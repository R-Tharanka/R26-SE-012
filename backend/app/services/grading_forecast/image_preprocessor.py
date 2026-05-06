from __future__ import annotations


def preprocess_image_bytes(image_bytes: bytes | None) -> tuple[bytes | None, dict[str, object]]:
    """
    Camera-image preprocessor for berry grading feature extraction.

    - Never raises.
    - Uses OpenCV when available.
    - If OpenCV is missing or decoding fails (and no safe fallback decoder is available),
      returns (None, meta) so callers can fall back to demo mode.
    """

    meta: dict[str, object] = {"processed": False, "note": "Preprocessing not executed."}
    if not image_bytes:
        meta["note"] = "No image provided; using demo mode."
        return None, meta

    try:
        import cv2  # type: ignore
        import numpy as np
    except Exception:
        meta["note"] = "OpenCV not available; skipping preprocessing."
        return None, meta

    try:
        buffer = np.frombuffer(image_bytes, dtype=np.uint8)
        image_bgr = cv2.imdecode(buffer, cv2.IMREAD_COLOR)
    except Exception:
        image_bgr = None

    if image_bgr is None:
        # OpenCV can be strict about certain PNG edge cases; try a safe Pillow decode if available.
        try:
            import io

            from PIL import Image  # type: ignore

            img = Image.open(io.BytesIO(image_bytes))
            img.load()
            img_rgb = np.asarray(img.convert("RGB"))
            image_bgr = cv2.cvtColor(img_rgb, cv2.COLOR_RGB2BGR)
            meta["note"] = "OpenCV decode failed; Pillow fallback decode used."
        except Exception:
            meta["note"] = "Image decoding failed; skipping preprocessing."
            return None, meta

    input_h, input_w = image_bgr.shape[:2]
    meta["input_width"] = int(input_w)
    meta["input_height"] = int(input_h)

    max_side = 768
    scale_factor = 1.0
    try:
        if max(input_h, input_w) > max_side:
            scale_factor = max_side / float(max(input_h, input_w))
            new_w = max(1, int(round(input_w * scale_factor)))
            new_h = max(1, int(round(input_h * scale_factor)))
            image_bgr = cv2.resize(image_bgr, (new_w, new_h), interpolation=cv2.INTER_AREA)
    except Exception:
        scale_factor = 1.0

    meta["scale_factor"] = float(scale_factor)
    meta["width"] = int(image_bgr.shape[1])
    meta["height"] = int(image_bgr.shape[0])

    try:
        # Denoise (fast and deterministic)
        image_bgr = cv2.medianBlur(image_bgr, 3)

        # Improve local contrast using CLAHE on L channel (LAB)
        lab = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2LAB)
        l_channel, a_channel, b_channel = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        l_eq = clahe.apply(l_channel)
        lab_eq = cv2.merge((l_eq, a_channel, b_channel))
        image_bgr = cv2.cvtColor(lab_eq, cv2.COLOR_LAB2BGR)
    except Exception:
        meta["note"] = "Preprocessing step failed; using original image bytes."
        return image_bytes, meta

    try:
        encode_params = [int(cv2.IMWRITE_JPEG_QUALITY), 90]
        ok, encoded = cv2.imencode(".jpg", image_bgr, encode_params)
        if not ok:
            raise ValueError("imencode failed")
        processed_bytes = encoded.tobytes()
    except Exception:
        meta["note"] = "Image encoding failed; using original image bytes."
        return image_bytes, meta

    meta["processed"] = True
    meta["note"] = "OpenCV preprocessing applied."
    return processed_bytes, meta
