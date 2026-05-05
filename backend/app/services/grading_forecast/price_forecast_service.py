from __future__ import annotations

import hashlib
import random

from app.schemas.grading_forecast import ForecastMetrics, ForecastResult, TrendEnum


def _rng_for(seed_hint: str | None) -> random.Random:
    hasher = hashlib.sha256()
    hasher.update(b"price-forecast-mock-v1")
    if seed_hint:
        hasher.update(seed_hint.encode("utf-8", errors="ignore"))
    seed = int.from_bytes(hasher.digest()[:8], "big", signed=False)
    return random.Random(seed)


def build_price_forecast(seed_hint: str | None) -> ForecastResult:
    rng = _rng_for(seed_hint=seed_hint)

    current_price = int(rng.uniform(1200, 1600))
    change_pct = rng.uniform(-0.06, 0.07)
    predicted_price = max(0, int(round(current_price * (1.0 + change_pct))))

    threshold = max(20, int(round(current_price * 0.02)))
    if predicted_price >= current_price + threshold:
        trend = TrendEnum.upward
    elif predicted_price <= current_price - threshold:
        trend = TrendEnum.downward
    else:
        trend = TrendEnum.stable

    return ForecastResult(
        model="moving_average_baseline",
        current_price_lkr_per_kg=current_price,
        predicted_price_lkr_per_kg=predicted_price,
        trend=trend,
        forecast_period="next_month",
        metrics=ForecastMetrics(mae=None, rmse=None),
    )

