# 🌳 AI Models ↔ Flutter App Linkage Tree

## Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP (Mobile)                            │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTP Requests
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  lib/services/model_service.dart                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ ModelService Class                                                │  │
│  │ • baseUrl: 'http://localhost:8000'                               │  │
│  │ • runScreening() ───────────────────────────────────────────────┐  │  │
│  │ • predictADHDBehavior() ────────────────────────────────────┐ │  │  │
│  │ • predictADHDEye() ───────────────────────────────────────┐ │ │  │  │
│  │ • predictADHDVoice() ───────────────────────────────────┐ │ │ │  │  │
│  │ • predictADHDFacial() ────────────────────────────────┐ │ │ │ │  │  │
│  │ • predictAnxiety() ─────────────────────────────────┐ │ │ │ │ │  │  │
│  │ • predictASDFace() ─────────────────────────────┐ │ │ │ │ │ │  │  │
│  │ • predictASDText() ────────────────────────────┐ │ │ │ │ │ │ │  │  │
│  └────────────────────────────────────────────────┼─┼─┼─┼─┼─┼─┼─┘  │
└────────────────────────────────────────────────────┼─┼─┼─┼─┼─┼─┼───┘
                                                    │ │ │ │ │ │ │
                                                    │ │ │ │ │ │ │ HTTP POST/GET
                                                    │ │ │ │ │ │ │
                                                    ▼ ▼ ▼ ▼ ▼ ▼ ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    BACKEND API (Python FastAPI)                         │
│                    backend/main.py                                      │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ FastAPI Endpoints:                                                │  │
│  │                                                                    │  │
│  │ POST /run-screening ───────────────────────────────────────────┐ │  │
│  │   │ • Receives: ranked_conditions, available_modalities        │ │  │
│  │   │ • Receives: video_file, audio_file, questionnaire_data    │ │  │
│  │   │ • Calls: model_router.execute_screening()                 │ │  │
│  │   └───────────────────────────────────────────────────────────┼─┘  │
│  │                                                                 │    │
│  │ POST /predict/adhd/behavior ────────────────────────────────┐│    │
│  │   │ • Receives: features (Dict)                               ││    │
│  │   │ • Calls: model_router.predict_adhd_behavior()            ││    │
│  │   └───────────────────────────────────────────────────────────┼┘    │
│  │                                                                │     │
│  │ POST /predict/adhd/eye ─────────────────────────────────────┐│     │
│  │   │ • Receives: features (Dict)                             ││     │
│  │   │ • Calls: model_router.predict_adhd_eye()                ││     │
│  │   └──────────────────────────────────────────────────────────┼┘     │
│  │                                                               │      │
│  │ POST /predict/adhd/voice ──────────────────────────────────┐│      │
│  │   │ • Receives: audio_file (UploadFile)                     ││      │
│  │   │ • Calls: model_router.predict_adhd_voice()             ││      │
│  │   └──────────────────────────────────────────────────────────┼┘      │
│  │                                                              │       │
│  │ POST /predict/adhd/facial ─────────────────────────────────┐│       │
│  │   │ • Receives: video_file (UploadFile)                    ││       │
│  │   │ • Calls: model_router.predict_adhd_facial()           ││       │
│  │   └──────────────────────────────────────────────────────────┼┘       │
│  │                                                             │        │
│  │ POST /predict/anxiety ────────────────────────────────────┐│        │
│  │   │ • Receives: features (Dict)                           ││        │
│  │   │ • Calls: model_router.predict_anxiety()              ││        │
│  │   └────────────────────────────────────────────────────────┼┘        │
│  │                                                            │         │
│  │ POST /predict/asd/face ─────────────────────────────────┐│         │
│  │   │ • Receives: video_file (UploadFile)                  ││         │
│  │   │ • Calls: model_router.predict_asd_face()             ││         │
│  │   └────────────────────────────────────────────────────────┼┘         │
│  │                                                           │          │
│  │ POST /predict/asd/text ─────────────────────────────────┐│          │
│  │   │ • Receives: aq10_scores (List[int])                 ││          │
│  │   │ • Calls: model_router.predict_asd_text()           ││          │
│  │   └───────────────────────────────────────────────────────┼┘          │
│  │                                                          │           │
│  │ POST /extract-features ────────────────────────────────┐│           │
│  │   │ • Receives: modality, video_file, audio_file       ││           │
│  │   │ • Calls: feature_extractor.extract_*()             ││           │
│  │   └──────────────────────────────────────────────────────┼┘           │
│  └──────────────────────────────────────────────────────────┼────────────┘
└─────────────────────────────────────────────────────────────┼────────────┘
                                                              │
                                                              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              MODEL ROUTER (Decision Engine)                           │
│              backend/services/model_router.py                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ ModelRouter Class                                                 │  │
│  │                                                                    │  │
│  │ execute_screening() ────────────────────────────────────────────┐ │  │
│  │   │ • Loops through ranked_conditions                           │ │  │
│  │   │ • Checks available_modalities                               │ │  │
│  │   │ • Routes to appropriate model based on condition           │ │  │
│  │   │ • Returns first result above threshold                      │ │  │
│  │   └────────────────────────────────────────────────────────────┼─┘  │
│  │                                                                  │    │
│  │ predict_adhd_behavior() ─────────────────────────────────────┐ │    │
│  │   │ • Loads: ADHD_BEHAVIOR_MODEL (CatBoost)                  │ │    │
│  │   │ • Loads: ADHD_BEHAVIOR_FEATURES (feature names)          │ │    │
│  │   │ • Builds feature vector from questionnaire_data          │ │    │
│  │   │ • Predicts: probability + binary result                  │ │    │
│  │   └───────────────────────────────────────────────────────────┼─┘    │
│  │                                                                │     │
│  │ predict_adhd_eye() ──────────────────────────────────────────┐│     │
│  │   │ • Loads: ADHD_EYE_MODEL                                  ││     │
│  │   │ • Extracts eye features from video                       ││     │
│  │   │ • Predicts: probability + binary result                  ││     │
│  │   └───────────────────────────────────────────────────────────┼┘     │
│  │                                                               │      │
│  │ predict_adhd_voice() ───────────────────────────────────────┐│      │
│  │   │ • Extracts audio features (MFCC, Chroma, Contrast)      ││      │
│  │   │ • Loads: ADHD_VOICE_CNN + ADHD_VOICE_SVM + SCALER       ││      │
│  │   │ • Ensemble prediction (CNN + SVM average)              ││      │
│  │   └───────────────────────────────────────────────────────────┼┘      │
│  │                                                              │       │
│  │ predict_adhd_facial() ─────────────────────────────────────┐│       │
│  │   │ • Extracts face frames from video                       ││       │
│  │   │ • Loads: ADHD_FACIAL_MODEL (ResNet50 Keras)            ││       │
│  │   │ • Predicts: emotion probabilities → ADHD probability   ││       │
│  │   └──────────────────────────────────────────────────────────┼┘       │
│  │                                                             │        │
│  │ predict_anxiety() ────────────────────────────────────────┐│        │
│  │   │ • Loads: ANXIETY_MODEL (RandomForest)                  ││        │
│  │   │ • Builds feature vector from questionnaire_data       ││        │
│  │   │ • Predicts: probability + binary result               ││        │
│  │   └─────────────────────────────────────────────────────────┼┘        │
│  │                                                            │         │
│  │ predict_asd_face() ───────────────────────────────────────┐│         │
│  │   │ • Extracts face frames from video                      ││         │
│  │   │ • Loads: ASD_FACE_MODEL (VGG19 H5)                    ││         │
│  │   │ • Loads: ASD_FACE_CLASSES (class_indices.json)        ││         │
│  │   │ • Predicts: autistic/non_autistic + probability       ││         │
│  │   └────────────────────────────────────────────────────────┼┘         │
│  │                                                           │          │
│  │ predict_asd_text() ──────────────────────────────────────┐│          │
│  │   │ • Loads: ASD_TEXT_ADABOOST + XGBOOST + RANDOMFOREST  ││          │
│  │   │ • Input: AQ-10 scores (10 integers)                  ││          │
│  │   │ • Ensemble prediction (average of 3 models)         ││          │
│  │   └───────────────────────────────────────────────────────┼┘          │
│  └────────────────────────────────────────────────────────────┼───────────┘
└───────────────────────────────────────────────────────────────┼───────────┘
                                                                │
                                                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              MODEL LOADER (Singleton Cache)                             │
│              backend/services/model_loader.py                           │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ ModelLoader Class                                                 │  │
│  │ • _models: {} (cache dictionary)                                  │  │
│  │                                                                    │  │
│  │ load_model(model_path, model_type)                                │  │
│  │   │ • Checks cache first                                          │  │
│  │   │ • Loads from disk if not cached                               │  │
│  │   │ • Caches loaded model                                         │  │
│  │   │ • Supports: joblib, keras, h5                                 │  │
│  │   └───────────────────────────────────────────────────────────────┘  │
│  └──────────────────────────────────────────────────────────────────────┘
└──────────────────────────────────────────────────────────────────────────┘
                                                                │
                                                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              FEATURE EXTRACTOR                                         │
│              backend/services/feature_extractor.py                     │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ FeatureExtractor Class                                            │  │
│  │                                                                    │  │
│  │ extract_from_video() ───────────────────────────────────────────┐ │  │
│  │   │ • Extracts frames (OpenCV)                                   │ │  │
│  │   │ • Extracts audio from video (librosa)                        │ │  │
│  │   │ • Extracts face features                                     │ │  │
│  │   │ • Extracts eye features (placeholder)                        │ │  │
│  │   └──────────────────────────────────────────────────────────────┼─┘  │
│  │                                                                   │    │
│  │ extract_from_audio() ──────────────────────────────────────────┐│    │
│  │   │ • Extracts: MFCC (40), Chroma (12), Contrast (7)           ││    │
│  │   │ • Returns: combined feature vector (59 dims)                ││    │
│  │   └──────────────────────────────────────────────────────────────┼┘    │
│  │                                                                  │     │
│  │ extract_face_features() ───────────────────────────────────────┐│     │
│  │   │ • Uses Haar Cascade (OpenCV)                               ││     │
│  │   │ • Detects faces in frames                                   ││     │
│  │   │ • Resizes to 224x224 for models                            ││     │
│  │   └──────────────────────────────────────────────────────────────┼┘     │
│  │                                                                 │      │
│  │ extract_eye_features() ──────────────────────────────────────┐│      │
│  │   │ • Placeholder implementation                               ││      │
│  │   │ • Returns synthetic features                               ││      │
│  │   └──────────────────────────────────────────────────────────────┼┘      │
│  │                                                                │       │
│  │ extract_text_features() ─────────────────────────────────────┐│       │
│  │   │ • Processes questionnaire responses                       ││       │
│  │   │ • Returns processed text data                            ││       │
│  │   └───────────────────────────────────────────────────────────┼┘       │
│  └────────────────────────────────────────────────────────────────┼───────┘
└────────────────────────────────────────────────────────────────────┼───────┘
                                                                      │
                                                                      ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              MODEL CONFIGURATION                                        │
│              backend/config/model_config.py                             │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ ModelConfig Class                                                 │  │
│  │ • Defines all model file paths                                    │  │
│  │ • Defines confidence thresholds                                   │  │
│  │ • Defines required modalities                                     │  │
│  │                                                                    │  │
│  │ Model Paths:                                                      │  │
│  │   ADHD_BEHAVIOR_MODEL = "Graduation Project/ADHD/.../adhd_behavior_catboost.pkl"│
│  │   ADHD_EYE_MODEL = "Graduation Project/ADHD/.../adhd_eye_best_model.pkl"│
│  │   ADHD_VOICE_CNN = "Graduation Project/ADHD/.../voice_cnn_model.h5"│
│  │   ADHD_VOICE_SVM = "Graduation Project/ADHD/.../voice_svm_model.pkl"│
│  │   ADHD_FACIAL_MODEL = "Graduation Project/ADHD/.../young_affectnet_...keras"│
│  │   ANXIETY_MODEL = "Graduation Project/anxitey/anxiety_detection_model.pkl"│
│  │   ASD_FACE_MODEL = "Graduation Project/asd/models/ASD/face/asd_vgg19.h5"│
│  │   ASD_TEXT_ADABOOST = "Graduation Project/asd/models/ASD/text/adaboost_model.joblib"│
│  │   ASD_TEXT_XGBOOST = "Graduation Project/asd/models/ASD/text/xgboost_model.joblib"│
│  │   ASD_TEXT_RANDOMFOREST = "Graduation Project/asd/models/ASD/text/random_forest_model.joblib"│
│  └──────────────────────────────────────────────────────────────────────┘
└──────────────────────────────────────────────────────────────────────────┘
                                                                      │
                                                                      ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    ACTUAL MODEL FILES (Disk)                            │
│                    Graduation Project/                                  │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                                                                   │  │
│  │ ADHD/                                                             │  │
│  │ └── ADHD_final/                                                  │  │
│  │     └── ADHD_Models/                                             │  │
│  │         ├── adhd_behavior_catboost.pkl ────────────────┐         │  │
│  │         ├── adhd_behavior_feature_names.pkl ──────────┤         │  │
│  │         ├── adhd_eye_best_model.pkl ───────────────────┤         │  │
│  │         ├── voice_cnn_model.h5 ────────────────────────┤         │  │
│  │         ├── voice_svm_model.pkl ───────────────────────┤         │  │
│  │         ├── voice_scaler.pkl ──────────────────────────┤         │  │
│  │         └── young_affectnet_best_emotion_model_ResNet50.keras ──┤ │  │
│  │                                                                   │  │
│  │ anxitey/                                                          │  │
│  │ └── anxiety_detection_model.pkl ────────────────────────────────┤ │  │
│  │                                                                   │  │
│  │ asd/                                                              │  │
│  │ └── models/                                                       │  │
│  │     └── ASD/                                                      │  │
│  │         ├── face/                                                 │  │
│  │         │   ├── asd_vgg19.h5 ───────────────────────────────────┤ │  │
│  │         │   └── class_indices.json ─────────────────────────────┤ │  │
│  │         └── text/                                                │  │
│  │             ├── adaboost_model.joblib ──────────────────────────┤ │  │
│  │             ├── xgboost_model.joblib ──────────────────────────┤ │  │
│  │             └── random_forest_model.joblib ────────────────────┤ │  │
│  │                                                                   │  │
│  └───────────────────────────────────────────────────────────────────┼─┘
└───────────────────────────────────────────────────────────────────────┼─┘
                                                                        │
                                                                        │
                                                                        │
                    ┌───────────────────────────────────────────────────┘
                    │
                    │ Model Predictions Flow Back
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    RESPONSE FLOW (Back to Flutter)                     │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ JSON Response Format:                                             │  │
│  │ {                                                                 │  │
│  │   "success": true,                                                │  │
│  │   "result": {                                                     │  │
│  │     "detected_condition": "ADHD",                                │  │
│  │     "confidence": 0.72,                                           │  │
│  │     "model_type": "behavior",                                     │  │
│  │     "all_results": [...],                                         │  │
│  │     "message": "Strong indicators detected for ADHD"              │  │
│  │   }                                                               │  │
│  │ }                                                                 │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                    │
                    │ HTTP Response
                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              FLUTTER APP (Receives Results)                             │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ lib/screens/screening_chat_screen.dart                             │  │
│  │ • Receives result from model_service.runScreening()              │  │
│  │ • Displays messages in chat UI                                    │  │
│  │ • Navigates to ResultsScreen if condition detected                │  │
│  │                                                                    │  │
│  │ lib/results_screen.dart                                            │  │
│  │ • Displays detected condition                                     │  │
│  │ • Shows confidence level                                          │  │
│  │ • Shows disclaimer                                                 │  │
│  │ • Shows detailed results                                          │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔗 Key Linkage Points

### 1. **Flutter → Backend API**
- **File**: `lib/services/model_service.dart`
- **Connection**: HTTP POST/GET requests to `http://localhost:8000`
- **Data Format**: JSON + MultipartFormData (for files)

### 2. **Backend API → Model Router**
- **File**: `backend/main.py` → `backend/services/model_router.py`
- **Connection**: Python function calls
- **Purpose**: Routes requests to appropriate models

### 3. **Model Router → Model Loader**
- **File**: `backend/services/model_router.py` → `backend/services/model_loader.py`
- **Connection**: Python function calls
- **Purpose**: Loads models from disk (with caching)

### 4. **Model Router → Feature Extractor**
- **File**: `backend/services/model_router.py` → `backend/services/feature_extractor.py`
- **Connection**: Python function calls
- **Purpose**: Extracts features from raw data (video/audio/text)

### 5. **Model Loader → Model Files**
- **File**: `backend/services/model_loader.py` → `Graduation Project/*/`
- **Connection**: File system reads
- **Purpose**: Loads actual ML model files (.pkl, .h5, .keras, .joblib)

### 6. **Model Config → All Components**
- **File**: `backend/config/model_config.py`
- **Connection**: Imported by ModelRouter, ModelLoader
- **Purpose**: Provides model paths, thresholds, required modalities

---

## 📊 Data Flow Summary

```
User Input (Video/Audio/Questionnaire)
    │
    ▼
Flutter App (screening_chat_screen.dart)
    │ HTTP POST
    ▼
Backend API (/run-screening)
    │ Function Call
    ▼
Model Router (execute_screening)
    │ Function Call
    ├──► Feature Extractor (extract features)
    │    │
    │    └──► OpenCV, librosa, etc.
    │
    └──► Model Loader (load model)
         │
         └──► Model Config (get path)
              │
              └──► Model File (disk)
                   │
                   └──► TensorFlow/Keras/CatBoost/etc.
                        │
                        └──► Prediction Result
                             │
                             ▼
                    JSON Response
                             │
                             ▼
                    Flutter App (display results)
```

---

## 🎯 Critical Files for Linkage

1. **`lib/services/model_service.dart`** - Flutter API client
2. **`backend/main.py`** - API endpoints
3. **`backend/services/model_router.py`** - Model routing logic
4. **`backend/services/model_loader.py`** - Model loading
5. **`backend/services/feature_extractor.py`** - Feature extraction
6. **`backend/config/model_config.py`** - Model configuration
7. **`Graduation Project/*/`** - Actual model files

---

This tree shows the complete linkage from Flutter app → Backend API → Models → Results → Back to Flutter.

