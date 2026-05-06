from __future__ import annotations

import uuid
from pathlib import Path

import pytest

from app.services.grading_forecast.grading_service import build_grading_result
from app.services.grading_forecast.price_forecast_service import build_price_forecast
from app.services.grading_forecast.recommendation_service import build_recommendation
from app.services.grading_forecast.result_storage_service import build_storage_result


def test_storage_service_handles_initialization_failure_safely(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    # Provide an invalid service account JSON path (exists but is not a valid JSON).
    repo_root = Path(__file__).resolve().parents[2]
    scratch_dir = repo_root / "data" / "_tmp_tests"
    scratch_dir.mkdir(parents=True, exist_ok=True)

    sa_path = scratch_dir / f"invalid_service_account_{uuid.uuid4().hex}.json"
    sa_path.write_text("not json", encoding="utf-8")

    try:
        monkeypatch.setenv("FIREBASE_SERVICE_ACCOUNT_PATH", str(sa_path))
        monkeypatch.setenv("FIREBASE_PROJECT_ID", "demo-project")
        monkeypatch.setenv("FIREBASE_RESULTS_COLLECTION", "grading_forecast_results")

        grading = build_grading_result(image_bytes=None, image_name=None)
        forecast = build_price_forecast(seed_hint="storage-test")
        recommendation = build_recommendation(
            grade=grading.predicted_grade,
            trend=forecast.trend,
            quality_score=grading.quality_score,
            current_price_lkr_per_kg=forecast.current_price_lkr_per_kg,
            predicted_price_lkr_per_kg=forecast.predicted_price_lkr_per_kg,
        )

        storage = build_storage_result(
            component="berry_grading_export_price_forecasting",
            image_id="TEST_IMAGE",
            image_processed=True,
            grading=grading,
            forecast=forecast,
            recommendation=recommendation,
        )

        assert storage.saved_to_firebase is False
        assert storage.document_id is None
    finally:
        try:
            sa_path.unlink(missing_ok=True)
        except Exception:
            pass
