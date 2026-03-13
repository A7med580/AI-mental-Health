# Depression Model Training Pipeline

## What's in this folder?

This directory contains complete training scripts for the DAIC-WOZ multimodal depression detection pipeline. These scripts produce 3 specialized models + 1 fusion model that power the `/depression/` endpoints in the FastAPI backend.

## Dataset Location
`/Volumes/Untitled/daicwoz` (pre-extracted features, 167 participants, DO NOT move)

## Setup (One Time)
```bash
chmod +x setup_training_env.sh && ./setup_training_env.sh
source "/Volumes/1t storage/grad project/venv_depression/bin/activate"
```

## Training Order
```bash
cd backend/depression_training

python 2_train_audio.py      # LightGBM on COVAREP  — ~3 min
python 3_train_visual.py     # BiLSTM on CLNF AUs   — ~10 min
python 1_train_text.py       # DistilBERT transcript — ~30 min (downloads model on first run)
python 4_train_fusion.py     # Logistic regression fusion — requires above 3 to be done
```

## Output Paths (1TB Storage)
```
/Volumes/1t storage/grad project/depression_training/trained_models/
├── audio_model.joblib      ← LightGBM audio model
├── audio_scaler.joblib     ← StandardScaler for audio features
├── visual_model.pt         ← BiLSTM state dict
├── visual_model_meta.pt    ← Architecture dimensions for loading
├── text_model.pt           ← DistilBERT state dict
├── text_model_dir/         ← Full HuggingFace model for deployment
└── fusion_model.joblib     ← Final meta-learner
```

## Files
| File | Purpose |
|------|---------|
| `config.py` | All paths, hyperparams, constants |
| `data_loader.py` | Parses COVAREP, AUs, transcripts |
| `1_train_text.py` | DistilBERT fine-tuning |
| `2_train_audio.py` | LightGBM on COVAREP stats |
| `3_train_visual.py` | BiLSTM on Action Unit time-series |
| `4_train_fusion.py` | Meta-learner |
| `requirements_train.txt` | pip packages |
| `setup_training_env.sh` | One-time environment setup |
