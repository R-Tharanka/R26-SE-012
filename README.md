
# Multimodal Pepper AI Decision Support System

An AI-powered mobile-based system for **black pepper crop analysis, quality assessment, and market decision support**.

This project integrates **computer vision, machine learning, and time-series forecasting** to help farmers detect crop issues, evaluate pepper quality, and make informed selling decisions.

---

## 🚀 Features

- 🔍 **Pest Detection**
  - Detect pests on pepper plants using image-based AI models

- 🍃 **Leaf Disease Detection & Severity Analysis**
  - Identify diseases and estimate infection severity

- 🫛 **Berry Disease Detection**
  - Detect diseases affecting pepper berries and provide safe remediation advice

- 📊 **Berry Grading & Quality Scoring**
  - Analyze berry size, color, and texture to determine export quality

- 📈 **Price Forecasting**
  - Predict short-term market prices using historical data

- 💡 **Decision Support**
  - Recommend actions:
    - Sell now
    - Wait for better price
    - Process locally

- 📱 **Mobile Application**
  - Farmers can capture images and receive real-time insights

---

## 🧠 System Architecture

```

Mobile App (Flutter)
↓
FastAPI Backend
↓
AI Models (PyTorch + OpenCV)
↓
Firebase / Cloud Storage

```

The system processes images captured from the field and combines AI predictions with market data to generate actionable insights.

---

## 🏗️ Project Structure

```

multimodal-pepper-ai-decision-support/

├── backend/        # FastAPI backend services
├── mobile/         # Flutter mobile application
├── ml/             # Machine learning models
├── data/           # Datasets (raw, processed)
├── notebooks/      # Experiments & EDA
├── docs/           # Documentation
├── scripts/        # Utility scripts
└── README.md

```

---

## ⚙️ Tech Stack

### 🔹 Backend
- FastAPI
- Python

### 🔹 Machine Learning
- PyTorch
- OpenCV
- Scikit-learn
- Time-series models (ARIMA / LSTM / Prophet)

### 🔹 Mobile
- Flutter

### 🔹 Cloud & Storage
- Firebase

---

## 📊 Workflow

1. Capture image via mobile app  
2. Upload to backend API  
3. Preprocess image (OpenCV)  
4. Run AI models (classification / detection / segmentation)  
5. Compute quality score  
6. Predict market price  
7. Generate recommendation  
8. Return results to mobile app  

---

## 📁 Data Pipeline

- Raw data collection (field visits)
- Image preprocessing & augmentation
- Feature extraction
- Model training & evaluation
- Inference via API

---

## 🧪 Current Status

🚧 Initial development phase  
- [x] Project setup  
- [ ] Backend API development  
- [ ] Mobile UI development  
- [ ] Data collection  
- [ ] Model training  
- [ ] System integration  

---

## 👥 Team

- Member 1 – Pest Detection  
- Member 2 – Leaf Disease Detection  
- Member 3 – Berry Disease Detection  
- Member 4 – Berry Grading & Price Forecasting  

---

## 📌 Future Improvements

- Improve model accuracy with larger datasets  
- Real-time inference optimization  
- Offline mode for mobile app  
- Advanced forecasting models  
- Integration with agricultural advisory systems  

---

## 📄 License

This project is for academic and research purposes.

---

## ⭐ Acknowledgements

- Agricultural experts and pepper farmers  
- Academic supervisor and research guidance  
- Open-source ML and development communities  
