from __future__ import annotations

import sys
from pathlib import Path

sys.dont_write_bytecode = True


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[4]


def main() -> int:
    repo_root = _repo_root()
    backend_path = repo_root / "backend"
    sys.path.insert(0, str(backend_path))

    from app.services.grading_forecast.price_forecast_service import (  # noqa: PLC0415
        clean_price_csv,
        select_input_csv_path,
    )

    input_csv = select_input_csv_path(repo_root=repo_root)
    if input_csv is None:
        print("No input CSV found. Add data/raw/market_prices/black_pepper_prices.csv or sample_black_pepper_prices.csv")
        return 2

    output_csv = repo_root / "data" / "processed" / "grading_forecast" / "cleaned_price_data.csv"
    points = clean_price_csv(input_csv, output_csv_path=output_csv)
    print(f"Cleaned {len(points)} records -> {output_csv}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
