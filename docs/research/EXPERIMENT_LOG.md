# Experiment Log: Berry Grading and Export Price Forecasting

Last updated: 2026-08-27

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

## Pipeline Preparation Entries

| Entry ID | Status | Scope | Files Updated | Validation Result | Notes |
| --- | --- | --- | --- | --- | --- |
| PIPELINE-BERRY-V2-SAFE | COMPLETE | Berry grading V2 pre-training pipeline | `train_berry_classifier.py`, `evaluate_berry_classifier.py`, `export_berry_model.py`, `predict_berry_grade.py` | PASSED | Added explicit V2 train/val/test and output-path support. Dry-runs resolve to `berry_split_v2` and `models/v2`. No model training performed. |
| PIPELINE-PRICE-V2-SAFE | COMPLETE | Price forecasting V2 pre-execution pipeline | `train_forecast_model.py`, `evaluate_forecast_model.py`, `export_forecast_model.py`, `predict_future_price.py` | PASSED | Added explicit V2 path checks, dry-runs, same-test-timestamp evaluation plan, naive persistence metrics support, and V2 output-path support. No RandomForest training or final test evaluation performed. |

## Integration Validation Entries

| Entry ID | Status | Scope | Evidence | Validation Result | Notes |
| --- | --- | --- | --- | --- | --- |
| INTEGRATION-PHASE5-BACKEND | COMPLETE | Backend grading forecast API | `docs/research/PP2_INTEGRATION_VALIDATION.md` | PASSED WITH LIMITATIONS | FastAPI started and health, price forecast, grade-only, and analyze endpoints returned HTTP 200. Runtime grading used the legacy/root ONNX artifact. Runtime forecasting returned `demo_baseline`. Firebase storage was not configured and returned `saved_to_firebase: false`. |

## Experiment Register

| Experiment ID | Status | Dataset | Split | Model/Method | Purpose | Key Config | Metrics | Artifact Path | Observation | Decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BERRY-V1-MNV2 | COMPLETE | berry_v1 | image-level/dir train-val split | MobileNetV2 | Historical baseline | 224x224, transfer learning, augmentation, fine-tune top layers | Accuracy 0.7778, weighted F1 0.7447 | `ml/grading_forecast/berry_grading/models/berry_classifier_metrics.json` | Grade 2 recall was weak at 0.3333. No separate test split. | Keep as historical baseline only. |
| PRICE-V1-RF | COMPLETE | price_v1 | chronological train-test | RandomForestRegressor | Historical forecasting baseline | lag_1..3, rolling 3/5, time features | Test MAE 45.8347, RMSE 47.7556, R2 -6.1315 | `ml/grading_forecast/price_forecasting/models/forecast_metrics.json` | Weak future generalization despite strong train metrics. | Keep as historical baseline only. |
| BERRY-V2-MNV2 | COMPLETE | berry_v2 | sample-level train-val-test | MobileNetV2 | Primary PP2 berry baseline | ImageNet, 224x224 RGB, batch 16, Adam, sparse categorical cross-entropy, stage1 15 max epochs LR 0.001, stage2 5 max epochs LR 0.00001 | Accuracy 0.8073, macro F1 0.8068, weighted F1 0.8076, Grade 2 precision 0.7805, Grade 2 recall 0.8889, Grade 2 F1 0.8312 | `ml/grading_forecast/berry_grading/models/v2/` | Trained on V2 train/val only, evaluated once on untouched V2 test set. ONNX export succeeded. | Select as PP2 berry baseline. |
| BERRY-V2-IMPROVE-1 | COMPLETE | berry_v2 | same as BERRY-V2-MNV2 | MobileNetV2 dropout 0.35 | Limited berry improvement | Same as Phase 2 baseline except dropout 0.25 -> 0.35 | Accuracy 0.8073, macro F1 0.8068, weighted F1 0.8076, Grade 2 precision 0.7805, Grade 2 recall 0.8889, Grade 2 F1 0.8312 | `ml/grading_forecast/berry_grading/models/v2_phase4/` | Saved headline metrics matched Phase 2 baseline; model hash differs from Phase 2. | Do not replace Phase 2 baseline based on this result. |
| PRICE-V2-NAIVE | COMPLETE | price_v2 | chronological train-val-test | Naive persistence | Required forecast baseline | prediction(t+1) = observed price(t) | MAE 16.4094, RMSE 22.5208, MAPE 0.8539, R2 0.9045 | `ml/grading_forecast/price_forecasting/models/v2/naive_persistence_metrics.json` | Evaluated on same 36 V2 test timestamps as RF. | Selected as stronger Phase 3 forecast baseline. |
| PRICE-V2-RF | COMPLETE | price_v2 | chronological train-val-test | RandomForestRegressor | Primary PP2 ML forecast baseline | 400 trees, random_state 42, lag/rolling past-only features | MAE 82.4179, RMSE 88.4452, MAPE 4.1679, R2 -0.4736 | `ml/grading_forecast/price_forecasting/models/v2/` | Underperformed naive persistence on the V2 test period. | Keep as required ML baseline; do not claim superiority. |
| PRICE-V2-IMPROVE-1 | COMPLETE | price_v2 | same as PRICE-V2-RF | Extended-lag RandomForest | Limited forecast improvement | Phase 3 RF plus `lag_4`, `lag_8`, `lag_12` | MAE 78.1641, RMSE 84.8622, MAPE 3.9482, R2 -0.3566 | `ml/grading_forecast/price_forecasting/models/v2_phase4/` | Improved over Phase 3 RF, but still underperformed Naive Persistence. | Record as limited RF improvement; keep Naive Persistence as strongest forecast baseline. |

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

## Prepared Phase 3 Commands

These commands are prepared for Phase 3 execution. Do not run them until Phase 3 execution is explicitly started.

RandomForest training command:

```powershell
.\.venv\Scripts\python.exe ml/grading_forecast/price_forecasting/training/train_forecast_model.py --train-csv data/processed/grading_forecast/price_v2/forecast_train.csv --validation-csv data/processed/grading_forecast/price_v2/forecast_validation.csv --test-csv data/processed/grading_forecast/price_v2/forecast_test.csv --target-csv data/processed/grading_forecast/price_v2/national_grade1_average_weekly.csv --models-dir ml/grading_forecast/price_forecasting/models/v2 --dataset-version v2 --artifact-version v2 --seed 42 --n-estimators 400 --min-samples-leaf 1 --n-jobs -1 --require-v2-paths
```

Same-test-timestamp evaluation command:

```powershell
.\.venv\Scripts\python.exe ml/grading_forecast/price_forecasting/training/evaluate_forecast_model.py --target-csv data/processed/grading_forecast/price_v2/national_grade1_average_weekly.csv --test-csv data/processed/grading_forecast/price_v2/forecast_test.csv --models-dir ml/grading_forecast/price_forecasting/models/v2 --output-dir ml/grading_forecast/price_forecasting/evaluation/_outputs/v2 --split-name test --require-v2-paths
```

Forecast export-manifest command:

```powershell
.\.venv\Scripts\python.exe ml/grading_forecast/price_forecasting/training/export_forecast_model.py --models-dir ml/grading_forecast/price_forecasting/models/v2 --require-v2-paths
```

V2 inference command after model creation:

```powershell
.\.venv\Scripts\python.exe ml/grading_forecast/price_forecasting/inference/predict_future_price.py --data-csv data/processed/grading_forecast/price_v2/national_grade1_average_weekly.csv --models-dir ml/grading_forecast/price_forecasting/models/v2 --require-v2-paths
```

Dry-run validation result from pre-execution preparation:

- Training dry-run resolves to V2 train/validation/test/target paths and `models/v2`.
- Training feature rows available from V2 train split: 156 from 162 input rows.
- Evaluation dry-run resolves to V2 target/test/model/output paths.
- Evaluation dry-run predicts exactly 36 timestamps, matching the 36-row V2 test split.
- `feature_date_before_prediction_date` is true for planned test predictions.
- No Phase 3 model training, final evaluation metrics, or final plots were generated during preparation.

## Completed Experiment Details

### BERRY-V2-MNV2

Date: 2026-08-27.

Dataset version: `berry_v2`.

Split version: `data/processed/grading_forecast/berry_split_v2_manifest.csv`.

Image/sample counts:

- Train: 117 samples, 467 images.
- Validation: 24 samples, 95 images.
- Test: 27 samples, 109 images.
- Leakage validation: no `grade + sample_id` group crosses train, validation, and test.

Model/method:

- MobileNetV2 transfer learning.
- ImageNet initialization.
- `include_top=False`.
- 224x224 RGB input.
- MobileNetV2 preprocessing inside the model.
- Light augmentation: horizontal flip, rotation 0.06, zoom 0.10, brightness factor 0.12.
- Classification head: global average pooling, dropout, dense softmax with 3 classes.

Configuration:

- Batch size: 16.
- Seed: 42.
- Loss: sparse categorical cross-entropy.
- Optimizer: Adam.
- Stage 1: frozen backbone, maximum 15 epochs, learning rate 0.001, patience 3; 14 epochs completed.
- Stage 2: limited fine-tuning of final MobileNetV2 layers, maximum 5 epochs, learning rate 0.00001, patience 2; 5 epochs completed.
- Best validation-loss checkpoint: Stage 2 epoch 5, validation loss 0.5248714089, validation accuracy 0.7473683953.

Training command:

```powershell
.\.venv\Scripts\python.exe ml/grading_forecast/berry_grading/training/train_berry_classifier.py --train-dir data/processed/grading_forecast/berry_split_v2/train --val-dir data/processed/grading_forecast/berry_split_v2/val --output-dir ml/grading_forecast/berry_grading/models/v2 --model-filename berry_mobilenetv2_v2_best.keras --metadata-version v2 --batch-size 16 --stage1-epochs 15 --stage2-epochs 5 --stage1-lr 1e-3 --stage2-lr 1e-5 --patience 3
```

Evaluation command:

```powershell
.\.venv\Scripts\python.exe ml/grading_forecast/berry_grading/training/evaluate_berry_classifier.py --model ml/grading_forecast/berry_grading/models/v2/berry_mobilenetv2_v2_best.keras --models-dir ml/grading_forecast/berry_grading/models/v2 --data-dir data/processed/grading_forecast/berry_split_v2/test --output-dir ml/grading_forecast/berry_grading/evaluation/_outputs/v2 --use-full-data-dir --split-name test
```

Export command:

```powershell
.\.venv\Scripts\python.exe ml/grading_forecast/berry_grading/training/export_berry_model.py --model ml/grading_forecast/berry_grading/models/v2/berry_mobilenetv2_v2_best.keras --out ml/grading_forecast/berry_grading/models/v2/berry_mobilenetv2_v2_best.onnx --metadata-out ml/grading_forecast/berry_grading/models/v2/onnx_metadata.json
```

Metrics:

- Accuracy: 0.8073.
- Grade 1 precision/recall/F1: 0.9063 / 0.7632 / 0.8286.
- Grade 2 precision/recall/F1: 0.7805 / 0.8889 / 0.8312.
- Grade 3 precision/recall/F1: 0.7500 / 0.7714 / 0.7606.
- Macro precision/recall/F1: 0.8122 / 0.8078 / 0.8068.
- Weighted precision/recall/F1: 0.8145 / 0.8073 / 0.8076.
- Inference timing: average 78.487 ms, p95 107.546 ms, 80 single-image runs.

Artifacts:

- `ml/grading_forecast/berry_grading/models/v2/berry_mobilenetv2_v2_best.keras`
- `ml/grading_forecast/berry_grading/models/v2/berry_mobilenetv2_v2_best.onnx`
- `ml/grading_forecast/berry_grading/models/v2/class_names.json`
- `ml/grading_forecast/berry_grading/models/v2/training_history.json`
- `ml/grading_forecast/berry_grading/models/v2/berry_model_metadata.json`
- `ml/grading_forecast/berry_grading/models/v2/berry_classifier_metrics.json`
- `ml/grading_forecast/berry_grading/models/v2/onnx_metadata.json`
- `ml/grading_forecast/berry_grading/evaluation/_outputs/v2/confusion_matrix.png`
- `ml/grading_forecast/berry_grading/evaluation/_outputs/v2/training_curves.png`

Observation:

V2 Grade 2 recall improved compared with the historical V1 metric, but V1 and V2 are not directly equivalent experiments because V2 uses the expanded dataset and leakage-safe sample-level split.

Decision:

Use `BERRY-V2-MNV2` as the PP2 berry grading baseline.

Limitations:

- Small dataset: 168 physical sample groups and 671 images.
- Camera-based visual grading only; no chemical or official SLS certification measurements.
- Native Windows TensorFlow used CPU only in the observed training environment.
- Initial write attempts for training/evaluation/export hit permission errors and were rerun with permission escalation using the same commands and methodology.

### FORECAST-V2-RF

Date: 2026-08-27.

Dataset version: `price_v2`.

Target definition: National + Grade 1 + average + farm_gate + weekly.

Split version:

- Full target: `data/processed/grading_forecast/price_v2/national_grade1_average_weekly.csv`.
- Train: `data/processed/grading_forecast/price_v2/forecast_train.csv`.
- Validation: `data/processed/grading_forecast/price_v2/forecast_validation.csv`.
- Test: `data/processed/grading_forecast/price_v2/forecast_test.csv`.

Rows/date ranges:

- Target: 232 rows, 2021-02-22 to 2026-08-18.
- Train: 162 rows, 2021-02-22 to 2025-03-18.
- Validation: 34 rows, 2025-03-25 to 2025-11-25.
- Test: 36 rows, 2025-12-02 to 2026-08-18.

Model/methods:

- Required baseline: Naive Persistence, `prediction(t+1) = observed price(t)`.
- ML baseline: RandomForestRegressor.

RandomForest configuration:

- `n_estimators`: 400.
- `random_state`: 42.
- `n_jobs`: -1.
- `max_depth`: None.
- `min_samples_leaf`: 1.

Feature list:

- `lag_1`
- `lag_2`
- `lag_3`
- `rolling_mean_3`
- `rolling_std_3`
- `rolling_mean_5`
- `rolling_std_5`
- `month`
- `week_of_year`
- `price_change_1w`
- `price_change_pct_1w`

Temporal feature methodology:

- Lag features use previous available observations, not guaranteed previous calendar weeks.
- Rolling features use previous available observations with shifted history.
- Test features use full target context but each feature date is before its prediction date.
- No missing calendar weeks were fabricated or interpolated.
- Grade 2 observations were not used as the forecasting target.

Training command:

```powershell
.\.venv\Scripts\python.exe ml/grading_forecast/price_forecasting/training/train_forecast_model.py --train-csv data/processed/grading_forecast/price_v2/forecast_train.csv --validation-csv data/processed/grading_forecast/price_v2/forecast_validation.csv --test-csv data/processed/grading_forecast/price_v2/forecast_test.csv --target-csv data/processed/grading_forecast/price_v2/national_grade1_average_weekly.csv --models-dir ml/grading_forecast/price_forecasting/models/v2 --dataset-version v2 --artifact-version v2 --seed 42 --n-estimators 400 --min-samples-leaf 1 --n-jobs -1 --require-v2-paths
```

Evaluation command:

```powershell
.\.venv\Scripts\python.exe ml/grading_forecast/price_forecasting/training/evaluate_forecast_model.py --target-csv data/processed/grading_forecast/price_v2/national_grade1_average_weekly.csv --test-csv data/processed/grading_forecast/price_v2/forecast_test.csv --models-dir ml/grading_forecast/price_forecasting/models/v2 --output-dir ml/grading_forecast/price_forecasting/evaluation/_outputs/v2 --split-name test --require-v2-paths
```

Export-manifest command:

```powershell
.\.venv\Scripts\python.exe ml/grading_forecast/price_forecasting/training/export_forecast_model.py --models-dir ml/grading_forecast/price_forecasting/models/v2 --require-v2-paths
```

Execution durations:

- RandomForest training command duration: 5.6078 seconds.
- Evaluation command duration: 5.2312 seconds.
- Export-manifest command duration: 0.0932 seconds.

Final test metrics:

| Method | MAE | RMSE | MAPE | R2 |
| --- | ---: | ---: | ---: | ---: |
| Naive Persistence | 16.4094 | 22.5208 | 0.8539 | 0.9045 |
| RandomForest | 82.4179 | 88.4452 | 4.1679 | -0.4736 |

Artifacts:

- `ml/grading_forecast/price_forecasting/models/v2/forecast_model.joblib`
- `ml/grading_forecast/price_forecasting/models/v2/forecast_features.json`
- `ml/grading_forecast/price_forecasting/models/v2/forecast_metrics.json`
- `ml/grading_forecast/price_forecasting/models/v2/naive_persistence_metrics.json`
- `ml/grading_forecast/price_forecasting/models/v2/forecast_model_metadata.json`
- `ml/grading_forecast/price_forecasting/models/v2/forecast_export_manifest.json`
- `ml/grading_forecast/price_forecasting/evaluation/_outputs/v2/actual_vs_predicted.png`
- `ml/grading_forecast/price_forecasting/evaluation/_outputs/v2/feature_importances.png`
- `ml/grading_forecast/price_forecasting/evaluation/_outputs/v2/residuals.png`

Observation:

Naive Persistence clearly outperformed RandomForest on the 36-row V2 test period. The RandomForest model had strong training metrics but poor test generalization, suggesting overfitting and/or a test period where simple persistence is stronger.

Decision:

Use Naive Persistence as the stronger Phase 3 forecasting baseline for PP2. Keep RandomForest as the required ML baseline result and report honestly that it did not outperform the naive baseline.

Limitations:

- Primary target is Grade 1 only.
- Grade 2 coverage is sparse and remains out of scope for Phase 3.
- Missing calendar weeks exist, including a historical 316-day gap.
- Lags and rolling windows mean previous available observations, not exact calendar weeks.
- Test period is short: 36 prediction timestamps.
- No hyperparameter search or advanced time-series model was performed.
- Initial write attempts for training/evaluation/export hit permission errors and were rerun with permission escalation using the same commands and methodology.

### BERRY-V2-IMPROVE-1

Date: 2026-08-27.

Dataset version: `berry_v2`.

Split version: `data/processed/grading_forecast/berry_split_v2_manifest.csv`.

Objective:

Test one limited berry grading improvement by changing only dropout from the Phase 2 baseline value of 0.25 to 0.35.

Configuration:

- Model: MobileNetV2 transfer learning.
- ImageNet initialization: true.
- Input: 224x224 RGB.
- Batch size: 16.
- Seed: 42.
- Stage 1 maximum epochs: 15, learning rate 0.001.
- Stage 2 maximum epochs: 5, learning rate 0.00001.
- Fine-tuned MobileNetV2 layers: final 20 layers.
- Selected improvement variable: dropout 0.35.
- Same V2 train/validation/test split as Phase 2.

Training command for reproduction:

```powershell
.\.venv\Scripts\python.exe ml/grading_forecast/berry_grading/training/train_berry_classifier.py --train-dir data/processed/grading_forecast/berry_split_v2/train --val-dir data/processed/grading_forecast/berry_split_v2/val --output-dir ml/grading_forecast/berry_grading/models/v2_phase4 --model-filename berry_mobilenetv2_v2_phase4_best.keras --metadata-version v2_phase4 --batch-size 16 --stage1-epochs 15 --stage2-epochs 5 --stage1-lr 1e-3 --stage2-lr 1e-5 --patience 3 --dropout 0.35
```

Evaluation command:

```powershell
.\.venv\Scripts\python.exe ml/grading_forecast/berry_grading/training/evaluate_berry_classifier.py --model ml/grading_forecast/berry_grading/models/v2_phase4/berry_mobilenetv2_v2_phase4_best.keras --models-dir ml/grading_forecast/berry_grading/models/v2_phase4 --data-dir data/processed/grading_forecast/berry_split_v2/test --output-dir ml/grading_forecast/berry_grading/evaluation/_outputs/v2_phase4 --use-full-data-dir --split-name test
```

Metrics:

- Accuracy: 0.8073.
- Grade 1 precision/recall/F1: 0.9063 / 0.7632 / 0.8286.
- Grade 2 precision/recall/F1: 0.7805 / 0.8889 / 0.8312.
- Grade 3 precision/recall/F1: 0.7500 / 0.7714 / 0.7606.
- Macro precision/recall/F1: 0.8122 / 0.8078 / 0.8068.
- Weighted precision/recall/F1: 0.8145 / 0.8073 / 0.8076.

Artifacts:

- `ml/grading_forecast/berry_grading/models/v2_phase4/berry_mobilenetv2_v2_phase4_best.keras`
- `ml/grading_forecast/berry_grading/models/v2_phase4/class_names.json`
- `ml/grading_forecast/berry_grading/models/v2_phase4/berry_classifier_metrics.json`
- `ml/grading_forecast/berry_grading/models/v2_phase4/berry_model_metadata.json`
- `ml/grading_forecast/berry_grading/evaluation/_outputs/v2_phase4/confusion_matrix.png`

Observation:

The dropout 0.35 model produced the same saved headline test metrics and confusion matrix as the Phase 2 V2 baseline. The Phase 4 model file has a different SHA256 hash from the Phase 2 model, so it is a separate artifact, but it did not produce measurable test-metric improvement.

Decision:

Record the dropout experiment as a valid limited Phase 4 result, but keep `BERRY-V2-MNV2` as the selected PP2 berry grading baseline.

Limitations:

- Only one berry improvement was tested.
- No hyperparameter search was performed.
- `training_history.json` was not present in the Phase 4 berry artifact directory during finalization, so exact completed epoch counts are unavailable from saved artifacts.

### PRICE-V2-IMPROVE-1

Date: 2026-08-27.

Dataset version: `price_v2`.

Target definition: National + Grade 1 + average + farm_gate + weekly.

Objective:

Test one limited forecasting improvement by adding longer historical lag features to the Phase 3 RandomForest baseline.

Configuration:

- Model: RandomForestRegressor.
- `n_estimators`: 400.
- `random_state`: 42.
- `n_jobs`: -1.
- `max_depth`: None.
- `min_samples_leaf`: 1.
- Added features: `lag_4`, `lag_8`, `lag_12`.
- Same 36 V2 test timestamps as Phase 3.

Feature list:

- `lag_1`
- `lag_2`
- `lag_3`
- `lag_4`
- `lag_8`
- `lag_12`
- `rolling_mean_3`
- `rolling_std_3`
- `rolling_mean_5`
- `rolling_std_5`
- `month`
- `week_of_year`
- `price_change_1w`
- `price_change_pct_1w`

Training command:

```powershell
.\.venv\Scripts\python.exe ml/grading_forecast/price_forecasting/training/train_forecast_model_phase4.py --train-csv data/processed/grading_forecast/price_v2/forecast_train.csv --validation-csv data/processed/grading_forecast/price_v2/forecast_validation.csv --test-csv data/processed/grading_forecast/price_v2/forecast_test.csv --target-csv data/processed/grading_forecast/price_v2/national_grade1_average_weekly.csv --models-dir ml/grading_forecast/price_forecasting/models/v2_phase4 --dataset-version v2 --artifact-version v2_phase4 --seed 42 --n-estimators 400 --min-samples-leaf 1 --n-jobs -1 --require-v2-paths
```

Evaluation command:

```powershell
.\.venv\Scripts\python.exe ml/grading_forecast/price_forecasting/training/evaluate_forecast_model_phase4.py --target-csv data/processed/grading_forecast/price_v2/national_grade1_average_weekly.csv --test-csv data/processed/grading_forecast/price_v2/forecast_test.csv --models-dir ml/grading_forecast/price_forecasting/models/v2_phase4 --phase3-models-dir ml/grading_forecast/price_forecasting/models/v2 --output-dir ml/grading_forecast/price_forecasting/evaluation/_outputs/v2_phase4 --split-name test --require-v2-paths
```

Final test metrics:

| Method | MAE | RMSE | MAPE | R2 |
| --- | ---: | ---: | ---: | ---: |
| Naive Persistence | 16.4094 | 22.5208 | 0.8539 | 0.9045 |
| Phase 3 RandomForest | 82.4179 | 88.4452 | 4.1679 | -0.4736 |
| Phase 4 Extended-Lag RandomForest | 78.1641 | 84.8622 | 3.9482 | -0.3566 |

Artifacts:

- `ml/grading_forecast/price_forecasting/models/v2_phase4/forecast_model.joblib`
- `ml/grading_forecast/price_forecasting/models/v2_phase4/forecast_features.json`
- `ml/grading_forecast/price_forecasting/models/v2_phase4/forecast_metrics.json`
- `ml/grading_forecast/price_forecasting/models/v2_phase4/naive_persistence_metrics.json`
- `ml/grading_forecast/price_forecasting/models/v2_phase4/forecast_model_metadata.json`
- `ml/grading_forecast/price_forecasting/evaluation/_outputs/v2_phase4/actual_vs_predicted.png`
- `ml/grading_forecast/price_forecasting/evaluation/_outputs/v2_phase4/feature_importances.png`
- `ml/grading_forecast/price_forecasting/evaluation/_outputs/v2_phase4/residuals.png`

Observation:

The extended-lag RandomForest improved over the Phase 3 RandomForest baseline on MAE, RMSE, MAPE, and R2. However, Naive Persistence remained much stronger on the same 36 test timestamps.

Decision:

Record the extended-lag result as a valid limited RF improvement, but keep Naive Persistence as the strongest PP2 forecasting method for the current V2 test period.

Limitations:

- Only one forecasting improvement was tested.
- Missing calendar weeks remain; lags represent previous available observations.
- Test period contains only 36 prediction timestamps.
- Grade 2 forecasting remains out of scope.
