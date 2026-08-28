# PP2 Execution Checklist

Last updated: 2026-08-28

Use this checklist phase-by-phase. Do not jump to model training before Phase 1 is complete.

## Global Rules

- [x] Do not modify raw datasets.
- [x] Do not delete V1 artifacts.
- [x] Do not fabricate labels, prices, or metadata.
- [x] Do not report metrics unless the experiment was actually run.
- [x] Do not tune on the test set.
- [x] Keep V1 and V2 outputs clearly separated.
- [x] Update `EXPERIMENT_LOG.md` after each experiment or dataset preparation entry.
- [x] Update `PP2_RESULTS.md` after each completed phase.

## Phase 0: Repository and Research Audit

Status: COMPLETE

- [x] Official project scope reviewed.
- [x] Individual component scope reviewed.
- [x] SLS standard boundary reviewed.
- [x] Existing guides reviewed.
- [x] Previous ChatGPT plans reviewed.
- [x] Codebase inspected.
- [x] Raw berry dataset inspected.
- [x] Raw price dataset inspected.
- [x] Processed V1 artifacts inspected.
- [x] Current PP2 plan created.

## Phase 1: Dataset V2 Preparation and Audit

Status: COMPLETE

- [x] Create V2 berry manifest.
- [x] Include `sample_id` derived from folder path.
- [x] Validate image existence and readability.
- [x] Count images per grade.
- [x] Count samples per grade.
- [x] Record samples with non-4 image counts.
- [x] Record EXIF camera model and orientation if available.
- [x] Create sample-level train/validation/test split.
- [x] Verify no sample appears in multiple splits.
- [x] Create V2 price cleaned dataset.
- [x] Extract National Grade 1 average farm-gate weekly target.
- [x] Analyze missing weeks and temporal gaps.
- [x] Record Grade 2 coverage limitation.
- [x] Update `PROJECT_STATUS.md`.
- [x] Update `PP2_RESULTS.md`.
- [x] Add dataset entries to `EXPERIMENT_LOG.md`.

Phase 1 validation result: PASSED.

## Phase 2: Berry Grading V2 Baseline

Status: COMPLETE

- [x] Confirm V2 sample-level split exists.
- [x] Make training script accept explicit V2 train and validation directories.
- [x] Make training script accept V2 output directory.
- [x] Make evaluator accept explicit V2 model, test data, and output directories.
- [x] Make exporter support explicit V2 Keras, ONNX, and metadata paths.
- [x] Make inference resolve class names beside an explicit model path.
- [x] Run lightweight dry-run validation without training.
- [x] Train MobileNetV2 baseline on V2 train split.
- [x] Use validation split for early stopping/tuning.
- [x] Evaluate on V2 test split.
- [x] Save metrics JSON.
- [x] Save confusion matrix.
- [x] Save training curves.
- [x] Export V2 ONNX model.
- [x] Save V2 ONNX metadata.
- [x] Compare against V1 MobileNetV2 as historical reference.
- [x] Inspect Grade 2 recall.
- [x] Update `EXPERIMENT_LOG.md`.
- [x] Update `PP2_RESULTS.md`.

Phase 2 validation result: PASSED.

Evidence:

- V2 Keras model: `ml/grading_forecast/berry_grading/models/v2/berry_mobilenetv2_v2_best.keras`
- V2 ONNX model: `ml/grading_forecast/berry_grading/models/v2/berry_mobilenetv2_v2_best.onnx`
- V2 metrics: `ml/grading_forecast/berry_grading/models/v2/berry_classifier_metrics.json`
- V2 confusion matrix: `ml/grading_forecast/berry_grading/evaluation/_outputs/v2/confusion_matrix.png`
- V2 test accuracy: 0.8073.
- V2 weighted F1: 0.8076.
- V2 Grade 2 recall: 0.8889.

## Phase 3: Price Forecasting V2 Baseline

Status: COMPLETE

- [x] Confirm V2 National Grade 1 average target exists.
- [x] Confirm chronological split exists.
- [x] Prepare naive persistence baseline implementation.
- [x] Prepare same-test-timestamp naive-vs-RandomForest evaluation.
- [x] Prepare explicit V2 output directories.
- [x] Verify dry-run path resolution without training/evaluation.
- [x] Update docs for Phase 3 pipeline preparation only.
- [x] Execute/evaluate naive persistence baseline.
- [x] Train/evaluate RandomForest.
- [x] Confirm past-only lag/rolling feature logic.
- [x] Save metrics JSON.
- [x] Save actual vs predicted plot.
- [x] Save feature importance plot if available.
- [x] Compare naive vs RandomForest.
- [x] Update `EXPERIMENT_LOG.md`.
- [x] Update `PP2_RESULTS.md`.

Phase 3 pipeline preparation result: PASSED.

Phase 3 experiment execution result: PASSED.

Evidence:

- V2 RF model: `ml/grading_forecast/price_forecasting/models/v2/forecast_model.joblib`
- V2 metrics: `ml/grading_forecast/price_forecasting/models/v2/forecast_metrics.json`
- V2 naive metrics: `ml/grading_forecast/price_forecasting/models/v2/naive_persistence_metrics.json`
- Actual-vs-predicted plot: `ml/grading_forecast/price_forecasting/evaluation/_outputs/v2/actual_vs_predicted.png`
- Feature importance plot: `ml/grading_forecast/price_forecasting/evaluation/_outputs/v2/feature_importances.png`
- Naive Persistence MAE/RMSE/MAPE/R2: 16.4094 / 22.5208 / 0.8539 / 0.9045.
- RandomForest MAE/RMSE/MAPE/R2: 82.4179 / 88.4452 / 4.1679 / -0.4736.
- Decision: Naive Persistence outperformed RandomForest on the V2 test period.

## Phase 4: Limited Model Improvement

Status: COMPLETE

- [x] Confirm Phase 2 baseline is complete.
- [x] Confirm Phase 3 baseline is complete.
- [x] Select one berry improvement only.
- [x] Select one forecast improvement only.
- [x] Run improvement on same splits.
- [x] Compare against baseline.
- [x] Record result even if it does not improve.
- [x] Update `EXPERIMENT_LOG.md`.
- [x] Update `PP2_RESULTS.md`.

Phase 4 validation result: PASSED.

Evidence:

- Berry improvement: MobileNetV2 dropout 0.25 -> 0.35, evaluated on the same 109-image V2 test split.
- Berry Phase 4 accuracy: 0.8073.
- Berry Phase 4 weighted F1: 0.8076.
- Berry Phase 4 Grade 2 precision/recall/F1: 0.7805 / 0.8889 / 0.8312.
- Berry decision: dropout 0.35 did not improve or worsen the saved headline metrics compared with Phase 2.
- Forecast improvement: RandomForest extended with `lag_4`, `lag_8`, and `lag_12`.
- Phase 4 RF MAE/RMSE/MAPE/R2: 78.1641 / 84.8622 / 3.9482 / -0.3566.
- Forecast decision: Phase 4 RF improved over Phase 3 RF, but Naive Persistence remained substantially stronger.

## Phase 5: Integration Validation

Status: COMPLETE

- [x] Start FastAPI backend.
- [x] Validate health endpoint.
- [x] Validate price forecast endpoint.
- [x] Validate grade-only endpoint with image.
- [x] Validate analyze endpoint with image.
- [x] Confirm response includes grading, forecast, recommendation, and storage.
- [x] Confirm whether real model or fallback was used.
- [ ] Optionally validate Flutter flow.
- [x] Save API response examples or screenshots.
- [x] Update `PP2_RESULTS.md`.

Phase 5 validation result: PASSED with runtime limitations.

Evidence:

- Integration evidence file: `docs/research/PP2_INTEGRATION_VALIDATION.md`
- Backend startup: successful on `http://127.0.0.1:8000`.
- Health endpoint: HTTP 200.
- Price forecast endpoint: HTTP 200, runtime model `demo_baseline`.
- Grade-only endpoint: HTTP 200, runtime explanation says real ONNX grading model was used.
- Analyze endpoint: HTTP 200 with grading, forecast, recommendation, and storage fields.
- Storage: Firebase not configured; returned `saved_to_firebase: false`.
- Flutter: inspected only; not run.

## Phase 6: PP2 Evidence and Documentation

Status: COMPLETE

- [x] Finalize dataset summary table.
- [x] Finalize berry experiment table.
- [x] Finalize forecast experiment table.
- [x] Finalize limitations.
- [x] Prepare final PP2 speaking points.
- [x] Confirm all pending metrics are either completed or marked pending.
- [x] Confirm no unsupported claims are included.

Phase 6 validation result: PASSED.

Evidence:

- Final dataset summary table: `docs/research/PP2_RESULTS.md`
- Final berry experiment table: `docs/research/PP2_RESULTS.md`
- Final forecast experiment table: `docs/research/PP2_RESULTS.md`
- Final integration validation table: `docs/research/PP2_RESULTS.md`
- Final limitations: `docs/research/PP2_LIMITATIONS.md`
- PP2 speaking points: `docs/research/PP2_RESULTS.md`
- Evidence map: `docs/research/PP2_RESULTS.md`
- Phase 6 did not run model training, model evaluation, backend execution, Flutter, or dataset modification.

## Four-Day Schedule Tracker

Day 1:

- [x] Finish Phase 1.

Day 2:

- [x] Finish Phase 2 baseline.
- [x] Finish Phase 3 baseline.

Day 3:

- [x] Run Phase 4 if time permits.
- [x] Start Phase 5.

Day 4:

- [x] Finish Phase 5.
- [x] Finish Phase 6.

## Stop Conditions

Stop and reassess if:

- V2 manifest does not match raw files.
- Any sample appears in more than one berry split.
- Price target has duplicated dates after filtering.
- A script would overwrite V1 artifacts without explicit V2 output paths.
- A model result is being reported without saved metrics.
