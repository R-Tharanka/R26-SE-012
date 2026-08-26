# Experiment Log: Berry Grading and Export Price Forecasting

Last updated: 2026-08-26

This document records dataset versions, model experiments, metrics, observations, and model-selection reasoning. Do not enter fabricated metrics. Use `PENDING` until an experiment is actually run.

## Dataset Versions

| Dataset ID | Type | Source | Status | Notes |
| --- | --- | --- | --- | --- |
| berry_v1 | Image classification | `data/processed/grading_forecast/berry_images_processed/` | LEGACY | 360 processed images, 120 per class, created before current dataset expansion. |
| berry_v2 | Image classification | `data/raw/berry_images/` | PREPARED | 671 readable JPGs. V2 manifest and deterministic sample-level train/validation/test split created with seed 42. |
| price_v1 | Forecasting | `data/processed/grading_forecast/forecast_training_data.csv` | LEGACY | 216 National Grade 1 average rows through 2026-04-21. |
| price_v2 | Forecasting | `data/raw/market_prices/dea_farmgate_weekly_prices_2016_2026.csv` | PREPARED | 7,742 preserved rows. Primary target has 232 National Grade 1 average farm-gate weekly observations through 2026-08-18. |

## Dataset Preparation Entries

| Entry ID | Status | Dataset | Script | Output Artifacts | Validation Result | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| DATASET-BERRY-V2-PREP | COMPLETE | berry_v2 | `ml/grading_forecast/berry_grading/preprocessing/prepare_berry_dataset_v2.py` | `berry_grading_labels_v2.csv`, `berry_dataset_v2_summary.json`, `berry_split_v2/`, `berry_split_v2_manifest.csv` | PASSED | 168 physical sample groups. Split: train 117 samples/467 images, validation 24 samples/95 images, test 27 samples/109 images. No `grade + sample_id` group crosses splits. |
| DATASET-PRICE-V2-PREP | COMPLETE | price_v2 | `ml/grading_forecast/price_forecasting/data/prepare_price_v2_dataset.py` | `cleaned_price_data_v2.csv`, `national_grade1_average_weekly.csv`, `price_v2_coverage_summary.json`, `forecast_train.csv`, `forecast_validation.csv`, `forecast_test.csv` | PASSED | Chronological split: train 2021-02-22 to 2025-03-18, validation 2025-03-25 to 2025-11-25, test 2025-12-02 to 2026-08-18. Missing weeks were documented, not fabricated. |

## Experiment Register

| Experiment ID | Status | Dataset | Split | Model/Method | Purpose | Key Config | Metrics | Artifact Path | Observation | Decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BERRY-V1-MNV2 | COMPLETE | berry_v1 | image-level/dir train-val split | MobileNetV2 | Historical baseline | 224x224, transfer learning, augmentation, fine-tune top layers | Accuracy 0.7778, weighted F1 0.7447 | `ml/grading_forecast/berry_grading/models/berry_classifier_metrics.json` | Grade 2 recall was weak at 0.3333. No separate test split. | Keep as historical baseline only. |
| PRICE-V1-RF | COMPLETE | price_v1 | chronological train-test | RandomForestRegressor | Historical forecasting baseline | lag_1..3, rolling 3/5, time features | Test MAE 45.8347, RMSE 47.7556, R2 -6.1315 | `ml/grading_forecast/price_forecasting/models/forecast_metrics.json` | Weak future generalization despite strong train metrics. | Keep as historical baseline only. |
| BERRY-V2-MNV2 | NOT STARTED | berry_v2 | sample-level train-val-test | MobileNetV2 | Primary PP2 berry baseline | PENDING | PENDING | PENDING | Must prevent sample leakage. | PENDING |
| BERRY-V2-IMPROVE-1 | OPTIONAL | berry_v2 | same as BERRY-V2-MNV2 | MobileNetV2 tuned | Limited improvement | PENDING | PENDING | PENDING | Run only after baseline. | PENDING |
| PRICE-V2-NAIVE | NOT STARTED | price_v2 | chronological train-val-test | Naive persistence | Required forecast baseline | y_next = y_current | PENDING | PENDING | Must be compared on same test period as RF. | PENDING |
| PRICE-V2-RF | NOT STARTED | price_v2 | chronological train-val-test | RandomForestRegressor | Primary PP2 forecast model | lag/rolling past-only features | PENDING | PENDING | Target: National Grade 1 average farm-gate weekly. | PENDING |
| PRICE-V2-IMPROVE-1 | OPTIONAL | price_v2 | same as PRICE-V2-RF | Tuned RandomForest | Limited improvement | PENDING | PENDING | PENDING | Run only after baseline. | PENDING |

## Required Metric Fields

Berry grading:

- accuracy
- precision per class
- recall per class
- F1 per class
- macro F1
- weighted F1
- confusion matrix
- inference latency if measured

Price forecasting:

- MAE
- RMSE
- MAPE
- R2
- actual vs predicted plot
- residual plot if available
- feature importance if RandomForest is used

## Model Selection Rules

Berry:

- Do not select a model using validation performance only.
- Use the untouched test split for final PP2 metric reporting.
- Inspect Grade 2 recall and confusion with Grade 3.
- Prefer the model with reliable generalization, not only highest apparent accuracy.

Forecasting:

- The RandomForest model must beat or reasonably justify itself against naive persistence.
- If RandomForest does not beat naive, report that honestly and keep the best method as the PP2 baseline.
- Use MAE/RMSE/MAPE as the main practical metrics; R2 may be unstable in short or low-variance test windows.

## Logging Template

Use this template for each new experiment:

```text
Experiment ID:
Date:
Dataset version:
Split version:
Model/method:
Objective:
Configuration:
Training command:
Evaluation command:
Metrics:
Artifacts:
Observation:
Decision:
Limitations:
```
