# Model Training Phase (Phase 3) — Berry Grading + Export Price Forecasting

This document describes the **real model training** work completed for the **Berry Grading and Export Price Forecasting** component of the `multimodal-pepper-ai-decision-support` project.

It focuses on:

1. Berry grading (image classification)
2. Short-horizon export price forecasting (one-step ahead, weekly)

Important: This is a **camera-based visual estimation** system. It **does not** measure moisture, piperine, volatile oil, ash, or bulk density, and it must **not** be presented as official SLS certification.

PP2 evidence update, 2026-08-27:

- Berry V2 MobileNetV2 baseline training, final test evaluation, and ONNX export are complete.
- The V2 berry baseline uses the sample-level split under `data/processed/grading_forecast/berry_split_v2/`.
- V2 model artifacts are stored under `ml/grading_forecast/berry_grading/models/v2/`.
- The old 360-image processed berry dataset and root-level model artifacts are historical V1 artifacts only.
- Price Forecasting V2 training has not started yet.

---

## 1) Model Architectures

### 1.1 Berry grading model (MobileNetV2 transfer learning)

- Task: image classification
- Input: `224x224` RGB image (letterboxed)
- Output classes: `Grade 1`, `Grade 2`, `Grade 3`
- Base model: `MobileNetV2(weights="imagenet", include_top=False)`
- Head: GlobalAveragePooling → Dropout → Dense softmax (3 classes)
- Training: two-stage transfer learning (freeze → fine-tune)
- Goal: **lightweight**, laptop-friendly, mobile-friendly baseline.

### 1.2 Price forecasting model (RandomForestRegressor)

- Task: one-step ahead regression (predict next week price)
- Model: `RandomForestRegressor`
- Goal: **explainable**, stable baseline suitable for academic defense.

---

## 2) Dataset Summary

### 2.1 Berry grading dataset

Current PP2 V2 dataset:

- V2 split directory:
  - `data/processed/grading_forecast/berry_split_v2/`
- Split folders:
  - `train/`, `val/`, `test/`
- V2 manifest:
  - `data/annotations/grading_forecast/berry_grading_labels_v2.csv`
- V2 split manifest:
  - `data/processed/grading_forecast/berry_split_v2_manifest.csv`
- Dataset size:
  - 671 images from 168 physical sample groups
  - Grade 1: 224 images
  - Grade 2: 224 images
  - Grade 3: 223 images
- Leakage-safe split:
  - Train: 117 samples, 467 images
  - Validation: 24 samples, 95 images
  - Test: 27 samples, 109 images
  - No `grade + sample_id` group crosses train, validation, and test.

Historical V1 dataset:

- Processed dataset directory:
  - `data/processed/grading_forecast/berry_images_processed/`
- Class folders:
  - `grade_1/`, `grade_2/`, `grade_3/`
- Dataset size:
  - 360 images total (120 per class)
- Status:
  - Historical only. Do not use this directory for PP2 V2 training.

### 2.2 Forecasting dataset

- Cleaned weekly price dataset:
  - `data/processed/grading_forecast/cleaned_price_data.csv`
- Forecast training series (National + Grade 1 + average):
  - `data/processed/grading_forecast/forecast_training_data.csv`
- Chronological split:
  - `data/processed/grading_forecast/train_forecast_data.csv`
  - `data/processed/grading_forecast/test_forecast_data.csv`

---

## 3) Preprocessing Pipelines

### 3.1 Berry image preprocessing

- Uses letterbox resizing to keep aspect ratio and produce `224x224` RGB.
- Lightweight augmentation only (training-time):
  - random flip
  - small random rotation
  - small random zoom
  - brightness adjustment

### 3.2 Forecasting feature engineering

Features are **past-only** (no leakage) and aligned to predict **next week's** price:

- Lags:
  - `lag_1`, `lag_2`, `lag_3`
- Rolling stats (computed on shifted history):
  - `rolling_mean_3`, `rolling_std_3`
  - `rolling_mean_5`, `rolling_std_5`
- Time features:
  - `month`
  - `week_of_year` (ISO week)
- Change features:
  - `price_change_1w`
  - `price_change_pct_1w`

Target:

- `y = next_week_price`

---

## 4) Training Strategy (Reproducible + Maintainable)

### 4.1 Deterministic reproducibility

All training scripts fix random seeds and attempt deterministic execution:

- `PYTHONHASHSEED`
- Python `random`
- NumPy seed
- TensorFlow seed (`tf.keras.utils.set_random_seed`)
- scikit-learn `random_state`

### 4.2 Berry grading: two-stage transfer learning

Stage 1 (feature extractor):

- Freeze MobileNetV2 backbone
- Train only classification head
- Early stopping + model checkpoint + reduce LR on plateau

Stage 2 (fine-tuning):

- Unfreeze top ~20 MobileNetV2 layers
- Fine-tune with a low learning rate
- Early stopping to prevent overfitting

Class weights:

- Always computed from the training split counts (future-proofing for imbalance).

### 4.3 Forecasting model training

- Preserve chronological ordering (no shuffle)
- Train RandomForestRegressor baseline
- Optionally compare against a LinearRegression baseline (for academic discussion)

---

## 5) Evaluation Metrics

### 5.1 Berry grading evaluation

- Accuracy
- Precision / Recall / F1-score
- Confusion matrix + classification report

Completed PP2 V2 result:

- Test set: `data/processed/grading_forecast/berry_split_v2/test/`
- Test images: 109
- Accuracy: 0.8073
- Macro F1: 0.8068
- Weighted F1: 0.8076
- Grade 2 precision: 0.7805
- Grade 2 recall: 0.8889
- Grade 2 F1: 0.8312
- Confusion matrix:

```text
[[29,  3,  6],
 [ 1, 32,  3],
 [ 2,  6, 27]]
```

Artifacts:

- V2 metrics: `ml/grading_forecast/berry_grading/models/v2/berry_classifier_metrics.json`
- V2 confusion matrix: `ml/grading_forecast/berry_grading/evaluation/_outputs/v2/confusion_matrix.png`
- V2 training curves: `ml/grading_forecast/berry_grading/evaluation/_outputs/v2/training_curves.png`
- V1 historical metrics: `ml/grading_forecast/berry_grading/models/berry_classifier_metrics.json`

### 5.2 Forecasting evaluation

- MAE
- RMSE
- MAPE
- R²

Explainability:

- Random Forest feature importance plot + numeric importances

Artifacts:

- `ml/grading_forecast/price_forecasting/models/forecast_metrics.json`
- Plots under `ml/grading_forecast/price_forecasting/evaluation/_outputs/` (generated locally)

---

## 6) Model Limitations (Must Be Stated)

Berry grading model limitations:

- Camera-based visual estimate only
- Does not measure chemical or lab-based quality indicators
- Not an official certification tool (no SLS certification claims)

Forecasting limitations:

- One-step ahead baseline forecasting (short-horizon)
- Uses only National + Grade 1 + average as the first academically justified baseline

---

## 7) Performance + Deployment Readiness

### 7.1 Inference performance measurements

The berry evaluation script records:

- average and p95 single-image inference latency (after warmup)
- model size on disk
- memory usage estimate (RSS delta)

### 7.2 Backend-friendly exports

- Berry grading is exported to ONNX for backend inference via `onnxruntime`
- Forecasting is exported as `joblib` (scikit-learn model)

Backend requirements:

- Lazy loading + caching to avoid per-request model reload
- Graceful fallback to baseline logic if artifacts are missing

---

## 8) Maintainability + MLOps Practices

### 8.1 Model versioning metadata

Each model stores a metadata JSON (v1 baseline) including:

- model name + version
- trained timestamp (UTC)
- seed / random_state
- image size / class list / feature spec
- dataset paths and split counts/date ranges
- git SHA (best effort)

### 8.2 Clear separation of concerns

- Training scripts are isolated under `ml/.../training/`
- Evaluation scripts under `ml/.../evaluation/`
- Inference scripts under `ml/.../inference/`
- Backend uses inference-only dependencies and avoids TensorFlow runtime.

---

## 9) How To Run (High Level)

Berry grading V2 baseline commands used for PP2:

Train:

```powershell
.\.venv\Scripts\python.exe ml/grading_forecast/berry_grading/training/train_berry_classifier.py --train-dir data/processed/grading_forecast/berry_split_v2/train --val-dir data/processed/grading_forecast/berry_split_v2/val --output-dir ml/grading_forecast/berry_grading/models/v2 --model-filename berry_mobilenetv2_v2_best.keras --metadata-version v2 --batch-size 16 --stage1-epochs 15 --stage2-epochs 5 --stage1-lr 1e-3 --stage2-lr 1e-5 --patience 3
```

Evaluate on the untouched V2 test split:

```powershell
.\.venv\Scripts\python.exe ml/grading_forecast/berry_grading/training/evaluate_berry_classifier.py --model ml/grading_forecast/berry_grading/models/v2/berry_mobilenetv2_v2_best.keras --models-dir ml/grading_forecast/berry_grading/models/v2 --data-dir data/processed/grading_forecast/berry_split_v2/test --output-dir ml/grading_forecast/berry_grading/evaluation/_outputs/v2 --use-full-data-dir --split-name test
```

Export ONNX:

```powershell
.\.venv\Scripts\python.exe ml/grading_forecast/berry_grading/training/export_berry_model.py --model ml/grading_forecast/berry_grading/models/v2/berry_mobilenetv2_v2_best.keras --out ml/grading_forecast/berry_grading/models/v2/berry_mobilenetv2_v2_best.onnx --metadata-out ml/grading_forecast/berry_grading/models/v2/onnx_metadata.json
```

CLI inference with explicit V2 model:

```powershell
.\.venv\Scripts\python.exe ml/grading_forecast/berry_grading/inference/predict_berry_grade.py path\to\test.jpg --model ml/grading_forecast/berry_grading/models/v2/berry_mobilenetv2_v2_best.keras --class-names ml/grading_forecast/berry_grading/models/v2/class_names.json
```

Warning: the no-argument berry training/evaluation/export commands may still target historical V1 defaults. For PP2 V2 evidence, use the explicit V2 paths above.

Forecasting:

- Train: `python ml/grading_forecast/price_forecasting/training/train_forecast_model.py`
- Evaluate: `python ml/grading_forecast/price_forecasting/training/evaluate_forecast_model.py`
- Export manifest: `python ml/grading_forecast/price_forecasting/training/export_forecast_model.py`
- CLI inference: `python ml/grading_forecast/price_forecasting/inference/predict_future_price.py`

---

## 10) Future Improvements

- Collect more images for better generalization across lighting and camera quality.
- Add probability calibration (temperature scaling) for confidence reliability.
- Export and validate TensorFlow Lite model for on-device mobile inference.
- Expand forecasting to district-level and multiple grades once dataset coverage supports it.
