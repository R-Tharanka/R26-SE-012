# Project Status: Berry Grading and Export Price Forecasting

Last updated: 2026-08-28

This document is the current source of truth for the PP2 recovery work for the individual component: Berry Grading and Export Price Forecasting.

## Current Phase

Current phase: Phase 7 Existing Implementation Audit complete. Next work is Phase 8 Berry V2 Runtime Integration.

Phase 0, Repository and Research Audit, is complete.

Phase 1, Dataset V2 Preparation and Audit, is complete. Raw datasets and V1 artifacts were preserved. No model training was performed during Phase 1.

Phase 2, Berry Grading V2 Baseline, is complete. The V2 MobileNetV2 model was trained on the sample-level V2 train/validation split, evaluated once on the untouched V2 test split, and exported to ONNX under V2-specific artifact paths.

Phase 3, Price Forecasting V2 Baseline, is complete. Naive Persistence and RandomForest were evaluated on the same 36 chronological V2 test timestamps. Naive Persistence outperformed RandomForest on the final test period.

Phase 4, Limited Model Improvement, is complete. The berry dropout experiment and forecasting extended-lag experiment were completed on the same V2 splits.

Phase 5, Integration Validation, is complete with runtime limitations. The backend API demo path is known and recorded.

Phase 6, PP2 Evidence and Documentation, is complete. Final PP2 result tables, speaking points, limitations, and evidence references are recorded.

Phase 7, Existing Implementation Audit, is complete. The current backend/mobile runtime behavior, model paths, fallback behavior, recommendation logic, Firebase/storage behavior, Flutter API contract, and Phase 8+ pending work were documented. No application code was changed during Phase 7.

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
| Backend API | VALIDATED WITH LIMITATIONS | FastAPI started and required grading-forecast endpoints returned HTTP 200 during Phase 5. |
| Flutter UI | PARTIALLY COMPLETED | Component screens and API client exist; PP2 needs only demo validation, not new UI work. |
| Firebase storage | FALLBACK VALIDATED | Firebase was not configured during Phase 5; analyze returned `saved_to_firebase: false` without blocking the response. |
| Berry V1 model | COMPLETED BUT OUTDATED | MobileNetV2 model exists, trained on old 360-image processed dataset. |
| Berry V2 model | COMPLETE | MobileNetV2 V2 baseline trained, tested, and exported under `ml/grading_forecast/berry_grading/models/v2/`. |
| Forecast V1 model | COMPLETED BUT OUTDATED | RandomForest artifact exists, trained on old processed price data through 2026-04-21. |
| Forecast V2 baseline | COMPLETE | Naive Persistence and RandomForest V2 were evaluated on identical test timestamps under `ml/grading_forecast/price_forecasting/models/v2/`. |
| Berry V2 data | PREPARED | V2 manifest, audit summary, and leakage-safe sample-level train/validation/test split were created. |
| Price V2 data | PREPARED | V2 cleaned data, National Grade 1 average weekly target, coverage summary, and chronological split were created. |
| EDA notebooks | NOT STARTED | Notebook folders exist only as scaffolds. |
| Limited improvement | COMPLETE | Phase 4 berry dropout 0.35 and forecast extended-lag RF experiments were completed and documented. |
| PP2 evidence | COMPLETE | Phase 1-6 dataset, model, integration, limitations, speaking points, and evidence references are recorded for PP2. |
| Existing implementation audit | COMPLETE | Phase 7 identified that runtime berry grading currently uses the legacy/root ONNX model, runtime forecasting can return `demo_baseline`, Firebase is optional/fail-safe, and Flutter end-to-end validation remains pending. |

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

## Berry V2 Model Result

Status: COMPLETE.

The berry training pipeline now supports the authoritative V2 data flow:

`data/raw/berry_images/` -> Phase 1 V2 preparation -> `berry_split_v2/train` and `berry_split_v2/val` -> MobileNetV2 training -> V2 model artifacts -> `berry_split_v2/test` final evaluation.

Required V2 output locations:

- Models: `ml/grading_forecast/berry_grading/models/v2/`
- Evaluation plots: `ml/grading_forecast/berry_grading/evaluation/_outputs/v2/`

Phase 2 artifacts:

- `ml/grading_forecast/berry_grading/models/v2/berry_mobilenetv2_v2_best.keras`
- `ml/grading_forecast/berry_grading/models/v2/berry_mobilenetv2_v2_best.onnx`
- `ml/grading_forecast/berry_grading/models/v2/class_names.json`
- `ml/grading_forecast/berry_grading/models/v2/training_history.json`
- `ml/grading_forecast/berry_grading/models/v2/berry_model_metadata.json`
- `ml/grading_forecast/berry_grading/models/v2/berry_classifier_metrics.json`
- `ml/grading_forecast/berry_grading/models/v2/onnx_metadata.json`
- `ml/grading_forecast/berry_grading/evaluation/_outputs/v2/confusion_matrix.png`
- `ml/grading_forecast/berry_grading/evaluation/_outputs/v2/training_curves.png`

Final V2 test result:

- Test images: 109.
- Accuracy: 0.8073.
- Macro F1: 0.8068.
- Weighted F1: 0.8076.
- Grade 2 precision: 0.7805.
- Grade 2 recall: 0.8889.
- Grade 2 F1: 0.8312.

Environment note:

- Training/export used the project `.venv`, where TensorFlow and tf2onnx are available.
- Native Windows TensorFlow ran on CPU; GPU support was not available in that environment.

## Price Forecasting V2 Result

Status: COMPLETE.

The price forecasting pipeline used the authoritative V2 target:

`National + Grade 1 + average + farm_gate + weekly`

Phase 3 artifacts:

- `ml/grading_forecast/price_forecasting/models/v2/forecast_model.joblib`
- `ml/grading_forecast/price_forecasting/models/v2/forecast_features.json`
- `ml/grading_forecast/price_forecasting/models/v2/forecast_metrics.json`
- `ml/grading_forecast/price_forecasting/models/v2/naive_persistence_metrics.json`
- `ml/grading_forecast/price_forecasting/models/v2/forecast_model_metadata.json`
- `ml/grading_forecast/price_forecasting/models/v2/forecast_export_manifest.json`
- `ml/grading_forecast/price_forecasting/evaluation/_outputs/v2/actual_vs_predicted.png`
- `ml/grading_forecast/price_forecasting/evaluation/_outputs/v2/feature_importances.png`
- `ml/grading_forecast/price_forecasting/evaluation/_outputs/v2/residuals.png`

Final V2 test result:

- Test prediction timestamps: 36.
- Same timestamps for naive and RandomForest: true.
- Feature dates before prediction dates: true.
- Naive Persistence MAE/RMSE/MAPE/R2: 16.4094 / 22.5208 / 0.8539 / 0.9045.
- RandomForest MAE/RMSE/MAPE/R2: 82.4179 / 88.4452 / 4.1679 / -0.4736.
- Decision: Naive Persistence is the stronger Phase 3 forecasting baseline on the V2 test period.

## Phase 4 Limited Improvement Result

Status: COMPLETE.

Berry selected improvement:

- Phase 2 baseline: MobileNetV2 dropout 0.25.
- Phase 4 experiment: MobileNetV2 dropout 0.35.
- Dataset/split: same `berry_split_v2` sample-level train/validation/test split.
- Final test metrics: accuracy 0.8073, macro F1 0.8068, weighted F1 0.8076.
- Grade 2 precision/recall/F1: 0.7805 / 0.8889 / 0.8312.
- Decision: dropout 0.35 did not improve or worsen the saved headline metrics compared with Phase 2, so the Phase 2 V2 model remains the selected PP2 berry baseline.

Berry Phase 4 artifacts:

- `ml/grading_forecast/berry_grading/models/v2_phase4/berry_mobilenetv2_v2_phase4_best.keras`
- `ml/grading_forecast/berry_grading/models/v2_phase4/berry_classifier_metrics.json`
- `ml/grading_forecast/berry_grading/models/v2_phase4/berry_model_metadata.json`
- `ml/grading_forecast/berry_grading/evaluation/_outputs/v2_phase4/confusion_matrix.png`

Forecasting selected improvement:

- Phase 3 baseline: RandomForest with `lag_1`, `lag_2`, `lag_3`, rolling 3/5, date, and change features.
- Phase 4 experiment: add `lag_4`, `lag_8`, and `lag_12`.
- Dataset/split: same V2 National Grade 1 average weekly target and same 36 chronological V2 test timestamps.
- Phase 4 RF MAE/RMSE/MAPE/R2: 78.1641 / 84.8622 / 3.9482 / -0.3566.
- Decision: extended lags improved over the Phase 3 RF baseline, but did not outperform Naive Persistence.

Forecasting Phase 4 artifacts:

- `ml/grading_forecast/price_forecasting/models/v2_phase4/forecast_model.joblib`
- `ml/grading_forecast/price_forecasting/models/v2_phase4/forecast_metrics.json`
- `ml/grading_forecast/price_forecasting/models/v2_phase4/forecast_model_metadata.json`
- `ml/grading_forecast/price_forecasting/evaluation/_outputs/v2_phase4/actual_vs_predicted.png`
- `ml/grading_forecast/price_forecasting/evaluation/_outputs/v2_phase4/feature_importances.png`
- `ml/grading_forecast/price_forecasting/evaluation/_outputs/v2_phase4/residuals.png`

## Current Blockers

- Current backend runtime does not automatically load PP2 V2 or Phase 4 artifact directories.
- Berry runtime currently uses the legacy/root ONNX model: `ml/grading_forecast/berry_grading/models/berry_mobilenetv2_best.onnx`.
- Forecast runtime currently uses the legacy/root forecast model directory and can return `demo_baseline` because default raw input candidates do not point to the V2 forecasting dataset.
- Firebase was not configured during Phase 5.
- Flutter API integration exists, but end-to-end Flutter validation remains pending.

## Phase 7 Existing Implementation Audit Result

Status: COMPLETE.

Audit findings:

- Berry runtime currently uses the legacy/root ONNX model: `ml/grading_forecast/berry_grading/models/berry_mobilenetv2_best.onnx`.
- Berry V2 research model exists separately: `ml/grading_forecast/berry_grading/models/v2/berry_mobilenetv2_v2_best.onnx`.
- Forecast runtime currently uses the legacy/root forecast model directory and can return `demo_baseline` because default raw input candidates do not point to the V2 forecasting dataset.
- Forecast V2 RandomForest and Phase 4 RandomForest artifacts exist separately under `ml/grading_forecast/price_forecasting/models/v2/` and `ml/grading_forecast/price_forecasting/models/v2_phase4/`.
- Naive Persistence is currently the strongest research forecasting method on the V2 test period.
- Recommendation logic exists and still needs validation using real runtime research outputs.
- Firebase/storage is implemented as optional fail-safe storage and was not configured during Phase 5.
- Flutter API integration exists, but end-to-end validation remains pending.
- Existing error handling and fallback behavior were identified.

Phase 7 changed documentation only. No backend, Flutter, dataset, model artifact, or configuration file was modified.

## Phase 6 Evidence and Documentation Result

Status: COMPLETE.

Completed documentation outputs:

- Final dataset summary table in `docs/research/PP2_RESULTS.md`.
- Final berry experiment table in `docs/research/PP2_RESULTS.md`.
- Final forecast experiment table in `docs/research/PP2_RESULTS.md`.
- Final integration validation table in `docs/research/PP2_RESULTS.md`.
- Evidence map in `docs/research/PP2_RESULTS.md`.
- PP2 speaking points in `docs/research/PP2_RESULTS.md`.
- Final limitations in `docs/research/PP2_LIMITATIONS.md`.
- Phase execution checklist in `docs/research/PP2_EXECUTION_CHECKLIST.md`.

Phase 6 was documentation-only. No model training, evaluation, backend execution, Flutter execution, dataset modification, or artifact regeneration was performed during Phase 6.

## Phase 5 Integration Validation Result

Status: COMPLETE with runtime limitations.

Evidence file:

- `docs/research/PP2_INTEGRATION_VALIDATION.md`

Backend startup:

- FastAPI started successfully on `http://127.0.0.1:8000`.

Validated endpoints:

- `GET /api/v1/grading-forecast/health`: HTTP 200, `status: ok`.
- `GET /api/v1/grading-forecast/price-forecast`: HTTP 200, runtime model `demo_baseline`.
- `POST /api/v1/grading-forecast/grade-only`: HTTP 200 using sample image from `berry_split_v2/test`; response indicated real ONNX grading model use.
- `POST /api/v1/grading-forecast/analyze`: HTTP 200 with grading, forecast, recommendation, and storage fields.

Runtime model/fallback status:

- Berry grading runtime uses legacy/root artifacts: `ml/grading_forecast/berry_grading/models/berry_mobilenetv2_best.onnx` and `class_names.json`.
- Price forecasting runtime returned `demo_baseline`; it did not use the Phase 3 or Phase 4 V2 forecasting research artifacts.
- Storage returned `saved_to_firebase: false` because Firebase was not configured.

Mobile status:

- Flutter grading forecast API service was inspected. It calls the backend analyze and recommend endpoints and defaults to `localhost:8000` or Android emulator `10.0.2.2:8000`.
- Flutter was not run during Phase 5.

## Current Decision Record

- Use V1 MobileNetV2 as historical baseline only.
- Use V2 MobileNetV2 as the primary PP2 berry grading model.
- Phase 4 berry dropout 0.35 did not improve the saved test metrics; keep the Phase 2 V2 MobileNetV2 model as the selected PP2 berry baseline.
- Use National Grade 1 average farm-gate weekly price as the primary forecasting target.
- Use Naive Persistence as the stronger Phase 3 forecasting baseline because it outperformed RandomForest on the V2 test period.
- Keep V2 RandomForest as the required ML baseline and evidence that the simple method generalized better on the current short test window.
- Phase 4 extended-lag RandomForest improved over the Phase 3 RandomForest baseline, but still did not beat Naive Persistence.
- Phase 5 backend API validation is sufficient for PP2 demo path evidence, but the runtime model/fallback behavior must be described separately from the V2 research metrics.
- Do not make ARIMA, SARIMA, XGBoost, Prophet, or LSTM mandatory before PP2.
- Do not fabricate missing Grade 2 price observations.
- Do not manually annotate unavailable camera/background/capture metadata for PP2.

## Next Exact Action

Phase 8: Berry V2 Runtime Integration. After that, continue with forecast runtime integration, recommendation validation, Firebase/storage validation if required, error handling/API hardening, manual cross-component integration, Flutter end-to-end validation, UI/UX improvements, and final integrated validation.
