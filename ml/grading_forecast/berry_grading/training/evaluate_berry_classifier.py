from __future__ import annotations

import argparse
import json
import os
import sys
import time
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

sys.dont_write_bytecode = True


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def _utc_now_iso() -> str:
    return datetime.now(tz=UTC).replace(microsecond=0).isoformat()


def _safe_float(x: object) -> float | None:
    try:
        return float(x)  # type: ignore[arg-type]
    except Exception:
        return None


def _load_class_names(models_dir: Path) -> list[str]:
    p = models_dir / "class_names.json"
    if not p.exists():
        return ["Grade 1", "Grade 2", "Grade 3"]
    return list(json.loads(p.read_text(encoding="utf-8")))


def _model_size_mb(path: Path) -> float | None:
    try:
        return round(path.stat().st_size / (1024.0 * 1024.0), 3)
    except Exception:
        return None


def _memory_rss_bytes() -> int | None:
    try:
        import psutil

        return int(psutil.Process(os.getpid()).memory_info().rss)
    except Exception:
        return None


def _letterbox_pil(img, *, size: tuple[int, int] = (224, 224)):
    from PIL import Image

    target_w, target_h = size
    img = img.convert("RGB")
    w, h = img.size
    scale = min(target_w / w, target_h / h)
    new_w = max(1, int(round(w * scale)))
    new_h = max(1, int(round(h * scale)))
    resized = img.resize((new_w, new_h), resample=Image.BILINEAR)
    canvas = Image.new("RGB", (target_w, target_h), (0, 0, 0))
    canvas.paste(resized, ((target_w - new_w) // 2, (target_h - new_h) // 2))
    return canvas


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Evaluate berry classifier and write metrics JSON + plots.")
    parser.add_argument("--data-dir", type=Path, default=None, help="Dataset root (berry_images_processed).")
    parser.add_argument("--batch-size", type=int, default=16, help="Batch size.")
    parser.add_argument("--seed", type=int, default=42, help="Seed.")
    parser.add_argument("--val-split", type=float, default=0.2, help="Validation split ratio.")
    parser.add_argument("--runs", type=int, default=80, help="Inference timing runs (after warmup).")
    args = parser.parse_args(argv)

    repo_root = _repo_root()
    data_dir = args.data_dir or (
        repo_root / "data" / "processed" / "grading_forecast" / "berry_images_processed"
    )

    models_dir = repo_root / "ml" / "grading_forecast" / "berry_grading" / "models"
    eval_out = repo_root / "ml" / "grading_forecast" / "berry_grading" / "evaluation" / "_outputs"
    eval_out.mkdir(parents=True, exist_ok=True)

    model_path = models_dir / "berry_mobilenetv2_best.keras"
    if not model_path.exists():
        print(f"Missing trained model: {model_path}")
        return 2

    class_names = _load_class_names(models_dir)

    import matplotlib.pyplot as plt
    import numpy as np
    import tensorflow as tf
    from sklearn.metrics import classification_report, confusion_matrix, precision_recall_fscore_support

    class_names_dir = ["grade_1", "grade_2", "grade_3"]
    val_ds = tf.keras.utils.image_dataset_from_directory(
        data_dir,
        labels="inferred",
        label_mode="int",
        class_names=class_names_dir,
        image_size=(224, 224),
        batch_size=args.batch_size,
        shuffle=False,
        seed=args.seed,
        validation_split=args.val_split,
        subset="validation",
    ).cache().prefetch(tf.data.AUTOTUNE)

    model = tf.keras.models.load_model(model_path)

    y_true: list[int] = []
    y_pred: list[int] = []
    y_prob: list[list[float]] = []

    for x, y in val_ds:
        probs = model.predict(x, verbose=0)
        preds = np.argmax(probs, axis=1)
        y_true.extend(np.asarray(y).reshape(-1).astype(int).tolist())
        y_pred.extend(preds.reshape(-1).astype(int).tolist())
        y_prob.extend(probs.tolist())

    if not y_true:
        print("Validation dataset is empty; cannot evaluate.")
        return 3

    cm = confusion_matrix(y_true, y_pred, labels=list(range(len(class_names))))
    precision, recall, f1, _ = precision_recall_fscore_support(
        y_true, y_pred, labels=list(range(len(class_names))), average="weighted", zero_division=0
    )
    accuracy = float(np.mean(np.asarray(y_true) == np.asarray(y_pred)))

    report = classification_report(
        y_true,
        y_pred,
        target_names=class_names,
        zero_division=0,
        output_dict=True,
    )

    # Confusion matrix plot
    fig = plt.figure(figsize=(6.4, 5.2))
    ax = fig.add_subplot(1, 1, 1)
    im = ax.imshow(cm, interpolation="nearest", cmap="Blues")
    fig.colorbar(im, ax=ax)
    ax.set(
        xticks=np.arange(len(class_names)),
        yticks=np.arange(len(class_names)),
        xticklabels=class_names,
        yticklabels=class_names,
        ylabel="True label",
        xlabel="Predicted label",
        title="Berry Grading Confusion Matrix",
    )
    plt.setp(ax.get_xticklabels(), rotation=45, ha="right", rotation_mode="anchor")
    thresh = cm.max() / 2.0 if cm.size else 0.0
    for i in range(cm.shape[0]):
        for j in range(cm.shape[1]):
            ax.text(j, i, format(cm[i, j], "d"), ha="center", va="center", color="white" if cm[i, j] > thresh else "black")
    fig.tight_layout()
    cm_path = eval_out / "confusion_matrix.png"
    fig.savefig(cm_path, dpi=140)
    plt.close(fig)

    # Training curves plot (if history exists)
    history_path = models_dir / "training_history.json"
    curves_path = eval_out / "training_curves.png"
    if history_path.exists():
        try:
            payload = json.loads(history_path.read_text(encoding="utf-8"))
            stages = payload.get("stages") or []
            losses: list[float] = []
            val_losses: list[float] = []
            accs: list[float] = []
            val_accs: list[float] = []
            for s in stages:
                h = s.get("history") or {}
                losses.extend([float(v) for v in (h.get("loss") or [])])
                val_losses.extend([float(v) for v in (h.get("val_loss") or [])])
                accs.extend([float(v) for v in (h.get("accuracy") or [])])
                val_accs.extend([float(v) for v in (h.get("val_accuracy") or [])])
            if losses and val_losses:
                fig2 = plt.figure(figsize=(8.2, 3.6))
                ax1 = fig2.add_subplot(1, 2, 1)
                ax1.plot(losses, label="train_loss")
                ax1.plot(val_losses, label="val_loss")
                ax1.set_title("Loss")
                ax1.legend()
                ax2 = fig2.add_subplot(1, 2, 2)
                if accs:
                    ax2.plot(accs, label="train_acc")
                if val_accs:
                    ax2.plot(val_accs, label="val_acc")
                ax2.set_title("Accuracy")
                ax2.legend()
                fig2.tight_layout()
                fig2.savefig(curves_path, dpi=140)
                plt.close(fig2)
        except Exception:
            pass

    # Performance metrics (Keras model)
    warm_img = None
    try:
        for batch_x, _ in val_ds.take(1):
            warm_img = batch_x[:1]
            break
    except Exception:
        warm_img = None

    timing: dict[str, Any] = {"runs": int(args.runs), "avg_ms": None, "p95_ms": None}
    rss_before = _memory_rss_bytes()
    if warm_img is not None:
        # Warmup
        for _ in range(8):
            _ = model.predict(warm_img, verbose=0)
        times: list[float] = []
        for _ in range(max(1, int(args.runs))):
            t0 = time.perf_counter()
            _ = model.predict(warm_img, verbose=0)
            times.append((time.perf_counter() - t0) * 1000.0)
        if times:
            times_sorted = sorted(times)
            timing["avg_ms"] = round(float(sum(times) / len(times)), 3)
            timing["p95_ms"] = round(float(times_sorted[int(0.95 * (len(times_sorted) - 1))]), 3)
    rss_after = _memory_rss_bytes()

    metrics_path = models_dir / "berry_classifier_metrics.json"
    metrics: dict[str, Any] = {
        "evaluated_at": _utc_now_iso(),
        "model_path": str(model_path),
        "accuracy": round(accuracy, 4),
        "precision_weighted": round(float(precision), 4),
        "recall_weighted": round(float(recall), 4),
        "f1_weighted": round(float(f1), 4),
        "confusion_matrix": cm.tolist(),
        "classification_report": report,
        "artifacts": {
            "confusion_matrix_png": str(cm_path),
            "training_curves_png": str(curves_path) if curves_path.exists() else None,
        },
        "performance": {
            "inference_timing_single_image": timing,
            "model_size_mb": _model_size_mb(model_path),
            "rss_before_bytes": rss_before,
            "rss_after_bytes": rss_after,
            "rss_delta_bytes": (rss_after - rss_before) if (rss_after is not None and rss_before is not None) else None,
        },
    }
    metrics_path.write_text(json.dumps(metrics, indent=2), encoding="utf-8")

    print(f"Wrote metrics -> {metrics_path}")
    print(f"Wrote confusion matrix -> {cm_path}")
    if curves_path.exists():
        print(f"Wrote training curves -> {curves_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

