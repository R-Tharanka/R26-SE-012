from __future__ import annotations

from app.schemas.grading_forecast import StorageResult


def build_storage_result() -> StorageResult:
    return StorageResult(saved_to_firebase=False, document_id=None)

