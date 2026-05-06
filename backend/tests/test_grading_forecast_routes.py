from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_health_ok() -> None:
    resp = client.get("/api/v1/grading-forecast/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert data["component"] == "berry_grading_export_price_forecasting"


def test_analyze_without_file_returns_demo_response() -> None:
    resp = client.post("/api/v1/grading-forecast/analyze")
    assert resp.status_code == 200
    data = resp.json()

    assert data["status"] == "success"
    assert data["component"] == "berry_grading_export_price_forecasting"
    assert "grading" in data
    assert "forecast" in data
    assert "recommendation" in data
    assert "storage" in data


def test_analyze_is_deterministic_for_same_filename_and_bytes() -> None:
    files = {"image": ("IMG_001.jpg", b"demo-image-bytes", "image/jpeg")}

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
