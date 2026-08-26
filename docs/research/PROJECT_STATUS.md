# Project Status: Berry Grading and Export Price Forecasting

Last updated: 2026-08-26

This document is the current source of truth for the PP2 recovery work for the individual component: Berry Grading and Export Price Forecasting.

## Current Phase

Current phase: Phase 2 - Berry Grading V2 Baseline

Phase 0, Repository and Research Audit, is complete.

Phase 1, Dataset V2 Preparation and Audit, is complete. Raw datasets and V1 artifacts were preserved. No model training was performed during Phase 1.

## Project Scope

Full research project: Multimodal AI-Based Pest, Disease Detection and Export Price Prediction System for Black Pepper.

Individual component: Berry Grading and Export Price Forecasting.

Component responsibilities:

- Classify harvested black pepper berry batches into Grade 1, Grade 2, and Grade 3 using smartphone images.
- Forecast short-term black pepper price trends from historical market data.
- Combine grading and forecasting outputs into sell, wait, or process recommendations.
- Provide outputs through the shared FastAPI backend and Flutter mobile application.
- Store results in Firebase when credentials are configured.

Non-responsibilities:

- Pest detection.
- Leaf disease detection and severity scoring.
- Pepper berry disease detection, lesion segmentation, or remediation.
- Official SLS certification.

## Official Requirement Summary

The proposal and TAF require:

- Berry image dataset collection and preprocessing.
- Historical market price dataset collection and preprocessing.
- Visual quality feature extraction from berry images.
- Machine learning model for berry grading.
- Time-series or machine learning model for short-term price forecasting.
- Standard model evaluation.
- Integration into a mobile/backend decision-support workflow.

Important implementation boundary:

The SLS 105 Part 1: 2022 reference includes visual, physical, and chemical requirements. This project can only estimate camera-visible indicators. It cannot measure moisture, ash, volatile oil, piperine, non-volatile ether extract, or bulk density from images.

## Repository Status Summary

| Area | Status | Notes |
| --- | --- | --- |
| Research audit | COMPLETE | Official documents, guides, codebase, raw data, processed data, and model artifacts were inspected. |
| Backend API | EXISTS BUT NEEDS VALIDATION | FastAPI routes and services exist for grading, forecasting, recommendations, and storage. |
| Flutter UI | PARTIALLY COMPLETED | Component screens and API client exist; PP2 needs only demo validation, not new UI work. |
| Firebase storage | EXISTS BUT NEEDS LIVE VALIDATION | Safe fallback exists when Firebase is not configured. |
| Berry V1 model | COMPLETED BUT OUTDATED | MobileNetV2 model exists, trained on old 360-image processed dataset. |
| Forecast V1 model | COMPLETED BUT OUTDATED | RandomForest artifact exists, trained on old processed price data through 2026-04-21. |
| Berry V2 data | PREPARED | V2 manifest, audit summary, and leakage-safe sample-level train/validation/test split were created. |
| Price V2 data | PREPARED | V2 cleaned data, National Grade 1 average weekly target, coverage summary, and chronological split were created. |
| EDA notebooks | NOT STARTED | Notebook folders exist only as scaffolds. |
| PP2 evidence | PARTIALLY COMPLETE | Phase 1 dataset evidence is recorded; model metrics and integration evidence are still pending. |

## Dataset Status

### Berry Image Dataset

Raw root: `data/raw/berry_images/`

Audit facts:

- Total raw image files: 671 JPG files.
- Grade 1 images: 224.
- Grade 2 images: 224.
- Grade 3 images: 223.
- Sample folders per grade: 56.
- Root-level grade images: 0.
- Unreadable images found during audit: 0.
- Duplicate image-content groups found during audit: 0.
- Image dimensions observed: 4000x3000, 4080x3060, 8160x6120.
- Aspect ratio: 4:3 for all audited images.
- EXIF camera models found: SM-A127F and Galaxy A06.
- EXIF orientation values found: 1, 3, 6, 8.
- Most samples contain 4 images.
- Samples with non-4 image counts exist and must be documented, not manually fabricated.

Current issue:

`data/annotations/grading_forecast/berry_grading_labels.csv` has 360 rows and is outdated. It corresponds to V1, not the current 671-image raw dataset.

V2 artifacts:

- `data/annotations/grading_forecast/berry_grading_labels_v2.csv`
- `data/processed/grading_forecast/berry_dataset_v2_summary.json`
- `data/processed/grading_forecast/berry_split_v2/`
- `data/processed/grading_forecast/berry_split_v2_manifest.csv`

V2 split:

- Fixed random seed: 42.
- Train: 117 samples, 467 images.
- Validation: 24 samples, 95 images.
- Test: 27 samples, 109 images.
- Leakage validation: no `grade + sample_id` group crosses train, validation, and test.

### Price Dataset

Raw file: `data/raw/market_prices/dea_farmgate_weekly_prices_2016_2026.csv`

Audit facts:

- Total rows: 7,742.
- Columns include date, commodity, country, district, grade, price_type, price_lkr_per_kg, currency, unit, market_level, frequency, source, source_url.
- Date range: 2021-02-22 to 2026-08-18.
- Practical main coverage begins from early January 2022.
- Commodity: black_pepper.
- Country: Sri Lanka.
- Market level: farm_gate.
- Frequency: weekly.
- Price types: highest and average.
- Grades: Grade 1 and Grade 2.
- Grade 1 rows: 6,930.
- Grade 2 rows: 812.
- Duplicate rows by date, district, grade, and price_type: 0.

Recommended primary forecasting target:

`National + Grade 1 + average + farm_gate + weekly`

Reason:

National Grade 1 average has the strongest and most continuous historical coverage. Grade 2 has sparse early historical coverage and should not be fabricated.

V2 artifacts:

- `data/processed/grading_forecast/price_v2/cleaned_price_data_v2.csv`
- `data/processed/grading_forecast/price_v2/national_grade1_average_weekly.csv`
- `data/processed/grading_forecast/price_v2/price_v2_coverage_summary.json`
- `data/processed/grading_forecast/price_v2/forecast_train.csv`
- `data/processed/grading_forecast/price_v2/forecast_validation.csv`
- `data/processed/grading_forecast/price_v2/forecast_test.csv`

V2 target:

- Target observations: 232.
- Target date range: 2021-02-22 to 2026-08-18.
- Chronological split: train 2021-02-22 to 2025-03-18, validation 2025-03-25 to 2025-11-25, test 2025-12-02 to 2026-08-18.
- Missing target gaps greater than 8 days: 12.
- Largest target gap: 316 days from 2021-02-22 to 2022-01-04.

## V1 Artifact Status

Berry V1 artifacts:

- `ml/grading_forecast/berry_grading/models/berry_mobilenetv2_best.keras`
- `ml/grading_forecast/berry_grading/models/berry_mobilenetv2_best.onnx`
- `ml/grading_forecast/berry_grading/models/berry_classifier_metrics.json`
- `ml/grading_forecast/berry_grading/models/berry_model_metadata.json`

Berry V1 result:

- Accuracy: 0.7778.
- Weighted precision: 0.8516.
- Weighted recall: 0.7778.
- Weighted F1: 0.7447.
- Grade 2 recall: 0.3333.

Forecast V1 artifacts:

- `ml/grading_forecast/price_forecasting/models/forecast_model.joblib`
- `ml/grading_forecast/price_forecasting/models/forecast_features.json`
- `ml/grading_forecast/price_forecasting/models/forecast_metrics.json`
- `ml/grading_forecast/price_forecasting/models/forecast_model_metadata.json`

Forecast V1 result:

- Train MAE: 15.7114.
- Train RMSE: 24.3440.
- Train R2: 0.9841.
- Test MAE: 45.8347.
- Test RMSE: 47.7556.
- Test R2: -6.1315.

Interpretation:

V1 artifacts are useful as historical baselines and software integration evidence. They should not be treated as final PP2 research results for the current dataset.

## V1 Script Safety Notes

- `scripts/generate_grading_labels.py` defaults to `data/annotations/grading_forecast/berry_grading_labels.csv`, so accidental execution may overwrite the old V1 label CSV.
- `ml/grading_forecast/berry_grading/preprocessing/validate_dataset.py` defaults to the V1 labels path and writes a V1-style validation summary.
- `ml/grading_forecast/berry_grading/preprocessing/prepare_training_images.py` defaults to `data/processed/grading_forecast/berry_images_processed`, so accidental execution may overwrite or mix into the old processed image directory.
- `ml/grading_forecast/price_forecasting/data/clean_price_data.py`, `prepare_forecast_training_data.py`, and `create_forecast_split.py` default to V1 processed output filenames.
- For PP2 V2 work, use the new V2-specific scripts and output paths unless an old script is explicitly parameterized and checked first.

## Current Blockers

- Naive persistence baseline has not been properly recorded for forecasting comparison.
- V2 MobileNetV2 has not been trained on the sample-level split.
- V2 RandomForest and naive persistence forecasting baselines have not been run.
- No V2 model metrics, plots, or final experiment comparison table exists yet.

## Current Decision Record

- Use V1 MobileNetV2 as historical baseline only.
- Use V2 MobileNetV2 as the primary PP2 berry grading model.
- Use one limited MobileNetV2 improvement only if time permits.
- Use National Grade 1 average farm-gate weekly price as the primary forecasting target.
- Compare naive persistence against RandomForest for PP2 forecasting.
- Do not make ARIMA, SARIMA, XGBoost, Prophet, or LSTM mandatory before PP2.
- Do not fabricate missing Grade 2 price observations.
- Do not manually annotate unavailable camera/background/capture metadata for PP2.

## Next Exact Action

Execute Phase 2 from `docs/research/PP2_MASTER_PLAN.md`: Berry Grading V2 Baseline. Do not start Phase 3 until the Phase 2 action is explicitly requested or scheduled.
