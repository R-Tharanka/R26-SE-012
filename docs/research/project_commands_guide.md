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

### 5.4 Verify real models via API calls

Assuming `uvicorn` is running on `http://127.0.0.1:8000`.

This section includes:

- HTTP method + endpoint path
- Example `curl.exe` calls (PowerShell / Windows)
- Example JSON responses (what to look for)

Health check:

```powershell
curl.exe http://127.0.0.1:8000/api/v1/grading-forecast/health
```

Price forecasting (real model check):

```powershell
curl.exe http://127.0.0.1:8000/api/v1/grading-forecast/price-forecast
```

Verify in the JSON response:

- `forecast.model` is `random_forest_regressor_v1` when these exist:
  - `ml/grading_forecast/price_forecasting/models/forecast_model.joblib`
  - `ml/grading_forecast/price_forecasting/models/forecast_features.json`
- If artifacts are missing (or `GRADING_FORECAST_DISABLE_REAL_MODELS=1`), it will fall back to `moving_average_baseline` or `demo_baseline`.

Berry quality detection model (Berry Grading) endpoints are available under the same component prefix:

- ` /api/v1/grading-forecast/grade-only` (berry grading only)
- ` /api/v1/grading-forecast/analyze` (berry grading + price forecast + recommendation + storage result)

Berry grading only (real ONNX check):

```powershell
curl.exe -X POST -F "image=@path\\to\\test.jpg" http://127.0.0.1:8000/api/v1/grading-forecast/grade-only
```

Verify in the JSON response:

- `grading.explanation` contains: `Real grading model (ONNX) was used for predicted grade.` when these exist:
  - `ml/grading_forecast/berry_grading/models/berry_mobilenetv2_best.onnx`
  - `ml/grading_forecast/berry_grading/models/class_names.json`
- If artifacts are missing (or `GRADING_FORECAST_DISABLE_REAL_MODELS=1`), it will fall back to heuristic grading and mention heuristic mode in the explanation.
- Also verify core outputs are present and valid:
  - `grading.predicted_grade` is one of `Grade 1 | Grade 2 | Grade 3`
  - `grading.quality_score` is `0..100`
  - `grading.confidence` is `0..1`

Implementation note (important for correct ONNX results):

- The exported ONNX graph includes MobileNetV2 preprocessing, so ONNX inference feeds **raw 0..255 float32 RGB** into the model (do not pre-scale to `[-1, 1]`).

Full analyze endpoint (grading + forecast + recommendation):

```powershell
curl.exe -X POST -F "image=@path\\to\\test.jpg" http://127.0.0.1:8000/api/v1/grading-forecast/analyze
```

Verify in the JSON response:

- Berry model:
  - Same checks as `grade-only` for `grading.*`
- Forecast model:
  - `forecast.model` is `random_forest_regressor_v1` when forecast artifacts exist
- End-to-end:
  - Response contains `grading`, `forecast`, `recommendation`, and `storage`

### 5.5 Endpoint reference (HTTP methods + sample JSON)

#### `GET /api/v1/grading-forecast/health`

Purpose: quick service availability check.

Example response:

```json
{
  "status": "ok",
  "component": "berry_grading_export_price_forecasting"
}
```

#### `GET /api/v1/grading-forecast/price-forecast`

Purpose: run **price forecasting** (uses RandomForest if artifacts exist; otherwise falls back).

Example response (real model):

```json
{
  "status": "success",
  "component": "berry_grading_export_price_forecasting",
  "forecast": {
    "model": "random_forest_regressor_v1",
    "current_price_lkr_per_kg": 2027,
    "predicted_price_lkr_per_kg": 2068,
    "trend": "upward",
    "forecast_period": "next_period",
    "metrics": { "mae": null, "rmse": null }
  }
}
```

What to verify:

- `forecast.model == "random_forest_regressor_v1"` indicates the backend loaded `forecast_model.joblib` + `forecast_features.json`.
- `forecast.trend` is one of: `upward | downward | stable`.

#### `POST /api/v1/grading-forecast/grade-only` (multipart upload)

Purpose: run **berry quality grading** only (uses ONNX if exported; otherwise heuristic fallback).

Request (multipart form-data):

```powershell
curl.exe -X POST -F "image=@path\\to\\test.jpg" http://127.0.0.1:8000/api/v1/grading-forecast/grade-only
```

Example response (real model):

```json
{
  "status": "success",
  "component": "berry_grading_export_price_forecasting",
  "grading": {
    "predicted_grade": "Grade 2",
    "quality_score": 70.8,
    "confidence": 0.9,
    "visual_features": {
      "color_uniformity_score": 0.72,
      "dark_berry_ratio": 0.62,
      "light_berry_ratio": 0.18,
      "texture_score": 0.68,
      "defect_ratio": 0.1,
      "cleanliness_score": 0.9
    },
    "supporting_labels": {
      "size_quality": "medium",
      "color_quality": "medium",
      "texture_quality": "medium",
      "broken_level": "low",
      "light_berry_level": "medium",
      "pinhead_level": "medium",
      "foreign_matter_visible": false,
      "mould_visible": false,
      "insect_damage_visible": false
    },
    "explanation": [
      "Real grading model (ONNX) was used for predicted grade."
    ],
    "limitation": "Camera-based visual estimate only. Chemical requirements and bulk density are not measured."
  }
}
```

What to verify:

- `grading.predicted_grade` is one of `Grade 1 | Grade 2 | Grade 3`.
- `grading.explanation` contains `Real grading model (ONNX) was used for predicted grade.` when ONNX artifacts exist.

#### `POST /api/v1/grading-forecast/analyze` (multipart upload)

Purpose: full pipeline (image analysis + grading + forecast + recommendation + storage result).

Request (multipart form-data):

```powershell
curl.exe -X POST -F "image=@path\\to\\test.jpg" http://127.0.0.1:8000/api/v1/grading-forecast/analyze
```

Example response shape (fields abbreviated):

```json
{
  "status": "success",
  "component": "berry_grading_export_price_forecasting",
  "image_analysis": {
    "image_id": "test.jpg",
    "processed": true,
    "note": "Camera-based visual analysis only"
  },
  "grading": { "predicted_grade": "Grade 2", "quality_score": 70.8, "confidence": 0.9 },
  "forecast": { "model": "random_forest_regressor_v1", "trend": "upward" },
  "recommendation": { "decision": "WAIT_SHORTLY", "urgency_level": "LOW" },
  "storage": { "saved_to_firebase": false, "document_id": null }
}
```

What to verify:

- `grading.*` and `forecast.*` indicate real model usage as described above.
- Response includes all of: `grading`, `forecast`, `recommendation`, `storage`.

#### `POST /api/v1/grading-forecast/recommend` (JSON body)

Purpose: request a recommendation directly if you already have `grade` and `trend` (and optionally prices).

Request (JSON):

```powershell
curl.exe -X POST ^
  -H "Content-Type: application/json" ^
  -d "{\"grade\":\"Grade 2\",\"trend\":\"upward\",\"quality_score\":70.8,\"current_price_lkr_per_kg\":2027,\"predicted_price_lkr_per_kg\":2068}" ^
  http://127.0.0.1:8000/api/v1/grading-forecast/recommend
```

Example response shape:

```json
{
  "status": "success",
  "component": "berry_grading_export_price_forecasting",
  "recommendation": {
    "decision": "WAIT_SHORTLY",
    "message": "…",
    "explanation": ["…"],
    "urgency_level": "LOW",
    "suggested_action": "…",
    "limitation_note": "Camera-based visual estimate only. Laboratory tests are required for full official quality certification."
  }
}
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
