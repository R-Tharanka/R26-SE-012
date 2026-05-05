from __future__ import annotations

import hashlib
import random

from app.schemas.grading_forecast import (
    GradeEnum,
    GradingResult,
    SupportingLabels,
    VisualFeatures,
)

LIMITATION_NOTE = (
    "Camera-based visual estimate only. Chemical requirements and bulk density are not measured."
)


def _rng_for(image_bytes: bytes | None, image_name: str | None) -> random.Random:
    hasher = hashlib.sha256()
    hasher.update(b"grading-forecast-mock-v1")
    if image_name:
        hasher.update(image_name.encode("utf-8", errors="ignore"))
    if image_bytes:
        hasher.update(image_bytes[:16384])

    seed = int.from_bytes(hasher.digest()[:8], "big", signed=False)
    return random.Random(seed)


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


def build_grading_result(image_bytes: bytes | None, image_name: str | None) -> GradingResult:
    rng = _rng_for(image_bytes=image_bytes, image_name=image_name)

    color_uniformity_score = rng.uniform(0.55, 0.95)
    texture_score = rng.uniform(0.45, 0.92)
    defect_ratio = rng.uniform(0.02, 0.30)
    cleanliness_score = rng.uniform(0.60, 0.98)

    dark_berry_ratio = rng.uniform(0.40, 0.92)
    light_berry_ratio = rng.uniform(0.05, 0.35)
    total = dark_berry_ratio + light_berry_ratio
    if total > 1.0:
        dark_berry_ratio /= total
        light_berry_ratio /= total

    visual_features = VisualFeatures(
        color_uniformity_score=round(color_uniformity_score, 3),
        dark_berry_ratio=round(dark_berry_ratio, 3),
        light_berry_ratio=round(light_berry_ratio, 3),
        texture_score=round(texture_score, 3),
        defect_ratio=round(defect_ratio, 3),
        cleanliness_score=round(cleanliness_score, 3),
    )

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
        size_quality = "good" if rng.random() < 0.80 else "medium"
    elif predicted_grade == GradeEnum.grade_2:
        size_quality = "medium" if rng.random() < 0.80 else "good"
    else:
        size_quality = "poor" if rng.random() < 0.80 else "medium"

    pinhead_r = rng.random()
    if pinhead_r < 0.65:
        pinhead_level = "low"
    elif pinhead_r < 0.85:
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
        foreign_matter_visible=visual_features.cleanliness_score < 0.74,
        mould_visible=(visual_features.defect_ratio > 0.22 and rng.random() < 0.35),
        insect_damage_visible=(visual_features.defect_ratio > 0.18 and rng.random() < 0.30),
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

    return GradingResult(
        predicted_grade=predicted_grade,
        quality_score=quality_score,
        confidence=confidence,
        visual_features=visual_features,
        supporting_labels=supporting_labels,
        explanation=explanation,
        limitation=LIMITATION_NOTE,
    )
