# PP2 Execution Checklist

Last updated: 2026-08-26

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

Status: NOT STARTED

- [ ] Confirm V2 sample-level split exists.
- [ ] Train MobileNetV2 baseline on V2 train split.
- [ ] Use validation split for early stopping/tuning.
- [ ] Evaluate on V2 test split.
- [ ] Save metrics JSON.
- [ ] Save confusion matrix.
- [ ] Save training curves.
- [ ] Compare against V1 MobileNetV2.
- [ ] Inspect Grade 2 recall.
- [ ] Update `EXPERIMENT_LOG.md`.
- [ ] Update `PP2_RESULTS.md`.

## Phase 3: Price Forecasting V2 Baseline

Status: NOT STARTED

- [ ] Confirm V2 National Grade 1 average target exists.
- [ ] Confirm chronological split exists.
- [ ] Implement/evaluate naive persistence baseline.
- [ ] Train/evaluate RandomForest.
- [ ] Use past-only lag/rolling features.
- [ ] Save metrics JSON.
- [ ] Save actual vs predicted plot.
- [ ] Save feature importance plot if available.
- [ ] Compare naive vs RandomForest.
- [ ] Update `EXPERIMENT_LOG.md`.
- [ ] Update `PP2_RESULTS.md`.

## Phase 4: Limited Model Improvement

Status: NOT STARTED

- [ ] Confirm Phase 2 baseline is complete.
- [ ] Confirm Phase 3 baseline is complete.
- [ ] Select one berry improvement only.
- [ ] Select one forecast improvement only.
- [ ] Run improvement on same splits.
- [ ] Compare against baseline.
- [ ] Record result even if it does not improve.
- [ ] Update `EXPERIMENT_LOG.md`.
- [ ] Update `PP2_RESULTS.md`.

## Phase 5: Integration Validation

Status: NOT STARTED

- [ ] Start FastAPI backend.
- [ ] Validate health endpoint.
- [ ] Validate price forecast endpoint.
- [ ] Validate grade-only endpoint with image.
- [ ] Validate analyze endpoint with image.
- [ ] Confirm response includes grading, forecast, recommendation, and storage.
- [ ] Confirm whether real model or fallback was used.
- [ ] Optionally validate Flutter flow.
- [ ] Save API response examples or screenshots.
- [ ] Update `PP2_RESULTS.md`.

## Phase 6: PP2 Evidence and Documentation

Status: NOT STARTED

- [ ] Finalize dataset summary table.
- [ ] Finalize berry experiment table.
- [ ] Finalize forecast experiment table.
- [ ] Finalize limitations.
- [ ] Prepare final PP2 speaking points.
- [ ] Confirm all pending metrics are either completed or marked pending.
- [ ] Confirm no unsupported claims are included.

## Four-Day Schedule Tracker

Day 1:

- [x] Finish Phase 1.

Day 2:

- [ ] Finish Phase 2 baseline.
- [ ] Finish Phase 3 baseline.

Day 3:

- [ ] Run Phase 4 if time permits.
- [ ] Start Phase 5.

Day 4:

- [ ] Finish Phase 5.
- [ ] Finish Phase 6.

## Stop Conditions

Stop and reassess if:

- V2 manifest does not match raw files.
- Any sample appears in more than one berry split.
- Price target has duplicated dates after filtering.
- A script would overwrite V1 artifacts without explicit V2 output paths.
- A model result is being reported without saved metrics.
