from __future__ import annotations

import logging
import os
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)

_firestore_client: Any | None = None


def _repo_root() -> Path:
    # backend/app/db/firebase.py -> repo root
    return Path(__file__).resolve().parents[3]


def _resolve_service_account_path(value: str) -> Path:
    path = Path(value).expanduser()
    if not path.is_absolute():
        path = (_repo_root() / path).resolve()
    return path


def get_firestore_client() -> Any | None:
    """
    Best-effort Firestore client initializer.

    Returns:
        A Firestore client when Firebase credentials are configured; otherwise None.

    Never raises. Safe to call from request handlers.
    """

    global _firestore_client
    if _firestore_client is not None:
        return _firestore_client

    service_account_path_raw = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
    project_id = os.getenv("FIREBASE_PROJECT_ID")
    if not service_account_path_raw or not project_id:
        return None

    service_account_path = _resolve_service_account_path(service_account_path_raw)
    if not service_account_path.is_file():
        return None

    try:
        import firebase_admin  # type: ignore[import-not-found]
        from firebase_admin import credentials, firestore  # type: ignore[import-not-found]
    except Exception:
        return None

    try:
        try:
            firebase_admin.get_app()
        except ValueError:
            cred = credentials.Certificate(str(service_account_path))
            firebase_admin.initialize_app(cred, {"projectId": project_id})

        _firestore_client = firestore.client()
        return _firestore_client
    except Exception:
        # Never allow Firebase init failures to crash the API.
        logger.warning("Firebase Firestore initialization failed; running without Firebase.")
        return None
