from __future__ import annotations

import hashlib
import math

def extract_features_from_bytes(image_bytes: bytes | None) -> dict[str, float]:
    """
    Extract camera-based visual features from an uploaded pepper berry image.

    Output values are normalized into [0, 1] and are intended for a lightweight
    rule-based grading baseline (no model training required).

    This function never raises. If OpenCV is unavailable or decoding fails, it
    falls back to deterministic demo features derived from the image bytes.
    """

    if image_bytes is None:
        return _demo_features(None)

    try:
        import cv2  # type: ignore
        import numpy as np
    except Exception:
        return _demo_features(image_bytes)

    try:
        buffer = np.frombuffer(image_bytes, dtype=np.uint8)
        image_bgr = cv2.imdecode(buffer, cv2.IMREAD_COLOR)
    except Exception:
        image_bgr = None

    if image_bgr is None:
        return _demo_features(image_bytes)

    try:
        mask = _berry_mask(image_bgr)
        if mask is None:
            return _demo_features(image_bytes)

        lab = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2LAB)
        l_channel, a_channel, b_channel = cv2.split(lab)
        hsv = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2HSV)
        h_channel, s_channel, v_channel = cv2.split(hsv)

        mask_bool = mask.astype(bool)
        if mask_bool.sum() < 50:
            mask_bool = np.ones(l_channel.shape, dtype=bool)

        l_vals = l_channel[mask_bool].astype(np.float32)
        a_vals = a_channel[mask_bool].astype(np.float32)
        b_vals = b_channel[mask_bool].astype(np.float32)

        # 1) Colour uniformity: lower chroma variation => higher score.
        ab_std = float(math.sqrt(float(a_vals.std()) ** 2 + float(b_vals.std()) ** 2))
        color_uniformity_score = math.exp(-ab_std / 18.0)

        # 2) Dark / light berry ratios using adaptive thresholds from L distribution.
        mean_l = float(l_vals.mean())
        std_l = float(l_vals.std())
        std_l = max(std_l, 1.0)
        dark_thr = mean_l - (0.70 * std_l)
        light_thr = mean_l + (0.90 * std_l)
        dark_berry_ratio = float((l_vals < dark_thr).mean())
        light_berry_ratio = float((l_vals > light_thr).mean())

        # 3) Texture score: combine edge density + Laplacian variance (focus measure).
        gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)
        gray_blur = cv2.GaussianBlur(gray, (5, 5), 0)
        edges = cv2.Canny(gray_blur, 50, 150)
        edge_density = float(edges[mask_bool].mean() / 255.0) if mask_bool.any() else 0.0
        edge_score = min(1.0, edge_density * 4.0)

        lap = cv2.Laplacian(gray_blur, cv2.CV_64F)
        lap_vals = lap[mask_bool] if mask_bool.any() else lap.reshape(-1)
        lap_var = float(lap_vals.var())
        lap_score = 1.0 - math.exp(-lap_var / 150.0)
        texture_score = (0.55 * lap_score) + (0.45 * edge_score)

        # 4) Defect ratio: bright/low-sat regions or unusual hues inside the berry mask.
        v_vals = v_channel[mask_bool].astype(np.float32)
        s_vals = s_channel[mask_bool].astype(np.float32)
        h_vals = h_channel[mask_bool].astype(np.float32)
        mean_v = float(v_vals.mean())
        std_v = float(v_vals.std())
        std_v = max(std_v, 1.0)

        bright = v_vals > (mean_v + (1.10 * std_v))
        low_sat = s_vals < 55.0
        mould_like = bright & low_sat

        # Green/blue-ish hues (commonly background/foreign material) when saturation is high.
        strong_sat = s_vals > 90.0
        unusual_hue = strong_sat & ((h_vals > 35.0) & (h_vals < 130.0))

        defect_ratio = float((mould_like | unusual_hue).mean())

        cleanliness_score = 1.0 - defect_ratio

        features = {
            "color_uniformity_score": _clamp01(color_uniformity_score),
            "dark_berry_ratio": _clamp01(dark_berry_ratio),
            "light_berry_ratio": _clamp01(light_berry_ratio),
            "texture_score": _clamp01(texture_score),
            "defect_ratio": _clamp01(defect_ratio),
            "cleanliness_score": _clamp01(cleanliness_score),
        }
        return features
    except Exception:
        return _demo_features(image_bytes)


def _berry_mask(image_bgr) -> object | None:
    try:
        import cv2  # type: ignore
        import numpy as np
    except Exception:
        return None

    try:
        gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)
        gray_blur = cv2.GaussianBlur(gray, (5, 5), 0)
        _, thresh = cv2.threshold(gray_blur, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

        white_mask = thresh == 255
        black_mask = thresh == 0
        mean_white = float(gray[white_mask].mean()) if white_mask.any() else 255.0
        mean_black = float(gray[black_mask].mean()) if black_mask.any() else 0.0

        # Pepper berries are typically darker than background; pick the darker cluster as foreground.
        if mean_white < mean_black:
            mask = thresh
        else:
            mask = cv2.bitwise_not(thresh)

        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
        mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel, iterations=1)
        mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel, iterations=2)

        ratio = float((mask > 0).mean())
        if ratio < 0.05 or ratio > 0.95:
            return np.full(mask.shape, 255, dtype=np.uint8)

        return mask
    except Exception:
        return None


def _clamp01(value: float) -> float:
    if value != value:  # NaN
        return 0.0
    return float(max(0.0, min(1.0, value)))


def _demo_features(image_bytes: bytes | None) -> dict[str, float]:
    if not image_bytes:
        return {
            "color_uniformity_score": 0.72,
            "dark_berry_ratio": 0.62,
            "light_berry_ratio": 0.18,
            "texture_score": 0.68,
            "defect_ratio": 0.10,
            "cleanliness_score": 0.90,
        }

    hasher = hashlib.sha256()
    hasher.update(b"grading-forecast-demo-features-v1")
    hasher.update(image_bytes[:32768])
    digest = hasher.digest()

    def u01(i: int) -> float:
        # Map 2 bytes into [0, 1]
        n = int.from_bytes(digest[i : i + 2], "big", signed=False)
        return n / 65535.0

    color_uniformity_score = 0.55 + (0.40 * u01(0))
    dark_berry_ratio = 0.35 + (0.55 * u01(2))
    light_berry_ratio = 0.05 + (0.35 * u01(4))
    texture_score = 0.35 + (0.60 * u01(6))
    defect_ratio = 0.02 + (0.28 * u01(8))
    cleanliness_score = 1.0 - defect_ratio

    return {
        "color_uniformity_score": _clamp01(color_uniformity_score),
        "dark_berry_ratio": _clamp01(dark_berry_ratio),
        "light_berry_ratio": _clamp01(light_berry_ratio),
        "texture_score": _clamp01(texture_score),
        "defect_ratio": _clamp01(defect_ratio),
        "cleanliness_score": _clamp01(cleanliness_score),
    }
