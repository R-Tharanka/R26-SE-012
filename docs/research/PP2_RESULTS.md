# PP2 Results

Last updated: 2026-08-27

This document is reserved for PP2 evidence. It currently contains audit results and placeholders for V2 experiments that have not been run yet.

## Current Result Status

Phase 0 audit result: COMPLETE.

Phase 1 dataset preparation result: COMPLETE.

Berry V2 pre-training pipeline preparation: COMPLETE.

No V2 model has been trained yet. No V2 metrics should be claimed until the corresponding experiment is executed.

## Dataset Evidence From Audit

### Berry Dataset

Raw dataset path: `data/raw/berry_images/`

| Item | Audit Result |
| --- | --- |
| Total raw image files | 671 |
| Grade 1 images | 224 |
| Grade 2 images | 224 |
| Grade 3 images | 223 |
| Sample folders per grade | 56 |
| Root-level images | 0 |
| Unreadable images | 0 |
| Duplicate content groups | 0 |
| Main image dimensions | 4000x3000 and 4080x3060 |
| EXIF camera models | SM-A127F, Galaxy A06 |
| Known issue | Some samples have 3 or 5 images instead of 4 |

Interpretation:

The berry dataset is suitable for a meaningful PP2 classification experiment if it is split at physical-sample level. The current folder structure supports deriving `grade` and `sample_id` automatically. Manual annotation of unavailable metadata is not required for PP2.

## Phase 1 Dataset Preparation Results

### Berry V2 Manifest and Audit

Artifacts:

- `data/annotations/grading_forecast/berry_grading_labels_v2.csv`
- `data/processed/grading_forecast/berry_dataset_v2_summary.json`

| Item | V2 Result |
| --- | ---: |
| Manifest rows | 671 |
| Readable images | 671 |
| Unreadable images | 0 |
| Missing files | 0 |
| Duplicate image paths | 0 |
| Duplicate image-content groups | 0 |
| Total physical sample groups | 168 |
| Samples per grade | 56 |

Images per grade:

| Grade | Images |
| --- | ---: |
| Grade 1 | 224 |
| Grade 2 | 224 |
| Grade 3 | 223 |

Non-4-image samples:

| Grade | Sample | Image Count |
| --- | --- | ---: |
| Grade 1 | sample_028 | 3 |
| Grade 1 | sample_030 | 3 |
| Grade 3 | sample_010 | 3 |
| Grade 1 | sample_002 | 5 |
| Grade 1 | sample_018 | 5 |

### Berry V2 Sample-Level Split

Artifacts:

- `data/processed/grading_forecast/berry_split_v2/`
- `data/processed/grading_forecast/berry_split_v2_manifest.csv`

Split seed: 42.

| Split | Samples | Images |
| --- | ---: | ---: |
| Train | 117 | 467 |
| Validation | 24 | 95 |
| Test | 27 | 109 |

Sample counts by grade:

| Split | Grade 1 | Grade 2 | Grade 3 |
| --- | ---: | ---: | ---: |
| Train | 39 | 39 | 39 |
| Validation | 8 | 8 | 8 |
| Test | 9 | 9 | 9 |

Image counts by grade:

| Split | Grade 1 | Grade 2 | Grade 3 |
| --- | ---: | ---: | ---: |
| Train | 155 | 156 | 156 |
| Validation | 31 | 32 | 32 |
| Test | 38 | 36 | 35 |

Leakage validation:

- Every V2 image appears exactly once in the split manifest.
- Every split contains Grade 1, Grade 2, and Grade 3.
- No `grade + sample_id` group appears in more than one split.
- The split is sample-level, not image-level.

### Price Dataset

Raw dataset path: `data/raw/market_prices/dea_farmgate_weekly_prices_2016_2026.csv`

| Item | Audit Result |
| --- | --- |
| Total rows | 7,742 |
| Date range | 2021-02-22 to 2026-08-18 |
| Main practical coverage | early January 2022 to 2026-08-18 |
| Commodity | black_pepper |
| Country | Sri Lanka |
| Market level | farm_gate |
| Frequency | weekly |
| Price types | highest, average |
| Grades | Grade 1, Grade 2 |
| Grade 1 rows | 6,930 |
| Grade 2 rows | 812 |
| Duplicate date/district/grade/price_type rows | 0 |

Primary forecasting target:

`National + Grade 1 + average + farm_gate + weekly`

Reason:

This target is the most defensible PP2 forecasting series because it has stronger historical coverage than Grade 2 and avoids fabricating sparse observations.

### Price V2 Cleaned Dataset and Target

Artifacts:

- `data/processed/grading_forecast/price_v2/cleaned_price_data_v2.csv`
- `data/processed/grading_forecast/price_v2/national_grade1_average_weekly.csv`
- `data/processed/grading_forecast/price_v2/price_v2_coverage_summary.json`

| Item | V2 Result |
| --- | ---: |
| Raw rows | 7,742 |
| Cleaned rows | 7,742 |
| Target observations | 232 |
| Duplicate target dates | 0 |
| Target missing prices | 0 |
| Target gaps greater than 8 days | 12 |
| Largest target gap | 316 days |

Target date range:

- Minimum date: 2021-02-22.
- Maximum date: 2026-08-18.
- Largest gap: 2021-02-22 to 2022-01-04.

Observed target interval distribution in days:

| Interval Days | Count |
| ---: | ---: |
| 2 | 1 |
| 5 | 1 |
| 6 | 14 |
| 7 | 189 |
| 8 | 14 |
| 13 | 1 |
| 14 | 9 |
| 22 | 1 |
| 316 | 1 |

### Price V2 Chronological Split

Artifacts:

- `data/processed/grading_forecast/price_v2/forecast_train.csv`
- `data/processed/grading_forecast/price_v2/forecast_validation.csv`
- `data/processed/grading_forecast/price_v2/forecast_test.csv`

| Split | Rows | Date Range |
| --- | ---: | --- |
| Train | 162 | 2021-02-22 to 2025-03-18 |
| Validation | 34 | 2025-03-25 to 2025-11-25 |
| Test | 36 | 2025-12-02 to 2026-08-18 |

Grade 2 coverage:

- All observed Grade 2 rows: 812.
- National Grade 2 average observations: 161.
- Grade 2 observed dates by year: 2022: 6, 2023: 27, 2024: 49, 2025: 49, 2026: 30.
- Grade 2 remains out of scope for the primary PP2 forecasting target.

## Historical V1 Results

### Berry V1 MobileNetV2

Source: `ml/grading_forecast/berry_grading/models/berry_classifier_metrics.json`

| Metric | Result |
| --- | --- |
| Accuracy | 0.7778 |
| Weighted precision | 0.8516 |
| Weighted recall | 0.7778 |
| Weighted F1 | 0.7447 |
| Grade 1 recall | 1.0000 |
| Grade 2 recall | 0.3333 |
| Grade 3 recall | 1.0000 |

Interpretation:

This is a useful historical baseline, but it is not final PP2 evidence because it used the old 360-image dataset and did not include a proper sample-level train/validation/test split.

### Forecast V1 RandomForest

Source: `ml/grading_forecast/price_forecasting/models/forecast_metrics.json`

| Metric | Train | Test |
| --- | ---: | ---: |
| MAE | 15.7114 | 45.8347 |
| RMSE | 24.3440 | 47.7556 |
| MAPE | 0.9527 | 2.2911 |
| R2 | 0.9841 | -6.1315 |

Interpretation:

The V1 RandomForest model showed overfitting or poor future generalization. This motivates a cleaner V2 comparison against naive persistence.

## V2 Berry Results

Status: READY TO TRAIN.

Pipeline readiness:

- Training can now explicitly use `berry_split_v2/train` and `berry_split_v2/val`.
- Evaluation can now explicitly use the untouched `berry_split_v2/test`.
- V2 artifacts resolve to `ml/grading_forecast/berry_grading/models/v2/`.
- V2 plots resolve to `ml/grading_forecast/berry_grading/evaluation/_outputs/v2/`.
- Dry-run validation passed; no V2 model has been trained.

Planned table:

| Experiment | Dataset | Split | Accuracy | Macro F1 | Weighted F1 | Grade 2 Recall | Decision |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| V1 MobileNetV2 | berry_v1 | legacy train-val | 0.7778 | 0.7447 | 0.7447 | 0.3333 | Historical baseline |
| V2 MobileNetV2 | berry_v2 | sample-level train-val-test | PENDING | PENDING | PENDING | PENDING | PENDING |
| V2 limited improvement | berry_v2 | same split | PENDING | PENDING | PENDING | PENDING | Optional |

## V2 Forecast Results

Status: NOT STARTED.

Planned table:

| Experiment | Target | Split | MAE | RMSE | MAPE | R2 | Decision |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| Naive persistence | National Grade 1 average | chronological test | PENDING | PENDING | PENDING | PENDING | Required baseline |
| RandomForest | National Grade 1 average | chronological test | PENDING | PENDING | PENDING | PENDING | Primary PP2 ML model |
| Limited improvement | National Grade 1 average | same test | PENDING | PENDING | PENDING | PENDING | Optional |

## Integration Evidence

Status: NOT STARTED.

Existing API endpoints to validate:

- `GET /api/v1/grading-forecast/health`
- `POST /api/v1/grading-forecast/grade-only`
- `GET /api/v1/grading-forecast/price-forecast`
- `POST /api/v1/grading-forecast/analyze`
- `POST /api/v1/grading-forecast/recommend`

Expected PP2 evidence:

- backend health response;
- one grade-only response;
- one full analyze response;
- note showing whether real model or fallback was used;
- optional Flutter screenshots.

## PP2 Result Narrative

Recommended narrative:

The V1 implementation established a working end-to-end baseline. After PP1, the datasets were expanded substantially. The PP2 work corrects the methodology by creating V2 datasets, preventing berry sample leakage, selecting a defensible price forecasting target, comparing against simple baselines, and validating integration with the shared mobile/backend architecture.
