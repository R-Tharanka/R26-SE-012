from __future__ import annotations

from fastapi.testclient import TestClient

from app import main as main_module


def test_lifespan_downloads_artifacts_and_initializes_models(monkeypatch) -> None:
    calls: list[str] = []

    monkeypatch.setattr(main_module, "load_dotenv", lambda: calls.append("load_dotenv"))
    monkeypatch.setattr(
        main_module,
        "download_runtime_artifacts",
        lambda: calls.append("download_runtime_artifacts"),
    )
    monkeypatch.setattr(
        main_module,
        "initialize_grading_runtime",
        lambda: calls.append("initialize_grading_runtime"),
    )
    monkeypatch.setattr(
        main_module,
        "initialize_forecast_runtime",
        lambda: calls.append("initialize_forecast_runtime"),
    )

    app = main_module.create_app()
    with TestClient(app):
        pass

    assert calls == [
        "load_dotenv",
        "download_runtime_artifacts",
        "initialize_grading_runtime",
        "initialize_forecast_runtime",
    ]
