"""
config.py — Central configuration for DAIC-WOZ depression training pipeline.
All paths, hyperparameters, and constants are defined here.
"""
import os

# ─────────────────────────────────────────────
# PATHS
# ─────────────────────────────────────────────
DATASET_DIR = "/Volumes/Untitled/daicwoz"
TRAIN_SPLIT  = os.path.join(DATASET_DIR, "train_split_Depression_AVEC2017.csv")
DEV_SPLIT    = os.path.join(DATASET_DIR, "dev_split_Depression_AVEC2017.csv")

# Output on 1TB storage
OUTPUT_BASE_DIR   = "/Volumes/1t storage/grad project/backend/depression_training_output"
CHECKPOINTS_DIR   = os.path.join(OUTPUT_BASE_DIR, "checkpoints")
LOGS_DIR          = os.path.join(OUTPUT_BASE_DIR, "logs")
# User requested folder: "depression models foler"
TRAINED_MODELS_DIR = "/Volumes/1t storage/grad project/backend/depression models foler"

# Backend integration path (final models copied here for API use)
BACKEND_MODELS_DIR = "/Volumes/1t storage/grad project/backend/Models/depression"

# ─────────────────────────────────────────────
# FEATURES
# ─────────────────────────────────────────────
# COVAREP has 74-88 columns; we drop the timestamp column (index 0)
COVAREP_SKIP_COLS = 1  # first col is frame index
AU_SKIP_COLS      = 1  # first col is frame index

# CLNF AU column names (17 AUs used in depression literature)
AU_COLS = [
    "AU01_r", "AU02_r", "AU04_r", "AU05_r", "AU06_r", "AU07_r",
    "AU09_r", "AU10_r", "AU12_r", "AU14_r", "AU15_r", "AU17_r",
    "AU20_r", "AU23_r", "AU25_r", "AU26_r", "AU45_r"
]

# ─────────────────────────────────────────────
# TEXT MODEL (DistilBERT)
# ─────────────────────────────────────────────
TEXT_MODEL_NAME       = "distilbert-base-uncased"
TEXT_MAX_LENGTH       = 512
TEXT_BATCH_SIZE       = 8
TEXT_EPOCHS           = 8
TEXT_LR               = 2e-5
TEXT_WARMUP_STEPS     = 50
TEXT_WEIGHT_DECAY     = 0.01
TEXT_DROPOUT          = 0.3
TEXT_OUTPUT_FILE      = os.path.join(TRAINED_MODELS_DIR, "text_model.pt")

# ─────────────────────────────────────────────
# AUDIO MODEL (LightGBM on COVAREP stats)
# ─────────────────────────────────────────────
AUDIO_N_ESTIMATORS = 500
AUDIO_MAX_DEPTH    = 6
AUDIO_LR           = 0.05
AUDIO_SUBSAMPLE    = 0.8
AUDIO_OUTPUT_FILE  = os.path.join(TRAINED_MODELS_DIR, "audio_model.joblib")
AUDIO_SCALER_FILE  = os.path.join(TRAINED_MODELS_DIR, "audio_scaler.joblib")

# Aggregate statistics: for each COVAREP feature compute these stats
AUDIO_AGG_STATS = ["mean", "std", "min", "max", "skew", "median"]

# ─────────────────────────────────────────────
# VISUAL MODEL (BiLSTM on CLNF AUs)
# ─────────────────────────────────────────────
VISUAL_SEQ_LEN    = 300   # sample or pad to N frames
VISUAL_HIDDEN_DIM = 64
VISUAL_NUM_LAYERS = 2
VISUAL_DROPOUT    = 0.4
VISUAL_BATCH_SIZE = 16
VISUAL_EPOCHS     = 20
VISUAL_LR         = 1e-3
VISUAL_OUTPUT_FILE = os.path.join(TRAINED_MODELS_DIR, "visual_model.pt")

# ─────────────────────────────────────────────
# FUSION META-LEARNER
# ─────────────────────────────────────────────
FUSION_OUTPUT_FILE = os.path.join(TRAINED_MODELS_DIR, "fusion_model.joblib")

# ─────────────────────────────────────────────
# LABELS
# ─────────────────────────────────────────────
LABEL_BINARY = "PHQ8_Binary"
LABEL_SCORE  = "PHQ8_Score"

# PHQ8 ≥ 10 is clinically "depressed" (binary threshold for score-only sets)
PHQ8_THRESHOLD = 10

# Random seed for reproducibility
SEED = 42
