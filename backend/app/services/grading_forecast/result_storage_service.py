from __future__ import annotations

import datetime as dt
import logging
import os
from typing import Any

from app.db.firebase import get_firestore_client
from app.schemas.grading_forecast import (
    ForecastResult,
    GradingResult,
    RecommendationResult,
    StorageResult,
)

logger = logging.getLogger(__name__)

DEFAULT_COLLECTION = "grading_forecast_results"


def _collection_name() -> str:
    name = os.getenv("FIREBASE_RESULTS_COLLECTION") or DEFAULT_COLLECTION
    name = name.strip()
    return name or DEFAULT_COLLECTION


def _created_at_value() -> Any:
    """
    Prefer Firestore server timestamps when firebase_admin is available;
    otherwise fallback to a UTC datetime.
    """

    try:
        from firebase_admin import firestore  # type: ignore[import-not-found]

        return firestore.SERVER_TIMESTAMP
    except Exception:
        return dt.datetime.now(dt.UTC)


def build_storage_result(
    *,
    component: str,
    image_id: str,
    image_processed: bool,
    grading: GradingResult,
    forecast: ForecastResult,
    recommendation: RecommendationResult,
) -> StorageResult:
    client = get_firestore_client()
    if client is None:
        logger.warning("Firebase not configured; skipping Firestore result storage.")
        return StorageResult(saved_to_firebase=False, document_id=None)

    document: dict[str, Any] = {
        "component": component,
        "image_id": image_id,
        "image_processed": bool(image_processed),
        "predicted_grade": grading.predicted_grade.value,
        "quality_score": float(grading.quality_score),
        "confidence": float(grading.confidence),
        "visual_features": grading.visual_features.model_dump(mode="json"),
        "supporting_labels": grading.supporting_labels.model_dump(mode="json"),
        "forecast": forecast.model_dump(mode="json"),
        "recommendation": recommendation.model_dump(mode="json"),
        "limitation_note": recommendation.limitation_note,
        "created_at": _created_at_value(),
    }

    try:
        _, doc_ref = client.collection(_collection_name()).add(document)
        doc_id = getattr(doc_ref, "id", None)
        if not doc_id:
            return StorageResult(saved_to_firebase=True, document_id=None)
        return StorageResult(saved_to_firebase=True, document_id=str(doc_id))
    except Exception:
        logger.warning("Failed to save analysis result to Firebase; continuing without Firebase.")
        return StorageResult(saved_to_firebase=False, document_id=None)
