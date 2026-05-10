# Phase 2: Data Cleaning + Dataset Preparation (Berry Grading + Export Price Forecasting)

This document covers **Phase 2** of the *Berry Grading and Export Price Forecasting* component: cleaning, validation, preprocessing, and split preparation. **No model training is performed in this phase.**

## Datasets (Inputs)

### Historical price dataset
- Source file: `data/raw/market_prices/dea_farmgate_weekly_prices_2016_2026.csv`
- Granularity: weekly (farm-gate)
- Key fields: `date`, `district`, `grade`, `price_type`, `price_lkr_per_kg`

### Berry image dataset
- Root folder: `data/raw/berry_images/`
- Label file: `data/annotations/grading_forecast/berry_grading_labels.csv`
- Classes: `Grade 1`, `Grade 2`, `Grade 3`

### Legacy / demo-only files (NOT used for final ML training)
These are kept for reference only and were moved to:
- `data/raw/market_prices/legacy/sample_black_pepper_prices.csv`
- `data/raw/market_prices/legacy/ipc_monthly_local_prices_2013_2022.csv`

## Cleaning + Preparation Pipeline

### 1) Price data cleaning
Script: `ml/grading_forecast/price_forecasting/data/clean_price_data.py`

Cleaning operations:
- Parse `date` with `pandas.to_datetime`
- Standardize district names (e.g., underscores -> spaces; title-casing)
- Standardize grade labels (e.g., `grade_1` -> `Grade 1`)
- Parse numeric prices (e.g., `"2,200.00"` -> `2200.0`)
- Remove duplicates using (`date`, `district`, `grade`, `price_type`)
- Drop invalid rows (missing/malformed date, district/grade/price_type, missing price)
- Sort chronologically ascending

Output:
- `data/processed/grading_forecast/cleaned_price_data.csv` (**7198 rows**, 2021-02-22 to 2026-04-21)

### 2) Forecasting subset strategy (baseline)
Script: `ml/grading_forecast/price_forecasting/data/prepare_forecast_training_data.py`

Research decision for the **first real forecasting model**:
- Use only `district = National`, `grade = Grade 1`, `price_type = average`
- Rationale: most complete subset, least missing values, stable baseline for evaluation/visualization

Note:
- **District-wise forecasting is identified as future work due to inconsistent district-level data availability and grade sparsity.**

Output:
- `data/processed/grading_forecast/forecast_training_data.csv` (**216 rows**, columns: `date`, `price_lkr_per_kg`)

### 3) Time series train/test split (chronological)
Script: `ml/grading_forecast/price_forecasting/data/create_forecast_split.py`

Split policy:
- Chronological split, **no shuffle**
- 80% train / 20% test

Outputs:
- `data/processed/grading_forecast/train_forecast_data.csv` (**172 rows**, 2021-02-22 to 2025-06-03)
- `data/processed/grading_forecast/test_forecast_data.csv` (**44 rows**, 2025-06-11 to 2026-04-21)

### 4) Berry image dataset validation (no permanent changes)
Script: `ml/grading_forecast/berry_grading/preprocessing/validate_dataset.py`

Validation checks:
- Labeled image path exists
- Image is readable
- Image dimensions are valid
- Grade label is valid
- Detect duplicate image paths in labels CSV

Output:
- `data/processed/grading_forecast/berry_dataset_validation_summary.json`
  - Total: **360**, Valid: **360**, Invalid: **0**
  - Per class: Grade 1 = 120, Grade 2 = 120, Grade 3 = 120

### 5) Image preprocessing (processed copies only)
Script: `ml/grading_forecast/berry_grading/preprocessing/prepare_training_images.py`

Preprocessing:
- Read from `data/raw/berry_images/`
- Convert to RGB
- Resize to **224x224** using letterbox padding to preserve aspect ratio
- Compute dataset mean/std in [0, 1] space for later normalization during training
- Save **processed copies** (raw images are not modified)

Outputs:
- `data/processed/grading_forecast/berry_images_processed/` (360 processed images; preserves `grade_1/`, `grade_2/`, `grade_3/` structure)
- `data/processed/grading_forecast/berry_preprocessing_summary.json`

## Safe execution guarantees
All scripts:
- Use project-relative paths via automatic repo-root detection
- Create output folders automatically
- Exit with a clear message if required input folders/files are missing

## How to run (order)
From repository root:
- `python ml/grading_forecast/price_forecasting/data/clean_price_data.py`
- `python ml/grading_forecast/price_forecasting/data/prepare_forecast_training_data.py`
- `python ml/grading_forecast/price_forecasting/data/create_forecast_split.py`
- `python ml/grading_forecast/berry_grading/preprocessing/validate_dataset.py`
- `python ml/grading_forecast/berry_grading/preprocessing/prepare_training_images.py`

## Dataset limitations
- District-level series are uneven and sparse across time; grades are also sparse in some districts.
- The current price dataset contains Grade 1 and Grade 2 only (no Grade 3 records).
- Image labels currently include mostly `unknown` sub-attributes (size/color/texture/etc.); only `grade` is used in Phase 2.

## Future work
- District-wise forecasting (once district-level completeness improves)
- Larger berry grading dataset (more varied samples, lighting conditions, collection days)
- Additional export-quality measurements and labels (e.g., defect percentages, moisture, foreign matter, mould/insect indicators)

