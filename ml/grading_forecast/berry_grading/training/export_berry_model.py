from __future__ import annotations

import argparse
import json
import sys
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

sys.dont_write_bytecode = True


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def _utc_now_iso() -> str:
    return datetime.now(tz=UTC).replace(microsecond=0).isoformat()


def _git_sha(repo_root: Path) -> str | None:
    head = repo_root / ".git" / "HEAD"
    if not head.exists():
        return None
    try:
        ref = head.read_text(encoding="utf-8").strip()
    except Exception:
        return None
    if ref.startswith("ref:"):
        ref_path = repo_root / ".git" / ref.replace("ref:", "").strip()
        try:
            return ref_path.read_text(encoding="utf-8").strip()
        except Exception:
            return None
    return ref


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Export berry MobileNetV2 Keras model to ONNX (training environment).")
    parser.add_argument("--model", type=Path, default=None, help="Path to best .keras model.")
    parser.add_argument("--out", type=Path, default=None, help="Output .onnx path.")
    parser.add_argument("--opset", type=int, default=13, help="ONNX opset (default 13).")
    args = parser.parse_args(argv)

    repo_root = _repo_root()
    models_dir = repo_root / "ml" / "grading_forecast" / "berry_grading" / "models"
    models_dir.mkdir(parents=True, exist_ok=True)

    keras_path = args.model or (models_dir / "berry_mobilenetv2_best.keras")
    onnx_path = args.out or (models_dir / "berry_mobilenetv2_best.onnx")
    meta_path = models_dir / "onnx_metadata.json"

    if not keras_path.exists():
        print(f"Missing .keras model: {keras_path}")
        return 2

    try:
        import tensorflow as tf
    except Exception as exc:
        print(f"TensorFlow is required for export. Install ml/grading_forecast/requirements-training.txt. Error: {exc}")
        return 3

    try:
        import tf2onnx  # type: ignore
    except Exception as exc:
        print(f"tf2onnx is required for export. Install ml/grading_forecast/requirements-training.txt. Error: {exc}")
        return 4

    model = tf.keras.models.load_model(keras_path)
    # Export with a fixed input signature for backend consistency.
    spec = (tf.TensorSpec((None, 224, 224, 3), tf.float32, name="image"),)
    onnx_model, _ = tf2onnx.convert.from_keras(model, input_signature=spec, opset=args.opset, output_path=str(onnx_path))

    payload: dict[str, Any] = {
        "exported_at": _utc_now_iso(),
        "git_sha": _git_sha(repo_root),
        "keras_model_path": str(keras_path),
        "onnx_model_path": str(onnx_path),
        "opset": int(args.opset),
        "inputs": [{"name": "image", "dtype": "float32", "shape": [None, 224, 224, 3]}],
        "outputs": [{"name": "probs", "note": "Model output probabilities (softmax) if exported as such."}],
        "onnx_graph_name": getattr(onnx_model, "graph", None).name if hasattr(onnx_model, "graph") else None,
    }
    meta_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    # Update berry_model_metadata.json export flags if present.
    berry_meta = models_dir / "berry_model_metadata.json"
    if berry_meta.exists():
        try:
            data = json.loads(berry_meta.read_text(encoding="utf-8"))
            exp = data.get("export_formats_present") or {}
            exp["onnx"] = bool(onnx_path.exists())
            data["export_formats_present"] = exp
            berry_meta.write_text(json.dumps(data, indent=2), encoding="utf-8")
        except Exception:
            pass

    print(f"Wrote ONNX -> {onnx_path}")
    print(f"Wrote metadata -> {meta_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

