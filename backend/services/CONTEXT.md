# Overview
This directory houses the core backend logic, separating machine learning loading, feature extraction, and prediction routing from the FastAPI transport layer.

# Primary Files & Responsibilities

* **`model_loader.py`**: A singleton pattern class responsible for loading, compiling, and caching Keras (`.h5`, `.keras`), Joblib, PyTorch (`.pt`), and HuggingFace models. Ensures models aren't re-loaded into memory on every request. Specifically handles `DepressionBiLSTM` and DistilBERT loading for the depression module.
* **`feature_extractor.py`**: The heavy lifter for data transformation. It takes raw mp4/wav/images and uses Librosa (MFCC), MediaPipe (Face/Eye mapping), and OpenCV to extract numerical feature vectors. For depression, it handles FFmpeg conversion for audio and AU sequence extraction for visual.
* **`model_router.py`**: The orchestrator. It acts as the bridge between `main.py` endpoints and the loaded models. It contains `execute_depression_screening`, which manually orchestrates text, audio, and visual feature extraction and feeds them into the Logistic Regression fusion model.
* **`adhd_fusion.py`**: Implements "Late Fusion" logic for ADHD. Weights sub-model confidence scores (voice, face, eye, behavior) to produce a final likelihood.
* **`job_store.py`**: A simple (currently in-memory) persistence layer for tracking the state of background ML jobs (`queued`, `processing`, `completed`, `failed`). 

# Key Logic Flow & Edge Cases

1. **Multimodal Orchestration:** The depression flow (`execute_depression_screening`) is strictly sequential:
    - **Step 1:** Extract text from questionnaire JSON.
    - **Step 2:** Extract WAV from MP4 via subprocess FFmpeg.
    - **Step 3:** Perform frame-by-frame AU extraction (Visual).
    - **Step 4:** Late fusion via Logistic Regression.
2. **Lazy Loading:** `model_loader.py` strictly lazy-loads assets to preserve server RAM. Complex models like DistilBERT are only instantiated once as singletons.
3. **Feature Synchronization:** Handles edge cases where a modality (e.g., video) is optional or fails. The system calculates a mean probability fallback to allow the fusion model to operate even with missing modalities.
4. **Temp File Management:** Coordinates with OS file systems to pass video paths to extraction tools, using `finally` blocks for secure deletion of temp wav and auction unit intermediate files.
