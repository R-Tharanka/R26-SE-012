# Evaluation Metrics and Scores

This document explains the evaluation metrics used in this project, how they are calculated, and where the scores are stored.

## 1) Berry Grading (Classification)

The berry grading model predicts one of three classes: Grade 1, Grade 2, Grade 3. The evaluation script computes standard classification metrics.

### 1.1 Accuracy

- Meaning: Overall percentage of correct predictions.
- Formula:

  Accuracy = (Number of correct predictions) / (Total predictions)

- Useful for: Quick overall performance check.
- Limitation: Can hide class imbalance problems.

### 1.2 Precision, Recall, F1-score

These are computed per class and also as a weighted average.

- Precision (per class):

  Precision = TP / (TP + FP)

  Measures how many predicted positives are actually correct.

- Recall (per class):

  Recall = TP / (TP + FN)

  Measures how many actual positives are correctly detected.

- F1-score (per class):

  F1 = 2 * (Precision * Recall) / (Precision + Recall)

  Balances precision and recall.

- Weighted average:

  Weighted metrics are averaged across classes using class support (number of true samples per class). This is better than a simple average when the dataset is imbalanced.

### 1.3 Confusion Matrix

- Meaning: A table that shows how many samples of each true class were predicted as each class.
- Format (3 classes):

  Rows = actual class, Columns = predicted class

- Useful for: Understanding which grades are commonly confused.

### 1.4 Classification Report

- The classification report contains per-class precision, recall, F1-score, and support (sample count).
- This is useful to explain model behavior in presentations because it gives a full view of class-level performance.

### 1.5 Where the scores are stored

- Metrics JSON:
  - ml/grading_forecast/berry_grading/models/berry_classifier_metrics.json
- Plots:
  - ml/grading_forecast/berry_grading/evaluation/_outputs/confusion_matrix.png
  - ml/grading_forecast/berry_grading/evaluation/_outputs/training_curves.png (if training history is available)


## 2) Price Forecasting (Regression)

The price forecasting model predicts the next week price (LKR/kg). The evaluation script computes regression metrics.

### 2.1 MAE (Mean Absolute Error)

- Meaning: Average absolute difference between actual and predicted values.
- Formula:

  MAE = mean(|y_true - y_pred|)

- Useful for: Interpreting average error in the same unit as price.

### 2.2 RMSE (Root Mean Squared Error)

- Meaning: Penalizes larger errors more than MAE.
- Formula:

  RMSE = sqrt(mean((y_true - y_pred)^2))

- Useful for: Highlighting larger mistakes; good for risk discussion.

### 2.3 MAPE (Mean Absolute Percentage Error)

- Meaning: Average error as a percentage of the actual value.
- Formula:

  MAPE = mean(|y_true - y_pred| / max(|y_true|, 1.0)) * 100

- Useful for: Easy to explain in percentage form.
- Note: A small clamp is used to avoid division by zero.

### 2.4 R-squared (R2)

- Meaning: How much of the variance in the target is explained by the model.
- Formula:

  R2 = 1 - (Sum of squared residuals / Total sum of squares)

- Useful for: Explaining how well the model explains the data trend.

### 2.5 Where the scores are stored

- Metrics JSON:
  - ml/grading_forecast/price_forecasting/models/forecast_metrics.json
- Plots:
  - ml/grading_forecast/price_forecasting/evaluation/_outputs/actual_vs_predicted.png
  - ml/grading_forecast/price_forecasting/evaluation/_outputs/residuals.png
  - ml/grading_forecast/price_forecasting/evaluation/_outputs/feature_importances.png (if available)


## 3) Timing and Performance (Berry Model)

The berry evaluation script also records inference performance:

- Average inference time (ms)
- p95 latency (ms)
- Minimum inference time

These are useful for performance discussion in presentations.


## 4) How to reproduce the metrics

Berry grading:

- Train:
  - python ml/grading_forecast/berry_grading/training/train_berry_classifier.py
- Evaluate:
  - python ml/grading_forecast/berry_grading/training/evaluate_berry_classifier.py

Price forecasting:

- Train:
  - python ml/grading_forecast/price_forecasting/training/train_forecast_model.py
- Evaluate:
  - python ml/grading_forecast/price_forecasting/training/evaluate_forecast_model.py
