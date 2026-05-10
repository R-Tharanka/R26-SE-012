from __future__ import annotations

import json
import io
import math
import os
from functools import lru_cache
from pathlib import Path

import numpy as np
from PIL import Image

from app.schemas.grading_forecast import (
    GradeEnum,
    GradingResult,
    SupportingLabels,
    VisualFeatures,
)
from app.services.grading_forecast.feature_extractor import extract_features_from_bytes
from app.services.grading_forecast.image_preprocessor import preprocess_image_bytes

LIMITATION_NOTE = (
    "Camera-based visual estimate only. Chemical requirements and bulk density are not measured."
)

GRADE_ANCHOR_SCORES: dict[GradeEnum, float] = {
    GradeEnum.grade_1: 85.0,
    GradeEnum.grade_2: 70.0,
    GradeEnum.grade_3: 55.0,
}


def _quality_band(value: float, *, good_threshold: float, medium_threshold: float) -> str:
    if value >= good_threshold:
        return "good"
    if value >= medium_threshold:
        return "medium"
    return "poor"


def _level_band(value: float, *, low_threshold: float, medium_threshold: float) -> str:
    if value <= low_threshold:
        return "low"
    if value <= medium_threshold:
        return "medium"
    return "high"


def _repo_root() -> Path:
    # backend/app/services/grading_forecast/grading_service.py -> repo root
    return Path(__file__).resolve().parents[4]


def _models_dir(repo_root: Path) -> Path:
    return repo_root / "ml" / "grading_forecast" / "berry_grading" / "models"


def _letterbox_224(img: Image.Image) -> Image.Image:
    target_w, target_h = 224, 224
    img = img.convert("RGB")
    w, h = img.size
    if w <= 0 or h <= 0:
        raise ValueError("Invalid image dimensions.")

    scale = min(target_w / w, target_h / h)
    new_w = max(1, int(round(w * scale)))
    new_h = max(1, int(round(h * scale)))
    resized = img.resize((new_w, new_h), resample=Image.BILINEAR)

    canvas = Image.new("RGB", (target_w, target_h), (0, 0, 0))
    canvas.paste(resized, ((target_w - new_w) // 2, (target_h - new_h) // 2))
    return canvas


def _mobilenetv2_scale_minus1_1(arr_0_255: np.ndarray) -> np.ndarray:
    return (arr_0_255.astype(np.float32) / 127.5) - 1.0


def _softmax(x: np.ndarray) -> np.ndarray:
    x = x.astype(np.float32)
    x = x - np.max(x)
    e = np.exp(x)
    return e / np.sum(e)


@lru_cache(maxsize=1)
def _onnx_session_bundle() -> tuple[object, str, list[str]] | None:
    """
    Returns (onnx_session, input_name, class_names) or None if unavailable.

    Never raises: backend must fall back gracefully when model artifacts are missing.
    """
    try:
        import onnxruntime as ort  # type: ignore
    except Exception:
        return None

    if os.getenv("GRADING_FORECAST_DISABLE_REAL_MODELS", "").strip().lower() in {"1", "true", "yes"}:
        return None

    root = _repo_root()
    models_dir = _models_dir(root)
    onnx_path = models_dir / "berry_mobilenetv2_best.onnx"
    class_names_path = models_dir / "class_names.json"
    if not onnx_path.is_file() or not class_names_path.is_file():
        return None

    try:
        class_names = list(json.loads(class_names_path.read_text(encoding="utf-8")))
        sess = ort.InferenceSession(str(onnx_path), providers=["CPUExecutionProvider"])
        input_name = sess.get_inputs()[0].name
        return sess, input_name, class_names
    except Exception:
        return None


def _predict_grade_with_onnx(image_bytes: bytes) -> tuple[GradeEnum, float, dict[GradeEnum, float]] | None:
    bundle = _onnx_session_bundle()
    if bundle is None:
        return None
    sess, input_name, class_names = bundle

    try:
        img = Image.open(io.BytesIO(image_bytes))  # type: ignore[name-defined]
        img.load()
        img224 = _letterbox_224(img)
        arr = np.asarray(img224, dtype=np.float32)
        x = _mobilenetv2_scale_minus1_1(arr)[None, ...]

        outputs = sess.run(None, {input_name: x})  # type: ignore[attr-defined]
        vec = np.asarray(outputs[0]).reshape(-1).astype(np.float32)
        if vec.size != 3:
            vec = vec[:3]

        s = float(np.sum(vec))
        if not math.isfinite(s) or s <= 0.0 or s > 1.2:
            probs = _softmax(vec)
        else:
            probs = (vec / s).astype(np.float32)

        # class_names.json contains: ["Grade 1", "Grade 2", "Grade 3"]
        name_to_enum = {
            "Grade 1": GradeEnum.grade_1,
            "Grade 2": GradeEnum.grade_2,
            "Grade 3": GradeEnum.grade_3,
        }
        enums: list[GradeEnum] = []
        for name in class_names[:3]:
            enums.append(name_to_enum.get(str(name), GradeEnum.grade_2))

        idx = int(np.argmax(probs))
        pred_grade = enums[idx]
        confidence = float(probs[idx])
        prob_map: dict[GradeEnum, float] = {enums[i]: float(probs[i]) for i in range(min(3, len(enums)))}
        return pred_grade, confidence, prob_map
    except Exception:
        return None


def _expected_quality_score(prob_map: dict[GradeEnum, float]) -> float:
    score = 0.0
    total_p = 0.0
    for grade, p in prob_map.items():
        total_p += float(p)
        score += float(p) * float(GRADE_ANCHOR_SCORES.get(grade, 70.0))
    if total_p <= 0.0:
        return 70.0
    return float(score / total_p)


def build_grading_result(image_bytes: bytes | None, image_name: str | None) -> GradingResult:
    processed_bytes, _ = preprocess_image_bytes(image_bytes)
    features = extract_features_from_bytes(processed_bytes or image_bytes)

    visual_features = VisualFeatures(
        color_uniformity_score=round(float(features["color_uniformity_score"]), 3),
        dark_berry_ratio=round(float(features["dark_berry_ratio"]), 3),
        light_berry_ratio=round(float(features["light_berry_ratio"]), 3),
        texture_score=round(float(features["texture_score"]), 3),
        defect_ratio=round(float(features["defect_ratio"]), 3),
        cleanliness_score=round(float(features["cleanliness_score"]), 3),
    )

    predicted_grade: GradeEnum
    quality_score: float
    confidence: float

    model_pred = None
    if image_bytes:
        # Prefer real ONNX model if present; otherwise fall back to heuristic grading.
        model_pred = _predict_grade_with_onnx(image_bytes)

    if model_pred is not None:
        predicted_grade, conf, prob_map = model_pred
        confidence = round(max(0.0, min(1.0, float(conf))), 2)
        quality_score = round(max(0.0, min(100.0, _expected_quality_score(prob_map))), 1)
    else:
        defect_free_score = 1.0 - visual_features.defect_ratio
        score_01 = (
            0.35 * visual_features.color_uniformity_score
            + 0.25 * visual_features.dark_berry_ratio
            + 0.20 * visual_features.texture_score
            + 0.15 * defect_free_score
            + 0.05 * visual_features.cleanliness_score
        )
        quality_score = round(max(0.0, min(100.0, score_01 * 100.0)), 1)

        if quality_score >= 80.0:
            predicted_grade = GradeEnum.grade_1
        elif quality_score >= 60.0:
            predicted_grade = GradeEnum.grade_2
        else:
            predicted_grade = GradeEnum.grade_3

        boundary_distance = min(abs(score_01 - 0.6), abs(score_01 - 0.8))
        confidence = max(0.55, min(0.92, 0.62 + (boundary_distance * 1.25)))
        confidence = round(confidence, 2)

    if predicted_grade == GradeEnum.grade_1:
        size_quality = "good"
    elif predicted_grade == GradeEnum.grade_2:
        size_quality = "medium"
    else:
        size_quality = "poor"

    if visual_features.light_berry_ratio <= 0.12:
        pinhead_level = "low"
    elif visual_features.light_berry_ratio <= 0.22:
        pinhead_level = "medium"
    else:
        pinhead_level = "high"

    supporting_labels = SupportingLabels(
        size_quality=size_quality,
        color_quality=_quality_band(
            visual_features.color_uniformity_score - (visual_features.light_berry_ratio * 0.4),
            good_threshold=0.78,
            medium_threshold=0.62,
        ),
        texture_quality=_quality_band(
            visual_features.texture_score, good_threshold=0.76, medium_threshold=0.60
        ),
        broken_level=_level_band(
            visual_features.defect_ratio, low_threshold=0.10, medium_threshold=0.20
        ),
        light_berry_level=_level_band(
            visual_features.light_berry_ratio, low_threshold=0.12, medium_threshold=0.22
        ),
        pinhead_level=pinhead_level,
        foreign_matter_visible=visual_features.cleanliness_score < 0.75,
        mould_visible=visual_features.defect_ratio > 0.20 and visual_features.light_berry_ratio > 0.15,
        insect_damage_visible=visual_features.defect_ratio > 0.18 and visual_features.texture_score < 0.55,
    )

    explanation: list[str] = []
    if visual_features.color_uniformity_score >= 0.80:
        explanation.append("Good black colour uniformity improved the grade.")
    elif visual_features.color_uniformity_score >= 0.65:
        explanation.append("Medium colour uniformity detected.")
    else:
        explanation.append("Poor colour uniformity reduced the visual quality score.")

    if visual_features.light_berry_ratio >= 0.22:
        explanation.append("Higher light berry ratio reduced the visual quality score.")

    if visual_features.defect_ratio >= 0.18:
        explanation.append("Visible defects or abnormal regions reduced the grade.")
    else:
        explanation.append("Low visible defect level detected.")

    if visual_features.texture_score >= 0.72:
        explanation.append("Wrinkled texture appears acceptable.")
    else:
        explanation.append("Texture quality appears weak and reduced the score.")

    if image_bytes is None:
        explanation.append("No image provided; demo features were used.")
    elif processed_bytes is None:
        explanation.append("OpenCV preprocessing unavailable; safe demo features may be used.")
    elif model_pred is None:
        explanation.append("Real grading model not available; heuristic grading was used.")
    else:
        explanation.append("Real grading model (ONNX) was used for predicted grade.")

    return GradingResult(
        predicted_grade=predicted_grade,
        quality_score=quality_score,
        confidence=confidence,
        visual_features=visual_features,
        supporting_labels=supporting_labels,
        explanation=explanation,
        limitation=LIMITATION_NOTE,
    )
