from __future__ import annotations

import json
import io
import logging
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
LOGGER = logging.getLogger(__name__)

GRADE_ANCHOR_SCORES: dict[GradeEnum, float] = {
    GradeEnum.grade_1: 85.0,
    GradeEnum.grade_2: 70.0,
    GradeEnum.grade_3: 55.0,
}

RUNTIME_MODEL_ID = "BERRY-V2-MNV2"
RUNTIME_MODEL_RELATIVE_PATH = (
    Path("ml")
    / "grading_forecast"
    / "berry_grading"
    / "models"
    / "v2"
    / "berry_mobilenetv2_v2_best.onnx"
)


class GradingRuntimeError(RuntimeError):
    """Raised when the selected research grading model cannot produce a safe result."""


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


def _runtime_model_paths(repo_root: Path) -> tuple[Path, Path]:
    onnx_path = repo_root / RUNTIME_MODEL_RELATIVE_PATH
    class_names_path = onnx_path.parent / "class_names.json"
    return onnx_path, class_names_path


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
    # NOTE: kept for backwards compatibility but not used for ONNX inference.
    return (arr_0_255.astype(np.float32) / 127.5) - 1.0


def _softmax(x: np.ndarray) -> np.ndarray:
    x = x.astype(np.float32)
    x = x - np.max(x)
    e = np.exp(x)
    return e / np.sum(e)


@lru_cache(maxsize=1)
def _onnx_session_bundle() -> tuple[object, str, list[str], str, Path]:
    """
    Returns (onnx_session, input_name, class_names, model_id, model_path).

    Raises GradingRuntimeError when the selected V2 runtime model cannot be used.
    """
    try:
        import onnxruntime as ort  # type: ignore
    except Exception as exc:
        raise GradingRuntimeError("Berry grading runtime dependency is unavailable.") from exc

    if os.getenv("GRADING_FORECAST_DISABLE_REAL_MODELS", "").strip().lower() in {"1", "true", "yes"}:
        raise GradingRuntimeError("Berry grading runtime model is disabled by configuration.")

    root = _repo_root()
    onnx_path, class_names_path = _runtime_model_paths(root)
    if not onnx_path.is_file() or not class_names_path.is_file():
        raise GradingRuntimeError("Berry grading V2 model artifacts are unavailable.")

    try:
        class_names = list(json.loads(class_names_path.read_text(encoding="utf-8")))
        expected_class_names = ["Grade 1", "Grade 2", "Grade 3"]
        if class_names[:3] != expected_class_names:
            raise GradingRuntimeError("Berry grading V2 class mapping is invalid.")
        sess = ort.InferenceSession(str(onnx_path), providers=["CPUExecutionProvider"])
        input_name = sess.get_inputs()[0].name
        input_shape = list(sess.get_inputs()[0].shape)
        if len(input_shape) != 4 or input_shape[1:4] != [224, 224, 3]:
            raise GradingRuntimeError("Berry grading V2 model input shape is invalid.")
        return sess, input_name, class_names, RUNTIME_MODEL_ID, onnx_path
    except GradingRuntimeError:
        raise
    except Exception as exc:
        raise GradingRuntimeError("Berry grading V2 model could not be initialized.") from exc


def _predict_grade_with_onnx(image_bytes: bytes) -> tuple[GradeEnum, float, dict[GradeEnum, float], str, Path]:
    bundle = _onnx_session_bundle()
    sess, input_name, class_names, model_id, model_path = bundle

    try:
        img = Image.open(io.BytesIO(image_bytes))  # type: ignore[name-defined]
        img.load()
        img224 = _letterbox_224(img)
        # IMPORTANT:
        # The exported ONNX graph includes the Keras MobileNetV2 `preprocess_input` operation.
        # Therefore, feed raw 0..255 float32 RGB into the model (do NOT pre-scale to [-1, 1]).
        arr_0_255 = np.asarray(img224, dtype=np.float32)
        x = arr_0_255[None, ...]

        outputs = sess.run(None, {input_name: x})  # type: ignore[attr-defined]
        vec = np.asarray(outputs[0]).reshape(-1).astype(np.float32)
        if vec.size != 3:
            raise GradingRuntimeError("Berry grading V2 model returned an invalid output shape.")

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
            enum_value = name_to_enum.get(str(name))
            if enum_value is None:
                raise GradingRuntimeError("Berry grading V2 class mapping contains an unknown class.")
            enums.append(enum_value)

        idx = int(np.argmax(probs))
        if idx < 0 or idx >= len(enums):
            raise GradingRuntimeError("Berry grading V2 predicted class index is invalid.")
        pred_grade = enums[idx]
        confidence = float(probs[idx])
        prob_map: dict[GradeEnum, float] = {enums[i]: float(probs[i]) for i in range(min(3, len(enums)))}
        return pred_grade, confidence, prob_map, model_id, model_path
    except GradingRuntimeError:
        raise
    except Exception as exc:
        raise GradingRuntimeError("Berry grading V2 inference failed.") from exc


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
    if image_bytes is None:
        raise GradingRuntimeError("Image is required for berry grading.")

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
    model_pred = _predict_grade_with_onnx(image_bytes)

    if model_pred is not None:
        predicted_grade, conf, prob_map, model_id, model_path = model_pred
        confidence = round(max(0.0, min(1.0, float(conf))), 2)
        quality_score = round(max(0.0, min(100.0, _expected_quality_score(prob_map))), 1)
    else:
        LOGGER.error("Berry grading V2 inference did not return a prediction.")
        raise GradingRuntimeError("Berry grading V2 inference did not return a prediction.")

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

    if processed_bytes is None:
        explanation.append("OpenCV preprocessing unavailable; safe demo features may be used.")
    explanation.append(
        f"Runtime model {model_id} was used for predicted grade: {RUNTIME_MODEL_RELATIVE_PATH.as_posix()}."
    )

    return GradingResult(
        predicted_grade=predicted_grade,
        quality_score=quality_score,
        confidence=confidence,
        visual_features=visual_features,
        supporting_labels=supporting_labels,
        explanation=explanation,
        limitation=LIMITATION_NOTE,
    )
