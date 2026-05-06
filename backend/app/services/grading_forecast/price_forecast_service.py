from __future__ import annotations

import csv
import datetime as dt
import hashlib
import math
import random
import re
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

from app.schemas.grading_forecast import ForecastMetrics, ForecastResult, TrendEnum

MOVING_AVG_WINDOW = 3
EVAL_MIN_RECORDS = 6


@dataclass(frozen=True)
class PricePoint:
    date: dt.date
    price_lkr_per_kg: int


def _repo_root() -> Path:
    # backend/app/services/grading_forecast/price_forecast_service.py -> repo root
    return Path(__file__).resolve().parents[4]


def _default_input_paths(*, repo_root: Path) -> tuple[Path, Path]:
    real = repo_root / "data" / "raw" / "market_prices" / "black_pepper_prices.csv"
    sample = repo_root / "data" / "raw" / "market_prices" / "sample_black_pepper_prices.csv"
    return real, sample


def _default_output_path(*, repo_root: Path) -> Path:
    return repo_root / "data" / "processed" / "grading_forecast" / "cleaned_price_data.csv"


def select_input_csv_path(*, repo_root: Path | None = None) -> Path | None:
    root = repo_root or _repo_root()
    real, sample = _default_input_paths(repo_root=root)
    if real.is_file():
        return real
    if sample.is_file():
        return sample
    return None


def _parse_date(value: str | None) -> dt.date | None:
    if value is None:
        return None
    s = value.strip()
    if not s:
        return None

    # ISO date/datetime forms
    try:
        return dt.datetime.fromisoformat(s).date()
    except Exception:
        pass

    # Common separators
    if "/" in s:
        s = s.replace("/", "-")

    parts = s.split("-")
    if len(parts) < 3:
        return None

    p0, p1, p2 = parts[0].strip(), parts[1].strip(), parts[2].strip()
    try:
        if len(p0) == 4:
            year, month, day = int(p0), int(p1), int(p2)
        elif len(p2) == 4:
            day, month, year = int(p0), int(p1), int(p2)
        else:
            return None
        return dt.date(year, month, day)
    except Exception:
        return None


_PRICE_ALLOWED_RE = re.compile(r"[^\d.\-]+")


def _parse_price(value: str | None) -> float | None:
    if value is None:
        return None
    s = value.strip()
    if not s:
        return None
    # Remove commas, currency markers, etc. Keep digits, '.', and '-' only.
    s = _PRICE_ALLOWED_RE.sub("", s.replace(",", ""))
    if not s:
        return None
    try:
        price = float(s)
    except Exception:
        return None
    if not math.isfinite(price) or price <= 0:
        return None
    return price


def _load_csv_rows(csv_path: Path) -> list[dict[str, str]]:
    with csv_path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        if reader.fieldnames is None:
            return []
        return [dict(row) for row in reader]


def _detect_columns(rows: list[dict[str, str]]) -> tuple[str, str] | None:
    if not rows:
        return None

    fieldnames = set(rows[0].keys())
    if "date" not in fieldnames:
        return None

    for price_col in ("price_lkr_per_kg", "price_lkr", "price"):
        if price_col in fieldnames:
            return "date", price_col
    return None


def clean_price_csv(
    input_csv_path: Path,
    *,
    output_csv_path: Path | None = None,
) -> list[PricePoint]:
    """
    Clean a raw market price CSV into a single, date-indexed series.

    - Parses dates into dt.date
    - Cleans prices into LKR/kg integers
    - Aggregates duplicate dates using average price
    - Forward-fill then backward-fill missing prices, then drops any remaining missing rows
    - Writes cleaned CSV if output_csv_path is provided
    """

    rows = _load_csv_rows(input_csv_path)
    detected = _detect_columns(rows)
    if detected is None:
        return []
    date_col, price_col = detected

    parsed: list[tuple[dt.date, float | None]] = []
    for row in rows:
        date = _parse_date(row.get(date_col))
        if date is None:
            continue
        price = _parse_price(row.get(price_col))
        parsed.append((date, price))

    if not parsed:
        return []

    by_date: dict[dt.date, list[float]] = defaultdict(list)
    all_dates: set[dt.date] = set()
    for date, price in parsed:
        all_dates.add(date)
        if price is not None:
            by_date[date].append(price)

    series: list[tuple[dt.date, float | None]] = []
    for date in sorted(all_dates):
        values = by_date.get(date) or []
        if values:
            series.append((date, sum(values) / float(len(values))))
        else:
            series.append((date, None))

    # Fill missing: forward-fill then back-fill.
    filled: list[tuple[dt.date, float | None]] = []
    last_price: float | None = None
    for date, price in series:
        if price is None and last_price is not None:
            price = last_price
        if price is not None:
            last_price = price
        filled.append((date, price))

    next_price: float | None = None
    backfilled: list[tuple[dt.date, float | None]] = []
    for date, price in reversed(filled):
        if price is None and next_price is not None:
            price = next_price
        if price is not None:
            next_price = price
        backfilled.append((date, price))
    backfilled.reverse()

    cleaned: list[PricePoint] = []
    for date, price in backfilled:
        if price is None:
            continue
        cleaned.append(PricePoint(date=date, price_lkr_per_kg=int(round(price))))

    if output_csv_path is not None:
        output_csv_path.parent.mkdir(parents=True, exist_ok=True)
        with output_csv_path.open("w", encoding="utf-8", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["date", "price_lkr_per_kg"])
            for point in cleaned:
                writer.writerow([point.date.isoformat(), point.price_lkr_per_kg])

    return cleaned


def evaluate_one_step_ahead_metrics(points: list[PricePoint]) -> ForecastMetrics:
    if len(points) < EVAL_MIN_RECORDS:
        return ForecastMetrics(mae=None, rmse=None)

    y_true: list[float] = []
    y_pred: list[float] = []

    prices = [p.price_lkr_per_kg for p in points]
    for i in range(1, len(prices)):
        history = prices[:i]
        if len(history) == 1:
            pred = float(history[-1])
        else:
            window = history[-min(MOVING_AVG_WINDOW, len(history)) :]
            pred = float(sum(window) / len(window))
        y_true.append(float(prices[i]))
        y_pred.append(pred)

    if not y_true:
        return ForecastMetrics(mae=None, rmse=None)

    abs_errors = [abs(a - p) for a, p in zip(y_true, y_pred, strict=False)]
    sq_errors = [(a - p) ** 2 for a, p in zip(y_true, y_pred, strict=False)]
    mae = sum(abs_errors) / len(abs_errors)
    rmse = math.sqrt(sum(sq_errors) / len(sq_errors))
    return ForecastMetrics(mae=round(float(mae), 3), rmse=round(float(rmse), 3))


def _rng_for(seed_hint: str | None) -> random.Random:
    hasher = hashlib.sha256()
    hasher.update(b"price-forecast-demo-v1")
    if seed_hint:
        hasher.update(seed_hint.encode("utf-8", errors="ignore"))
    seed = int.from_bytes(hasher.digest()[:8], "big", signed=False)
    return random.Random(seed)


def _trend(current_price: int, predicted_price: int) -> TrendEnum:
    threshold = max(20, int(round(current_price * 0.02)))
    if predicted_price >= current_price + threshold:
        return TrendEnum.upward
    if predicted_price <= current_price - threshold:
        return TrendEnum.downward
    return TrendEnum.stable


def _demo_forecast(seed_hint: str | None) -> ForecastResult:
    rng = _rng_for(seed_hint=seed_hint)
    current_price = int(rng.uniform(1200, 1600))
    change_pct = rng.uniform(-0.06, 0.07)
    predicted_price = max(0, int(round(current_price * (1.0 + change_pct))))
    return ForecastResult(
        model="demo_baseline",
        current_price_lkr_per_kg=current_price,
        predicted_price_lkr_per_kg=predicted_price,
        trend=_trend(current_price, predicted_price),
        forecast_period="next_period",
        metrics=ForecastMetrics(mae=None, rmse=None),
    )


def build_price_forecast(
    seed_hint: str | None,
    *,
    csv_path_override: Path | None = None,
    cleaned_output_path_override: Path | None = None,
) -> ForecastResult:
    """
    Build a baseline price forecast.

    - Uses real CSV if present, otherwise sample CSV, otherwise demo fallback.
    - Never raises; any error falls back to deterministic demo forecast.
    """

    try:
        root = _repo_root()
        input_csv = csv_path_override
        if input_csv is None:
            input_csv = select_input_csv_path(repo_root=root)

        if input_csv is None or not input_csv.is_file():
            return _demo_forecast(seed_hint=seed_hint)

        output_csv = cleaned_output_path_override or _default_output_path(repo_root=root)
        points = clean_price_csv(input_csv, output_csv_path=output_csv)

        if not points:
            return _demo_forecast(seed_hint=seed_hint)

        current = points[-1].price_lkr_per_kg
        if len(points) == 1:
            predicted = current
            model = "naive_baseline"
        else:
            window = points[-min(MOVING_AVG_WINDOW, len(points)) :]
            predicted = int(round(sum(p.price_lkr_per_kg for p in window) / len(window)))
            model = "moving_average_baseline"

        metrics = evaluate_one_step_ahead_metrics(points)
        return ForecastResult(
            model=model,
            current_price_lkr_per_kg=int(current),
            predicted_price_lkr_per_kg=int(max(0, predicted)),
            trend=_trend(int(current), int(max(0, predicted))),
            forecast_period="next_period",
            metrics=metrics,
        )
    except Exception:
        return _demo_forecast(seed_hint=seed_hint)
