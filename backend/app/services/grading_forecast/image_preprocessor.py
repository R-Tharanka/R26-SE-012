from __future__ import annotations


def preprocess_image_bytes(image_bytes: bytes | None) -> tuple[bytes | None, dict[str, object]]:
    """
    Mock/no-op preprocessor for the "Backend mock API only" milestone.

    Returns the original bytes and a small metadata dict. Never raises.
    """

    meta: dict[str, object] = {
        "processed": bool(image_bytes),
        "note": "Preprocessing is not implemented in mock API mode.",
    }
    return image_bytes, meta

