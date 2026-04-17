# Overview
This directory contains the experimental and training pipeline for the multimodal depression detection system using the DAIC-WOZ dataset.

# Primary Files & Responsibilities

* **`1_train_text.py`**: Fine-tunes a **DistilBERT** (HuggingFace) model on the transcribed DAIC-WOZ clinical interviews.
* **`2_train_audio.py`**: Trains a **LightGBM** classifier on 438 COVAREP acoustic features extracted from the audio recordings.
* **`3_train_visual.py`**: A **BiLSTM** with Attention trained on sequences of 17 Action Units (extracted via CLNF/OpenFace format) to capture temporal facial dynamics.
* **`4_train_fusion.py`**: Implements the **Late Fusion** meta-learner (Logistic Regression) that combines probabilities from the three individual models.
* **`data_loader.py`**: Shared utility for parsing the DAIC-WOZ directory structure, aligning labels, and handling sequence padding.
* **`config.py`**: Centralized hyperparameters (Learning rates, batch sizes, sequence lengths) and storage paths for models.

# Key Logic Flow & Edge Cases

1. **Training Sequence:** Must be run in order (Text/Audio/Visual first, then Fusion) as the fusion model requires the saved individual weights to generate training hold-out probabilities.
2. **Cold Start:** The `setup_training_env.sh` facilitates creation of a dedicated venv with PyTorch/MPS and HuggingFace dependencies.
3. **Data Imbalance:** The PHQ-8 categories in DAIC-WOZ are imbalanced; `3_train_visual.py` utilizes `BCEWithLogitsLoss` with positive weights to compensate.
4. **Modality Mismatch:** During inference, if a modality fails (e.g., silent video), the system uses the fusion model's ability to handle weighted fallbacks (implemented in the main backend router).
