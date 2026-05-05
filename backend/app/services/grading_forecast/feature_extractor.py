from __future__ import annotations


def extract_features_from_bytes(image_bytes: bytes | None) -> dict[str, float]:
    """
    Mock/no-op feature extractor for the "Backend mock API only" milestone.

    Real OpenCV-based feature extraction will be added later. This function never raises.
    """

    _ = image_bytes
    return {}

