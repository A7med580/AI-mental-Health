# 🧠 Mindful: AI Mental Health Companion

![Mindful Banner](https://via.placeholder.com/1200x300?text=Mindful+AI+Mental+Health+Companion)

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)](https://www.python.org)
[![TensorFlow](https://img.shields.io/badge/TensorFlow-%23FF6F00.svg?style=for-the-badge&logo=TensorFlow&logoColor=white)](https://www.tensorflow.org)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**Mindful** is a cutting-edge, multimodal AI-driven system designed for early screening, monitoring, and support of four key mental health conditions: **ADHD**, **Autism Spectrum Disorder (ASD)**, **Depression**, and **Social Anxiety**. 

By leveraging Computer Vision, Voice Stress Analysis, and NLP, Mindful provides objective biomarkers to supplement traditional clinical assessments.

---

## 🚀 Key Features

*   **⚡ Real-time Multimodal Screening**: Fusion of behavioral data, eye gaze heuristics, and voice prosody for accurate detection of **ADHD**, **ASD**, **Depression**, and **Social Anxiety**.
*   **🤖 MindCare AI Companion**: High-empathy supportive chatbot powered by **Gemini 2.0 Flash** for general mental health support, emotional navigation, and grounding.
*   **🧘 Wellness & Meditation Hub**: In-app audio streaming of clinically-validated meditations (MBSR/MBCT protocols) with external continuity for Spotify and YouTube.
*   **📊 Interactive Mood Monitoring**: Daily mood logging with Glassmorphism-styled metrics, trend analysis, and detailed weekly overviews.
*   **🎙️ Voice Stress Analysis**: MFCC-based emotion and impulsivity detection from audio recordings.
*   **👁️ Gaze & Facial Tracking**: Heuristic-based eye movement analysis for behavioral biomarker extraction and facial emotion recognition (AQ-10 integration).
*   **📱 Liquid Glass Design**: Premium mobile experience with smooth iOS-style transitions leveraging modern Flutter components.

---

## 🏗️ System Architecture

Mindful utilizes a modern client-server architecture built for heavy, asynchronous AI processing without compromising mobile UX.

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
    App->>API: Submit Multimodal Job
    API-->>App: Job Queued Ack
    Note over API,Models: Async Processing Starts
    API->>Models: Extract Features (Voice, Gaze, Face, NLP)
    Models-->>API: Fused Probabilities (ADHD/ASD/Depression/Anxiety)
    API->>DB: Save Final Result
    App->>API: Poll Status / Notification
    API-->>App: Screening Ready
    App->>User: Display Result Dashboard
```

### AI Fusion Engine — Internal Architecture

```mermaid
graph TD
    subgraph Input Modalities
        Face[Video/Face Feed]
        Voice[Audio Recording]
        Gaze[Eye Movement]
        Text[Questionnaire / Text]
    end

    subgraph Feature Extraction & Modeling
        Face --> ResNet["ResNet50 (Facial Emotion)"]
        Voice --> MFCC["MFCC / CNN (Voice Stress)"]
        Gaze --> MP["MediaPipe / RF (Eye Gaze)"]
        Text --> CatBoost["CatBoost (Behavioral NLP)"]
    end
    
    ResNet --> FV1[Feature Vector]
    MFCC --> FV2[Feature Vector]
    MP --> FV3[Feature Vector]
    CatBoost --> FV4[Feature Vector]
    
    subgraph Late Fusion
        FV1 & FV2 & FV3 & FV4 --> WPA[Weighted Probability Aggregator]
    end
    
    WPA --> Result["Final Screening Result<br/>(ADHD / ASD / Depression / Social Anxiety)"]
```

### App Screen Flow

```mermaid
graph TD
    A[Onboarding] --> B["Auth (Login/Register)"]
    B --> C[Home Dashboard]
    
    C --> D[Screening Chat]
    C --> E[Mood Tracker]
    C --> F[MindCare AI]
    C --> G[Wellness Hub]
    
    D --> H[Results Dashboard]
```

---

## 🛠️ Technology Stack

| Layer | Technologies |
| :--- | :--- |
| **Frontend** | Flutter, Riverpod, Supabase Auth, Camera, `just_audio`, `flutter_animate` |
| **Backend** | FastAPI (Async), Uvicorn, BackgroundTasks |
| **AI / NLP** | Google Gemini 2.0 Flash (Companion), TensorFlow, Scikit-learn, MediaPipe, Librosa, OpenCV |
| **Storage** | Supabase (User Data & Results), Cloud Storage (Media Artifacts) |

---

## 🏁 Setup Instructions

### 1. Backend Setup (FastAPI + AI Models)

The backend handles heavy ML workloads natively.

1. Navigate to the `backend/` directory:
   ```bash
   cd backend
   ```
2. Create and activate a Virtual Environment:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Set up environment variables (see `.env` Configuration below).
5. Start the server:
   ```bash
   python main.py
   ```
   *The Swagger UI will be available at `http://localhost:8000/docs`.*

### 2. Frontend Setup (Flutter App)

1. Navigate to the `frontend/` directory:
   ```bash
   cd frontend
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Update Backend Address:
   Open `lib/core/config/api_config.dart` and point `baseUrl` to your local machine running the FastAPI backend via network IP (e.g., `http://192.168.1.X:8000`).
4. Run the application:
   ```bash
   flutter run
   ```

---

## 🔑 Environment Configuration (`.env`)

Inside the `backend/` directory, create a `.env` file mapping exactly to `.env.example`:

```env
# Google Gemini API Key for MindCare AI Companion
GEMINI_API_KEY=your_gemini_api_key_here

# Supabase Configuration for Authentication and Database
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

*Note: Ensure `.env` is strongly guarded and never pushed to source control (it is excluded by `.gitignore`).*

---

## 📜 License & Academic Citation

### License
This project is open-source under the **MIT License**. See the [LICENSE](LICENSE) file for more information.

### Academic Disclaimer
> **Warning**: Mindful is an **Academic Research Prototype**. It is designed for study and exploration into multimodal objective biomarkers. It is **not** a certified medical diagnostic tool or substitute for professional medical advice.

### Citation
If you utilize this codebase or framework for your academic research, please consider citing this repository:

```bibtex
@software{Mindful_AI_Mental_Health,
  author = {Ali, Mohamed and [Contributors]},
  title = {Mindful: Multimodal AI Mental Health Companion},
  year = {2024},
  url = {https://github.com/A7med580/AI-mental-Health}
}
```
