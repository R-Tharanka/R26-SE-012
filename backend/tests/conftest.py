import pytest


@pytest.fixture(autouse=True)
def _disable_firebase_for_tests(monkeypatch: pytest.MonkeyPatch) -> None:
    """
    Ensure unit tests never talk to real Firebase/Firestore by default.

    Individual tests can still set env vars explicitly if needed.
    """

    monkeypatch.delenv("FIREBASE_SERVICE_ACCOUNT_PATH", raising=False)
    monkeypatch.delenv("FIREBASE_PROJECT_ID", raising=False)
    monkeypatch.delenv("FIREBASE_RESULTS_COLLECTION", raising=False)
    for name in (
        "HF_TOKEN",
        "HF_MODEL_REPO",
        "HF_MODEL_REVISION",
        "HF_GRADING_MODEL_FILE",
        "HF_CLASS_NAMES_FILE",
        "HF_FORECAST_MODEL_FILE",
        "HF_FORECAST_METRICS_FILE",
        "HF_FORECAST_DATA_FILE",
    ):
        monkeypatch.delenv(name, raising=False)

    try:
        from app.services.grading_forecast import artifact_service

        artifact_service.set_runtime_artifacts_for_tests(None)
    except Exception:
        pass

    try:
        from app.db import firebase as firebase_module

        monkeypatch.setattr(firebase_module, "_firestore_client", None, raising=False)
    except Exception:
        # If import fails, tests that don't touch Firebase should still run.
        pass
