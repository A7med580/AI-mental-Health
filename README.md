# 🧠 Mindful: AI Mental Health Companion

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)](https://www.python.org)
[![TensorFlow](https://img.shields.io/badge/TensorFlow-%23FF6F00.svg?style=for-the-badge&logo=TensorFlow&logoColor=white)](https://www.tensorflow.org)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)

**Mindful** is a cutting-edge, multimodal AI-driven system designed for early screening of mental health conditions like **ADHD** and **Autism (ASD)**. By leveraging Computer Vision, Voice Stress Analysis, and NLP, Mindful provides objective biomarkers to supplement traditional clinical assessments.

---

## 🚀 Key Features

*   **⚡ Real-time ADHD Screening**: Multi-modal fusion of behavioral data, eye gaze heuristics, and voice prosody.
*   **🧩 ASD Detection**: Advanced facial emotion recognition coupled with standardized AQ-10 diagnostics.
*   **🎙️ Voice Stress Analysis**: MFCC-based emotion and impulsivity detection from audio recordings.
*   **👁️ Gaze Tracking**: Heuristic-based eye movement analysis for behavioral biomarker extraction.
*   **🔔 Smart Notifications**: Asynchronous background processing with in-app result alerts.

---

## 🏗️ System Architecture

Mindful follows a modern client-server architecture designed for heavy AI processing without compromising mobile user experience.

### High-Level Data Flow

```mermaid
sequenceDiagram
    participant User
    participant App as Flutter Mobile App
    participant API as FastAPI Backend
    participant Models as AI Fusion Engine
    participant DB as Supabase

    User->>App: Record Interview/Media
    App->>DB: Store Metadata & Auth
    App->>API: Submit Job (UUID)
    API-->>App: Job Queued Ack
    Note over API,Models: Async Processing Starts
    API->>Models: Extract Features (MFCC, Gaze, Face)
    Models-->>API: Fused Probabilities
    API->>DB: Save Final Result
    App->>API: Poll Status / Notification
    API-->>App: Screening Ready
    App->>User: Display Result Dashboard
```

### AI Fusion Strategy (ADHD)

```mermaid
graph TD
    subgraph "Input Modalities"
        V[Video Feed]
        A[Audio Stream]
        T[Textual Answers]
    end

    V --> FD[Face Detection]
    V --> GT[Gaze Tracking]
    A --> VSA[Voice Stress Analysis]
    T --> NLP[Sentiment/Behavioral NLP]

    FD --> FM[Facial Model - CNN]
    GT --> EM[Eye Model - RF]
    VSA --> VM[Voice Model - SVM/CNN]
    NLP --> BM[Behavioral Model - CatBoost]

    subgraph "Late Fusion Engine"
        FM & EM & VM & BM --> LF[Weighted Probability Averaging]
    end

    LF --> Result[Final ADHD Probability]
```

---

## 🛠️ Technology Stack

| Layer | Technologies |
| :--- | :--- |
| **Frontend** | Flutter, Riverpod, Supabase Auth, Camera/Video Player |
| **Backend** | FastAPI (Async), Uvicorn, BackgroundTasks |
| **AI/ML** | TensorFlow/Keras, Scikit-learn, MediaPipe, Librosa, OpenCV |
| **Storage** | Supabase (User Data), Local Persistent OS Storage (Media) |

---

## 📂 Project Structure

```text
.
├── backend/                # FastAPI Python Server
│   ├── Models/             # Serialized AI Models (.h5, .pkl)
│   ├── services/           # AI Logic & Feature Extractors
│   │   ├── model_router.py # Request routing
│   │   └── adhd_fusion.py  # Multi-modal fusion logic
│   └── main.py             # Server Entry Point
├── frontend/               # Flutter Mobile Application
│   ├── lib/
│   │   ├── core/           # Config, Themes, and Constants
│   │   ├── screens/        # UI Implementation
│   │   └── services/       # API, Jobs, and Notification services
│   └── pubspec.yaml        # Flutter Dependencies
└── README.md
```

---

## 🏁 Getting Started

### Backend Setup
1. Navigate to `/backend`
2. Install dependencies: `pip install -r requirements.txt`
3. Start the server: `python main.py`

### Frontend Setup
1. Navigate to `/frontend`
2. Update `lib/core/config/api_config.dart` with your local IP.
3. Run the app: `flutter run`

---

## ⚖️ Disclaimer
This project is a **Research Prototype** for academic purposes (PUA). It is **not** a certified medical diagnostic tool.
