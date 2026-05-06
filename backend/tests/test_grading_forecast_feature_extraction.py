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
    # 1x1 JPEG (black) as a stable, dependency-free test fixture.
    #
    # Note: A tiny PNG fixture can fail OpenCV decoding in some environments
    # (libpng CRC errors). JPEG decoding is more consistently supported.
    b64 = "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wAARCAABAAEDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD8qqKKKAP/2Q=="
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
