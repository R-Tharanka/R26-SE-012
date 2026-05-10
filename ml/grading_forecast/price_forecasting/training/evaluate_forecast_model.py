from __future__ import annotations

import argparse
import json
import sys
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import joblib
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

sys.dont_write_bytecode = True


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def _utc_now_iso() -> str:
    return datetime.now(tz=UTC).replace(microsecond=0).isoformat()


def _metrics(y_true: np.ndarray, y_pred: np.ndarray) -> dict[str, float]:
    mae = float(mean_absolute_error(y_true, y_pred))
    rmse = float(mean_squared_error(y_true, y_pred, squared=False))
    mape = float(np.mean(np.abs((y_true - y_pred) / np.clip(np.abs(y_true), 1.0, None)))) * 100.0
    r2 = float(r2_score(y_true, y_pred))
    return {"mae": round(mae, 4), "rmse": round(rmse, 4), "mape": round(mape, 4), "r2": round(r2, 4)}


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
    parser = argparse.ArgumentParser(description="Evaluate RandomForest forecasting model on test set.")
    parser.add_argument("--test-csv", type=Path, default=None, help="Test CSV path (test_forecast_data.csv).")
    parser.add_argument("--models-dir", type=Path, default=None, help="Models dir containing joblib + features json.")
    args = parser.parse_args(argv)

    repo_root = _repo_root()
    test_csv = args.test_csv or (
        repo_root / "data" / "processed" / "grading_forecast" / "test_forecast_data.csv"
    )
    if not test_csv.exists():
        print(f"Missing test CSV: {test_csv}")
        return 2

    models_dir = args.models_dir or (repo_root / "ml" / "grading_forecast" / "price_forecasting" / "models")
    model_path = models_dir / "forecast_model.joblib"
    features_path = models_dir / "forecast_features.json"
    if not model_path.exists() or not features_path.exists():
        print(f"Missing artifacts. Need: {model_path} and {features_path}")
        return 3

    spec = json.loads(features_path.read_text(encoding="utf-8"))
    feature_names: list[str] = list(spec["feature_names"])

    df = pd.read_csv(test_csv)
    feats = build_features(
        df,
        lags=list(spec["lags"]),
        rolling_windows=list(spec["rolling_windows"]),
        eps=float(spec["eps"]),
    )
    feats = feats.dropna(subset=feature_names + ["y_next_price"]).copy()
    if feats.empty:
        print("Not enough test rows after feature engineering.")
        return 4

    X = feats[feature_names].astype(float).to_numpy()
    y = feats["y_next_price"].astype(float).to_numpy()

    model = joblib.load(model_path)
    pred = np.asarray(model.predict(X), dtype=float)

    test_metrics = _metrics(y, pred)

    out_dir = repo_root / "ml" / "grading_forecast" / "price_forecasting" / "evaluation" / "_outputs"
    out_dir.mkdir(parents=True, exist_ok=True)

    # Actual vs predicted
    fig = plt.figure(figsize=(8.0, 4.2))
    ax = fig.add_subplot(1, 1, 1)
    ax.plot(y, label="actual")
    ax.plot(pred, label="predicted")
    ax.set_title("Price Forecast: Actual vs Predicted (Test)")
    ax.set_xlabel("Test index (chronological)")
    ax.set_ylabel("Price (LKR/kg)")
    ax.legend()
    fig.tight_layout()
    avp_path = out_dir / "actual_vs_predicted.png"
    fig.savefig(avp_path, dpi=140)
    plt.close(fig)

    # Residuals
    residuals = y - pred
    fig2 = plt.figure(figsize=(8.0, 4.2))
    ax2 = fig2.add_subplot(1, 1, 1)
    ax2.plot(residuals, label="residuals")
    ax2.axhline(0.0, color="black", linewidth=1)
    ax2.set_title("Price Forecast: Residuals (Test)")
    ax2.set_xlabel("Test index (chronological)")
    ax2.set_ylabel("Actual - Predicted")
    fig2.tight_layout()
    res_path = out_dir / "residuals.png"
    fig2.savefig(res_path, dpi=140)
    plt.close(fig2)

    # Feature importances (if available)
    importances_payload: dict[str, Any] | None = None
    if hasattr(model, "feature_importances_"):
        importances = np.asarray(getattr(model, "feature_importances_"), dtype=float)
        pairs = sorted(zip(feature_names, importances.tolist(), strict=False), key=lambda x: x[1], reverse=True)
        importances_payload = {"feature_importances": [{"feature": f, "importance": round(float(v), 6)} for f, v in pairs]}

        fig3 = plt.figure(figsize=(8.2, 4.6))
        ax3 = fig3.add_subplot(1, 1, 1)
        top = pairs[:12]
        ax3.bar([p[0] for p in top][::-1], [p[1] for p in top][::-1])
        ax3.set_title("Random Forest Feature Importances (Top 12)")
        ax3.set_xlabel("Importance")
        fig3.tight_layout()
        imp_path = out_dir / "feature_importances.png"
        fig3.savefig(imp_path, dpi=140)
        plt.close(fig3)
    else:
        imp_path = None

    metrics_path = models_dir / "forecast_metrics.json"
    existing: dict[str, Any] = {}
    if metrics_path.exists():
        try:
            existing = json.loads(metrics_path.read_text(encoding="utf-8"))
        except Exception:
            existing = {}

    existing["evaluated_at"] = _utc_now_iso()
    existing["test_metrics"] = test_metrics
    existing["test_csv"] = str(test_csv)
    existing["artifacts"] = {
        "actual_vs_predicted_png": str(avp_path),
        "residuals_png": str(res_path),
        "feature_importances_png": str(imp_path) if imp_path else None,
    }
    if importances_payload:
        existing.update(importances_payload)

    metrics_path.write_text(json.dumps(existing, indent=2), encoding="utf-8")
    print(f"Wrote updated metrics -> {metrics_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
