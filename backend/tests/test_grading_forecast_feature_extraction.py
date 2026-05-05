import base64
import importlib.util

from app.services.grading_forecast.feature_extractor import extract_features_from_bytes
from app.services.grading_forecast.image_preprocessor import preprocess_image_bytes


FEATURE_KEYS = {
    "color_uniformity_score",
    "dark_berry_ratio",
    "light_berry_ratio",
    "texture_score",
    "defect_ratio",
    "cleanliness_score",
}


def _make_test_png_bytes() -> bytes:
    # 1x1 PNG (black) as a stable, dependency-free test fixture.
    b64 = (
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8A"
        "AwMCAO+u6v0AAAAASUVORK5CYII="
    )
    return base64.b64decode(b64)


def _assert_features_valid(features: dict[str, float]) -> None:
    assert set(features.keys()) == FEATURE_KEYS
    for value in features.values():
        assert isinstance(value, float)
        assert 0.0 <= value <= 1.0


def test_extract_features_returns_valid_output_for_none() -> None:
    features = extract_features_from_bytes(None)
    _assert_features_valid(features)


def test_extract_features_is_deterministic_for_same_bytes() -> None:
    image_bytes = _make_test_png_bytes()
    f1 = extract_features_from_bytes(image_bytes)
    f2 = extract_features_from_bytes(image_bytes)
    assert f1 == f2
    _assert_features_valid(f1)


def test_preprocess_image_bytes_never_raises_and_returns_meta() -> None:
    image_bytes = _make_test_png_bytes()
    processed_bytes, meta = preprocess_image_bytes(image_bytes)
    assert isinstance(meta, dict)
    assert "processed" in meta
    assert "note" in meta

    cv2_available = importlib.util.find_spec("cv2") is not None
    if cv2_available:
        assert processed_bytes is not None
        assert meta["processed"] is True
    else:
        # In environments without OpenCV, preprocessing is skipped safely.
        assert meta["processed"] is False
