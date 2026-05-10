from __future__ import annotations

import os
import shutil
import uuid
from contextlib import contextmanager
from pathlib import Path
from typing import Iterator

from app.services.grading_forecast.price_forecast_service import (
    EVAL_MIN_RECORDS,
    TrendEnum,
    build_price_forecast,
    clean_price_csv,
    evaluate_one_step_ahead_metrics,
)


def _write_csv(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


@contextmanager
def _temp_dir() -> Iterator[Path]:
    base = _repo_root() / "data" / "_tmp_tests"
    base.mkdir(parents=True, exist_ok=True)
    d = base / f"price-forecast-{uuid.uuid4().hex}"
    d.mkdir(parents=True, exist_ok=False)
    try:
        yield d
    finally:
        shutil.rmtree(d, ignore_errors=True)


def test_clean_price_csv_sorts_dedupes_fills_and_writes() -> None:
    # Keep baseline behavior stable even if real model artifacts exist locally.
    os.environ["GRADING_FORECAST_DISABLE_REAL_MODELS"] = "1"
    with _temp_dir() as tmp_dir:
        raw = tmp_dir / "raw.csv"
        out = tmp_dir / "cleaned.csv"

        _write_csv(
            raw,
            "\n".join(
                [
                    "date,price_lkr_per_kg,market,grade,source",
                    "2024-01-02,1200,local,Grade 2,test",
                    "2024-01-01,1100,local,Grade 2,test",
                    '2024-01-03,"1,300",local,Grade 2,test',
                    "2024-01-04,,local,Grade 2,test",
                    "2024-01-02,1300,local,Grade 2,test",
                    "",
                ]
            ),
        )

        points = clean_price_csv(raw, output_csv_path=out)
        assert out.is_file()
        assert len(points) >= 4
        assert points[0].date.isoformat() == "2024-01-01"
        assert points[-1].date.isoformat() == "2024-01-04"

        # 2024-01-02 is duplicated (1200 & 1300) -> average 1250
        d_0102 = [p for p in points if p.date.isoformat() == "2024-01-02"]
        assert len(d_0102) == 1
        assert d_0102[0].price_lkr_per_kg == 1250

        # 2024-01-04 missing -> filled from prior (2024-01-03)
        assert points[-1].price_lkr_per_kg == points[-2].price_lkr_per_kg


def test_forecast_model_selection_naive_for_single_point() -> None:
    os.environ["GRADING_FORECAST_DISABLE_REAL_MODELS"] = "1"
    with _temp_dir() as tmp_dir:
        raw = tmp_dir / "one.csv"
        _write_csv(
            raw,
            "\n".join(
                [
                    "date,price_lkr_per_kg",
                    "2024-01-01,1500",
                    "",
                ]
            ),
        )

        forecast = build_price_forecast(
            seed_hint="x",
            csv_path_override=raw,
            cleaned_output_path_override=(tmp_dir / "cleaned.csv"),
        )
        assert forecast.model == "naive_baseline"
        assert forecast.predicted_price_lkr_per_kg == forecast.current_price_lkr_per_kg


def test_forecast_model_selection_moving_average_for_multiple_points() -> None:
    os.environ["GRADING_FORECAST_DISABLE_REAL_MODELS"] = "1"
    with _temp_dir() as tmp_dir:
        raw = tmp_dir / "multi.csv"
        _write_csv(
            raw,
            "\n".join(
                [
                    "date,price_lkr_per_kg",
                    "2024-01-01,1000",
                    "2024-01-08,1100",
                    "2024-01-15,1200",
                    "",
                ]
            ),
        )

        forecast = build_price_forecast(
            seed_hint="x",
            csv_path_override=raw,
            cleaned_output_path_override=(tmp_dir / "cleaned.csv"),
        )
        assert forecast.model == "moving_average_baseline"
        assert forecast.current_price_lkr_per_kg == 1200
        assert forecast.predicted_price_lkr_per_kg == 1100


def test_metrics_are_null_when_insufficient_records() -> None:
    os.environ["GRADING_FORECAST_DISABLE_REAL_MODELS"] = "1"
    with _temp_dir() as tmp_dir:
        raw = tmp_dir / "few.csv"
        rows = ["date,price_lkr_per_kg"]
        for i in range(EVAL_MIN_RECORDS - 1):
            rows.append(f"2024-01-{i+1:02d},{1000 + (i * 10)}")
        _write_csv(raw, "\n".join(rows) + "\n")

        points = clean_price_csv(raw, output_csv_path=(tmp_dir / "cleaned.csv"))
        metrics = evaluate_one_step_ahead_metrics(points)
        assert metrics.mae is None
        assert metrics.rmse is None


def test_metrics_are_floats_when_enough_records() -> None:
    os.environ["GRADING_FORECAST_DISABLE_REAL_MODELS"] = "1"
    with _temp_dir() as tmp_dir:
        raw = tmp_dir / "enough.csv"
        rows = ["date,price_lkr_per_kg"]
        for i in range(EVAL_MIN_RECORDS):
            rows.append(f"2024-01-{i+1:02d},{1000 + (i * 10)}")
        _write_csv(raw, "\n".join(rows) + "\n")

        points = clean_price_csv(raw, output_csv_path=(tmp_dir / "cleaned.csv"))
        metrics = evaluate_one_step_ahead_metrics(points)
        assert isinstance(metrics.mae, float)
        assert isinstance(metrics.rmse, float)
        assert metrics.mae >= 0.0
        assert metrics.rmse >= 0.0


def test_demo_fallback_when_override_path_missing() -> None:
    os.environ["GRADING_FORECAST_DISABLE_REAL_MODELS"] = "1"
    with _temp_dir() as tmp_dir:
        missing = tmp_dir / "does_not_exist.csv"
        forecast = build_price_forecast(
            seed_hint="seed",
            csv_path_override=missing,
            cleaned_output_path_override=(tmp_dir / "cleaned.csv"),
        )
        assert forecast.model == "demo_baseline"


def test_real_forecast_model_path_when_artifacts_provided() -> None:
    # Enable real model inference for this test.
    os.environ.pop("GRADING_FORECAST_DISABLE_REAL_MODELS", None)

    import json

    import joblib
    import numpy as np
    from sklearn.ensemble import RandomForestRegressor

    with _temp_dir() as tmp_dir:
        # Synthetic weekly series
        raw = tmp_dir / "series.csv"
        rows = ["date,price_lkr_per_kg"]
        base = 1000
        for i in range(20):
            rows.append(f"2024-01-{1+i:02d},{base + (i * 10)}")
        _write_csv(raw, "\n".join(rows) + "\n")

        points = clean_price_csv(raw, output_csv_path=(tmp_dir / "cleaned.csv"))
        assert len(points) >= 8

        models_dir = tmp_dir / "models"
        models_dir.mkdir(parents=True, exist_ok=True)

        spec = {
            "lags": [1, 2, 3],
            "rolling_windows": [3, 5],
            "eps": 1.0,
            "feature_names": [
                "lag_1",
                "lag_2",
                "lag_3",
                "rolling_mean_3",
                "rolling_std_3",
                "rolling_mean_5",
                "rolling_std_5",
                "month",
                "week_of_year",
                "price_change_1w",
                "price_change_pct_1w",
            ],
        }
        (models_dir / "forecast_features.json").write_text(json.dumps(spec, indent=2), encoding="utf-8")

        # Train a tiny RF on engineered features (mirror backend feature logic).
        def std(vals: list[float]) -> float:
            m = sum(vals) / len(vals)
            return float(np.sqrt(sum((v - m) ** 2 for v in vals) / len(vals)))

        X = []
        y = []
        prices = [float(p.price_lkr_per_kg) for p in points]
        dates = [p.date for p in points]
        for t in range(6, len(points) - 1):
            cur = prices[t]
            lag1 = prices[t - 1]
            feats = [
                prices[t - 1],
                prices[t - 2],
                prices[t - 3],
                sum(prices[t - 3 : t]) / 3.0,
                std(prices[t - 3 : t]),
                sum(prices[t - 5 : t]) / 5.0,
                std(prices[t - 5 : t]),
                float(dates[t].month),
                float(dates[t].isocalendar().week),
                cur - lag1,
                (cur - lag1) / max(lag1, 1.0),
            ]
            X.append(feats)
            y.append(prices[t + 1])

        model = RandomForestRegressor(n_estimators=50, random_state=42)
        model.fit(np.asarray(X, dtype=float), np.asarray(y, dtype=float))
        joblib.dump(model, models_dir / "forecast_model.joblib")

        forecast = build_price_forecast(
            seed_hint="x",
            csv_path_override=raw,
            cleaned_output_path_override=(tmp_dir / "cleaned2.csv"),
            models_dir_override=models_dir,
        )
        assert forecast.model == "random_forest_regressor_v1"
        assert forecast.current_price_lkr_per_kg > 0
        assert forecast.predicted_price_lkr_per_kg > 0
        assert forecast.trend in {TrendEnum.upward, TrendEnum.downward, TrendEnum.stable}
