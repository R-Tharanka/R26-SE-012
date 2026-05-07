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

    try:
        from app.db import firebase as firebase_module

        monkeypatch.setattr(firebase_module, "_firestore_client", None, raising=False)
    except Exception:
        # If import fails, tests that don't touch Firebase should still run.
        pass

