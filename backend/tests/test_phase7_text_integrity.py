# =============================================================================
# File: frozen text integrity tests
# Purpose: Verifies portable line endings while rejecting real content changes.
# =============================================================================
from __future__ import annotations

import hashlib

from ml.grading_forecast.deployment.phase7.config import (
    canonical_text_sha256,
    frozen_text_matches,
    load_config,
    repo_path,
)


def _hash(payload: bytes) -> str:
    # Calculate the raw SHA-256 value used by the integrity assertions.
    return hashlib.sha256(payload).hexdigest()


def test_frozen_text_integrity_accepts_crlf_and_lf_checkouts(tmp_path) -> None:
    # Verify equivalent Windows and Linux line endings both pass validation.
    crlf = b"grade,value\r\nGrade 1,1.0\r\n"
    lf = crlf.replace(b"\r\n", b"\n")
    path = tmp_path / "frozen.csv"

    path.write_bytes(crlf)
    assert frozen_text_matches(
        path,
        raw_sha256=_hash(crlf),
        canonical_sha256=_hash(lf),
    )

    path.write_bytes(lf)
    assert frozen_text_matches(
        path,
        raw_sha256=_hash(crlf),
        canonical_sha256=_hash(lf),
    )


def test_frozen_text_integrity_rejects_content_changes(tmp_path) -> None:
    # Verify a real data change fails both raw and normalized integrity checks.
    crlf = b"grade,value\r\nGrade 1,1.0\r\n"
    canonical = crlf.replace(b"\r\n", b"\n")
    path = tmp_path / "frozen.csv"
    path.write_bytes(b"grade,value\nGrade 1,9.0\n")

    assert not frozen_text_matches(
        path,
        raw_sha256=_hash(crlf),
        canonical_sha256=_hash(canonical),
    )


def test_recorded_phase5_canonical_hash_matches_frozen_source() -> None:
    # Verify the recorded canonical hash still matches the frozen source file.
    settings = load_config()["price_runtime"]
    assert (
        canonical_text_sha256(repo_path(settings["source"]))
        == settings["source_canonical_text_sha256"]
    )
