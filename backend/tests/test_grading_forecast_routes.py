import base64

from fastapi.testclient import TestClient

from app.main import app
from app.schemas.grading_forecast import (
    DecisionEnum,
    ForecastMetrics,
    ForecastResult,
    GradeEnum,
    GradingResult,
    RecommendationResult,
    StorageResult,
    SupportingLabels,
    TrendEnum,
    UrgencyLevelEnum,
    VisualFeatures,
)
from app.services.grading_forecast.artifact_service import RuntimeArtifacts, set_runtime_artifacts_for_tests


client = TestClient(app)
TINY_PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
)


def test_health_ok() -> None:
    resp = client.get("/api/v1/grading-forecast/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert data["component"] == "berry_grading_export_price_forecasting"


def test_ready_reports_not_ready_without_loaded_artifacts() -> None:
    set_runtime_artifacts_for_tests(None)
    resp = client.get("/api/v1/grading-forecast/ready")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "not_ready"
    assert data["component"] == "berry_grading_export_price_forecasting"
    assert data["artifacts_loaded"] is False
    assert data["artifacts_available"] is False


def test_ready_reports_loaded_artifacts(tmp_path) -> None:
    paths = []
    for name in (
        "model.onnx",
        "class_names.json",
        "forecast.joblib",
        "metrics.json",
        "series.csv",
    ):
        path = tmp_path / name
        path.write_text("artifact", encoding="utf-8")
        paths.append(path)

    set_runtime_artifacts_for_tests(
        RuntimeArtifacts(
            grading_model_path=paths[0],
            class_names_path=paths[1],
            forecast_model_path=paths[2],
            forecast_metrics_path=paths[3],
            forecast_data_path=paths[4],
        )
    )

    resp = client.get("/api/v1/grading-forecast/ready")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ready"
    assert data["artifacts_loaded"] is True
    assert data["artifacts_available"] is True


def test_analyze_without_file_returns_validation_error() -> None:
    resp = client.post("/api/v1/grading-forecast/analyze")
    assert resp.status_code == 400
    data = resp.json()
    assert data["detail"] == "Image upload is required."


def test_analyze_is_deterministic_for_same_filename_and_bytes(monkeypatch) -> None:
    from app.api.routes import grading_forecast as route_module

    grading = GradingResult(
        predicted_grade=GradeEnum.grade_1,
        quality_score=82.3,
        confidence=0.91,
        visual_features=VisualFeatures(
            color_uniformity_score=0.8,
            dark_berry_ratio=0.7,
            light_berry_ratio=0.1,
            texture_score=0.75,
            defect_ratio=0.05,
            cleanliness_score=0.9,
        ),
        supporting_labels=SupportingLabels(
            size_quality="good",
            color_quality="good",
            texture_quality="good",
            broken_level="low",
            light_berry_level="low",
            pinhead_level="low",
            foreign_matter_visible=False,
            mould_visible=False,
            insect_damage_visible=False,
        ),
        explanation=["test"],
        limitation="test limitation",
    )
    forecast = ForecastResult(
        model="naive_persistence",
        current_price_lkr_per_kg=1886,
        predicted_price_lkr_per_kg=1886,
        trend=TrendEnum.stable,
        forecast_period="next_period",
        metrics=ForecastMetrics(mae=None, rmse=None),
    )
    recommendation = RecommendationResult(
        decision=DecisionEnum.sell_export,
        message="test",
        explanation=["test"],
        urgency_level=UrgencyLevelEnum.low,
        suggested_action="test",
        limitation_note="test",
    )

    captured_forecast_grades = []

    def fake_build_price_forecast(**kwargs):
        captured_forecast_grades.append(kwargs.get("grade"))
        return forecast

    monkeypatch.setattr(route_module, "build_grading_result", lambda **_kwargs: grading)
    monkeypatch.setattr(route_module, "build_price_forecast", fake_build_price_forecast)
    monkeypatch.setattr(route_module, "build_recommendation", lambda **_kwargs: recommendation)
    monkeypatch.setattr(
        route_module,
        "build_storage_result",
        lambda **_kwargs: StorageResult(saved_to_firebase=False, document_id=None),
    )

    files = {"image": ("IMG_001.png", TINY_PNG, "image/png")}

    r1 = client.post("/api/v1/grading-forecast/analyze", files=files)
    r2 = client.post("/api/v1/grading-forecast/analyze", files=files)
    assert r1.status_code == 200
    assert r2.status_code == 200

    d1 = r1.json()
    d2 = r2.json()
    assert d1["grading"]["predicted_grade"] == d2["grading"]["predicted_grade"]
    assert d1["grading"]["quality_score"] == d2["grading"]["quality_score"]
    assert d1["forecast"]["predicted_price_lkr_per_kg"] == d2["forecast"]["predicted_price_lkr_per_kg"]
    assert d1["recommendation"]["decision"] == d2["recommendation"]["decision"]
    assert captured_forecast_grades == [GradeEnum.grade_1, GradeEnum.grade_1]


def test_recommend_endpoint_validates_payload() -> None:
    payload = {"grade": "Grade 2", "trend": "upward"}
    resp = client.post("/api/v1/grading-forecast/recommend", json=payload)
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "success"
    assert data["recommendation"]["decision"] in {
        "WAIT_OR_TARGET_EXPORT_BUYER",
        "SELL_EXPORT",
        "SELL_SOON",
        "WAIT_SHORTLY",
        "MONITOR",
        "SORT_OR_PROCESS",
        "PROCESS_LOCAL",
        "PROCESS_OR_SELL_IMMEDIATELY",
    }
    assert data["recommendation"]["limitation_note"] == (
        "Camera-based visual estimate only. Laboratory tests are required for full official quality certification."
    )
