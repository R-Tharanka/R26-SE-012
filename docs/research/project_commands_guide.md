# Project Commands Guide (Backend + Phase 2 + Phase 3)

This guide is a **PowerShell-first** reference for running the backend, rebuilding datasets, training real models, and verifying everything works.

---

## Where to run commands

- **Repo root**:
  - `D:\work\Year - 4\pepper\project\multimodal-pepper-ai-decision-support`
- Unless explicitly noted, run commands from **repo root** in **PowerShell**.

---

## 0) One-time PowerShell setup (only if activation is blocked)

Run this in the same PowerShell window you’ll use:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
```

Use this only when `Activate.ps1` is blocked.

---

## 1) Backend environment + run API (FastAPI)

### 1.1 Activate your backend venv

From repo root:

```powershell
.\.venv\Scripts\Activate.ps1
```

Run this whenever you open a new terminal and want to work on backend/testing.

### 1.2 Upgrade pip

```powershell
python -m pip install --upgrade pip
```

Run this once per venv (or when installs act weird).

### 1.3 Install backend requirements

Option A (from repo root):

```powershell
python -m pip install -r backend\requirements.txt
```

Option B (cd into backend):

```powershell
cd backend
python -m pip install -r requirements.txt
cd ..
```

### 1.4 Start the backend server

Option A (recommended, from repo root):

```powershell
python -m uvicorn app.main:app --reload --app-dir backend
```

Option B (cd into backend):

```powershell
cd backend
python -m uvicorn app.main:app --reload
```

### 1.5 (Optional) PYTHONPATH env var

Usually not needed because `pytest.ini` already sets `pythonpath=backend`. If you still want it:

```powershell
$env:PYTHONPATH = "backend"
```

---

## 2) Run backend tests (pytest)

### 2.1 Run all backend tests (recommended)

From repo root:

```powershell
python -m pytest -q
```

### 2.2 Run only backend tests folder

From repo root:

```powershell
python -m pytest -q backend\tests
```

If you want to force `PYTHONPATH` anyway:

```powershell
$env:PYTHONPATH = "backend"
python -m pytest -q backend\tests
```

---

## 3) Phase 2 — (Re)build datasets (only if you need to regenerate inputs)

Run these if you changed raw data or need to recreate processed CSVs/processed images.

### 3.1 Validate berry labels + images

```powershell
python ml\grading_forecast\berry_grading\preprocessing\validate_dataset.py
```

### 3.2 Create processed training images (224×224 letterbox)

```powershell
python ml\grading_forecast\berry_grading\preprocessing\prepare_training_images.py
```

### 3.3 Clean price dataset

```powershell
python ml\grading_forecast\price_forecasting\data\clean_price_data.py
```

### 3.4 Prepare baseline forecast series (National + Grade 1 + average)

```powershell
python ml\grading_forecast\price_forecasting\data\prepare_forecast_training_data.py
```

### 3.5 Create chronological train/test split

```powershell
python ml\grading_forecast\price_forecasting\data\create_forecast_split.py
```

---

## 4) Phase 3 — Real model training (run exactly in this order)

### 4.1 Install training dependencies (in your training venv)

Activate venv first, then:

```powershell
python -m pip install -U pip setuptools wheel
pip install -r ml\grading_forecast\requirements-training.txt
```

### 4.2 Train berry grading model (MobileNetV2)

```powershell
python ml\grading_forecast\berry_grading\training\train_berry_classifier.py
```

Expected outputs in `ml\grading_forecast\berry_grading\models\`:

- `berry_mobilenetv2_best.keras`
- `class_names.json`
- `training_history.json`
- `berry_model_metadata.json`

### 4.3 Evaluate berry model

```powershell
python ml\grading_forecast\berry_grading\training\evaluate_berry_classifier.py
```

Expected:

- `ml\grading_forecast\berry_grading\models\berry_classifier_metrics.json`
- Plots under `ml\grading_forecast\berry_grading\evaluation\_outputs\`

### 4.4 Export berry model to ONNX (backend uses this)

```powershell
python ml\grading_forecast\berry_grading\training\export_berry_model.py
```

Expected:

- `ml\grading_forecast\berry_grading\models\berry_mobilenetv2_best.onnx`
- `ml\grading_forecast\berry_grading\models\onnx_metadata.json`

### 4.5 Test real berry inference (CLI)

```powershell
python ml\grading_forecast\berry_grading\inference\predict_berry_grade.py path\to\test.jpg
```

### 4.6 Train forecast model (RandomForestRegressor)

```powershell
python ml\grading_forecast\price_forecasting\training\train_forecast_model.py
```

Expected outputs in `ml\grading_forecast\price_forecasting\models\`:

- `forecast_model.joblib`
- `forecast_features.json`
- `forecast_metrics.json`
- `forecast_model_metadata.json`

### 4.7 Evaluate forecast model

```powershell
python ml\grading_forecast\price_forecasting\training\evaluate_forecast_model.py
```

Expected:

- Updated `ml\grading_forecast\price_forecasting\models\forecast_metrics.json`
- Plots under `ml\grading_forecast\price_forecasting\evaluation\_outputs\`

### 4.8 Test real forecast inference (CLI)

```powershell
python ml\grading_forecast\price_forecasting\inference\predict_future_price.py
```

---

## 5) Start backend with REAL models (after artifacts exist)

### 5.1 Ensure real models are not disabled

```powershell
Remove-Item Env:GRADING_FORECAST_DISABLE_REAL_MODELS -ErrorAction SilentlyContinue
```

### 5.2 Start server (repo root recommended)

```powershell
python -m uvicorn app.main:app --reload --app-dir backend
```

### 5.3 Confirm backend is using real models

- Berry grading response includes explanation: `Real grading model (ONNX) was used for predicted grade.`
- Forecast response has: `forecast.model == "random_forest_regressor_v1"`

If you ever need to force fallback mode for debugging/tests:

```powershell
$env:GRADING_FORECAST_DISABLE_REAL_MODELS = "1"
```

---

## 6) Git hygiene (do not commit artifacts)

Quick check before committing:

```powershell
git status
```

Do **not** commit:

- `*.keras`
- `*.onnx`
- `*.joblib`
- `*.tflite`
- Anything under `*_outputs\` plot folders

Do commit:

- scripts
- JSON metrics/metadata (small files)
- docs
- configs

