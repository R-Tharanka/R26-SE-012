from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path
from typing import Any

import joblib
import numpy as np
import pandas as pd

sys.dont_write_bytecode = True


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def _trend(current: float, predicted: float) -> str:
    threshold = max(20.0, float(abs(current) * 0.02))
    if predicted >= current + threshold:
        return "upward"
    if predicted <= current - threshold:
        return "downward"
    return "stable"


def _add_time_features(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    out["month"] = out["date"].dt.month.astype(int)
    out["week_of_year"] = out["date"].dt.isocalendar().week.astype(int)
    return out


def build_features(
    series_df: pd.DataFrame,
    *,
    lags: list[int],
    rolling_windows: list[int],
    eps: float,
) -> pd.DataFrame:
    df = series_df.copy()
    df["date"] = pd.to_datetime(df["date"], errors="coerce")
    df = df.dropna(subset=["date", "price_lkr_per_kg"]).sort_values("date", ascending=True)
    df["price_lkr_per_kg"] = pd.to_numeric(df["price_lkr_per_kg"], errors="coerce")
    df = df.dropna(subset=["price_lkr_per_kg"])

    df = _add_time_features(df)

    for lag in lags:
        df[f"lag_{lag}"] = df["price_lkr_per_kg"].shift(lag)

    shifted = df["price_lkr_per_kg"].shift(1)
    for w in rolling_windows:
        df[f"rolling_mean_{w}"] = shifted.rolling(window=w, min_periods=w).mean()
        df[f"rolling_std_{w}"] = shifted.rolling(window=w, min_periods=w).std()

    df["price_change_1w"] = df["price_lkr_per_kg"] - df["lag_1"]
    df["price_change_pct_1w"] = df["price_change_1w"] / df["lag_1"].clip(lower=eps)
    df["y_next_price"] = df["price_lkr_per_kg"].shift(-1)
    return df


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Predict next-week pepper price using trained RandomForest model.")
    parser.add_argument("--data-csv", type=Path, default=None, help="Forecast training CSV (forecast_training_data.csv).")
    parser.add_argument("--models-dir", type=Path, default=None, help="Models dir with joblib + features.")
    args = parser.parse_args(argv)

    repo_root = _repo_root()
    data_csv = args.data_csv or (
        repo_root / "data" / "processed" / "grading_forecast" / "forecast_training_data.csv"
    )
    if not data_csv.exists():
        print(f"Missing data CSV: {data_csv}")
        return 2

    models_dir = args.models_dir or (repo_root / "ml" / "grading_forecast" / "price_forecasting" / "models")
    model_path = models_dir / "forecast_model.joblib"
    features_path = models_dir / "forecast_features.json"
    if not model_path.exists() or not features_path.exists():
        print(f"Missing model/features. Need: {model_path} and {features_path}")
        return 3

    spec = json.loads(features_path.read_text(encoding="utf-8"))
    feature_names: list[str] = list(spec["feature_names"])

    df = pd.read_csv(data_csv)
    feats = build_features(
        df,
        lags=list(spec["lags"]),
        rolling_windows=list(spec["rolling_windows"]),
        eps=float(spec["eps"]),
    )
    feats = feats.dropna(subset=feature_names).sort_values("date", ascending=True)
    if feats.empty:
        print("Not enough rows to build features.")
        return 4

    latest = feats.iloc[-1]
    X = latest[feature_names].astype(float).to_numpy().reshape(1, -1)

    model = joblib.load(model_path)
    pred = float(np.asarray(model.predict(X), dtype=float).reshape(-1)[0])
    current = float(latest["price_lkr_per_kg"])
    out: dict[str, Any] = {
        "current_price": round(current, 2),
        "predicted_price": round(max(0.0, pred), 2),
        "trend": _trend(current, pred),
    }
    print(json.dumps(out, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
