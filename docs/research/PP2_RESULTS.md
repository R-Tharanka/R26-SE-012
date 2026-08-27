# PP2 Results

Last updated: 2026-08-27

This document records PP2 evidence from completed audit, dataset preparation, and baseline experiments. Metrics are included only when backed by saved artifacts.

## Current Result Status

Phase 0 audit result: COMPLETE.

Phase 1 dataset preparation result: COMPLETE.

Phase 2 Berry Grading V2 baseline result: COMPLETE.

No Phase 3 forecasting V2 model has been trained yet. No forecasting V2 metrics should be claimed until the corresponding experiment is executed.

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

Status: COMPLETE.

Source artifacts:

- Model: `ml/grading_forecast/berry_grading/models/v2/berry_mobilenetv2_v2_best.keras`
- ONNX: `ml/grading_forecast/berry_grading/models/v2/berry_mobilenetv2_v2_best.onnx`
- Metrics: `ml/grading_forecast/berry_grading/models/v2/berry_classifier_metrics.json`
- Metadata: `ml/grading_forecast/berry_grading/models/v2/berry_model_metadata.json`
- Training history: `ml/grading_forecast/berry_grading/models/v2/training_history.json`
- Confusion matrix: `ml/grading_forecast/berry_grading/evaluation/_outputs/v2/confusion_matrix.png`
- Training curves: `ml/grading_forecast/berry_grading/evaluation/_outputs/v2/training_curves.png`

V2 training summary:

- Dataset: `berry_v2`.
- Split: sample-level train/validation/test.
- Train: 117 samples, 467 images.
- Validation: 24 samples, 95 images.
- Test: 27 samples, 109 images.
- Training input: `data/processed/grading_forecast/berry_split_v2/train/`.
- Validation input: `data/processed/grading_forecast/berry_split_v2/val/`.
- Test input: `data/processed/grading_forecast/berry_split_v2/test/`.
- Model: MobileNetV2, ImageNet initialization, `include_top=False`.
- Input: 224x224 RGB.
- Optimizer/loss: Adam with sparse categorical cross-entropy.
- Stage 1: frozen backbone, maximum 15 epochs, learning rate 0.001, patience 3; 14 epochs completed.
- Stage 2: limited fine-tuning, maximum 5 epochs, learning rate 0.00001, patience 2; 5 epochs completed.
- Recorded training duration: 1216.447 seconds.
- Evaluation duration: 31.934 seconds.
- ONNX export duration: 10.209 seconds.

V2 final test metrics:

| Metric | Result |
| --- | ---: |
| Accuracy | 0.8073 |
| Macro precision | 0.8122 |
| Macro recall | 0.8078 |
| Macro F1 | 0.8068 |
| Weighted precision | 0.8145 |
| Weighted recall | 0.8073 |
| Weighted F1 | 0.8076 |

Per-class V2 test metrics:

| Class | Precision | Recall | F1 | Support |
| --- | ---: | ---: | ---: | ---: |
| Grade 1 | 0.9063 | 0.7632 | 0.8286 | 38 |
| Grade 2 | 0.7805 | 0.8889 | 0.8312 | 36 |
| Grade 3 | 0.7500 | 0.7714 | 0.7606 | 35 |

Confusion matrix:

```text
[[29,  3,  6],
 [ 1, 32,  3],
 [ 2,  6, 27]]
```

Historical comparison:

| Experiment | Dataset | Split | Accuracy | Macro F1 | Weighted F1 | Grade 2 Recall | Decision |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| V1 MobileNetV2 | berry_v1 | legacy train-val | 0.7778 | 0.7447 | 0.7447 | 0.3333 | Historical baseline |
| V2 MobileNetV2 | berry_v2 | sample-level train-val-test | 0.8073 | 0.8068 | 0.8076 | 0.8889 | Selected PP2 berry baseline |
| V2 limited improvement | berry_v2 | same split | PENDING | PENDING | PENDING | PENDING | Optional |

Interpretation:

The V2 model is the selected PP2 berry grading baseline because it was trained on the expanded V2 dataset, used the leakage-safe sample-level split, and was evaluated once on the untouched V2 test set. The V1 and V2 metrics are useful for historical comparison, but they are not directly equivalent experiments because V1 used the older 360-image dataset and did not include the same sample-level train/validation/test methodology.

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
