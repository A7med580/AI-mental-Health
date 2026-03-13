"""
Model Loader Service
Handles loading and caching of ML models + ADHD bundle
"""

import os
import json
import joblib
from typing import Any, Dict
<<<<<<< HEAD
=======

# ---------------------------------------------------------
# PyTorch Depression Visual Model Definition
# Needs to exist in memory before torch.load() can unpickle
# ---------------------------------------------------------
import torch
import torch.nn as nn

class DepressionBiLSTM(nn.Module):
    def __init__(self, input_size, hidden_size, num_layers, dropout=0.5):
        super(DepressionBiLSTM, self).__init__()
        self.lstm = nn.LSTM(
            input_size=input_size,
            hidden_size=hidden_size,
            num_layers=num_layers,
            batch_first=True,
            bidirectional=True,
            dropout=dropout if num_layers > 1 else 0.0
        )
        self.attention = nn.Linear(hidden_size * 2, 1)
        self.classifier = nn.Sequential(
            nn.Dropout(dropout),
            nn.Linear(hidden_size * 2, 32),
            nn.ReLU(),
            nn.Linear(32, 1)
        )

    def forward(self, x):
        lstm_out, _ = self.lstm(x)  # (batch, seq, 2*hidden)
        attn_weights = torch.softmax(self.attention(lstm_out), dim=1)
        context = torch.sum(attn_weights * lstm_out, dim=1)
        return self.classifier(context).squeeze(-1)


>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
class ModelLoader:
    _instance = None
    _models: Dict[str, Any] = {}

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(ModelLoader, cls).__new__(cls)
        return cls._instance

    def load_model(self, model_path: str, model_type: str = "joblib") -> Any:
        if model_path in self._models:
            return self._models[model_path]

        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model file not found: {model_path}")

        if model_type in ("joblib", "pkl", "pickle"):
            model = joblib.load(model_path)

        elif model_type in ("keras", "h5"):
            try:
                from tensorflow import keras
                model = keras.models.load_model(model_path)
            except ImportError:
                raise ValueError("TensorFlow/Keras is not installed. Cannot load model.")

        else:
            raise ValueError(f"Unsupported model type: {model_type}")

        self._models[model_path] = model
        return model

    def load_json(self, json_path: str) -> Dict:
        if json_path in self._models:
            return self._models[json_path]
        with open(json_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        self._models[json_path] = data
        return data

    def clear_cache(self):
        self._models.clear()

    # ✅ NEW: ADHD bundle loader
    def load_adhd_bundle(self) -> Dict[str, Any]:
        """
        Loads all ADHD models needed by backend (cached).
        """
        from config.model_config import ModelConfig

        key = "__ADHD_BUNDLE__"
        if key in self._models:
            return self._models[key]

        cfg = ModelConfig()

        behavior_model = self.load_model(cfg.ADHD_BEHAVIOR_MODEL, "joblib")
        # feature names is .pkl, so load as joblib not json
        behavior_feature_names = self.load_model(cfg.ADHD_BEHAVIOR_FEATURES, "joblib")

        eye_model = self.load_model(cfg.ADHD_EYE_MODEL, "joblib")

        voice_svm = self.load_model(cfg.ADHD_VOICE_SVM, "joblib")
        voice_scaler = self.load_model(cfg.ADHD_VOICE_SCALER, "joblib")

        try:
            import tensorflow
        except ImportError:
            raise RuntimeError("TensorFlow/Keras not available, cannot load voice_cnn/emotion model")

        voice_cnn = self.load_model(cfg.ADHD_VOICE_CNN, "h5")
        emotion_model = self.load_model(cfg.ADHD_FACIAL_MODEL, "keras")

        bundle = {
            "behavior_model": behavior_model,
            "behavior_feature_names": behavior_feature_names,
            "eye_model": eye_model,
            "voice_svm": voice_svm,
            "voice_scaler": voice_scaler,
            "voice_cnn": voice_cnn,
            "emotion_model": emotion_model,
        }

        self._models[key] = bundle
        return bundle
<<<<<<< HEAD
=======

    # ✅ NEW: Depression (DAIC-WOZ) bundle loader
    def load_depression_bundle(self) -> Dict[str, Any]:
        """
        Loads all multimodal Depression models (Text, Audio, Visual, Fusion)
        """
        from config.model_config import ModelConfig

        key = "__DEPRESSION_BUNDLE__"
        if key in self._models:
            return self._models[key]

        cfg = ModelConfig()
        dep_cfg = cfg.get_model_config("depression", "fusion")
        if not dep_cfg:
            raise ValueError("Depression models configuration not found in ModelConfig")

        print("[ModelLoader] Loading Depression Bundle...", flush=True)

        # 1. Fusion Model & Audio (LightGBM)
        fusion_model = self.load_model(dep_cfg["fusion_model"], "joblib")
        audio_model = self.load_model(dep_cfg["audio_model"], "joblib")
        audio_scaler = self.load_model(dep_cfg["audio_scaler"], "joblib")

        # 2. Visual Model (PyTorch BiLSTM)
        visual_model_path = dep_cfg["visual_model"]
        visual_meta_path = dep_cfg["visual_meta"]
        
        device = torch.device('mps' if torch.backends.mps.is_available() else ('cuda' if torch.cuda.is_available() else 'cpu'))
        # Meta contains {input_size, hidden_size, num_layers, dropout}
        visual_meta = torch.load(visual_meta_path, map_location=device, weights_only=True)
        visual_model = DepressionBiLSTM(
            input_size=visual_meta["n_aus"],
            hidden_size=visual_meta["hidden_dim"],
            num_layers=visual_meta["num_layers"],
            dropout=visual_meta["dropout"]
        )
        visual_model.load_state_dict(torch.load(visual_model_path, map_location=device, weights_only=True))
        visual_model.to(device)
        visual_model.eval()

        # 3. Text Model (HuggingFace Transformers DistilBERT)
        try:
            from transformers import AutoTokenizer, AutoModelForSequenceClassification
        except ImportError:
            raise RuntimeError("transformers package not available for text depression model.")

        text_dir = dep_cfg["text_dir"]
        text_tokenizer = AutoTokenizer.from_pretrained(text_dir)
        text_model = AutoModelForSequenceClassification.from_pretrained(text_dir)
        text_model.to(device)
        text_model.eval()

        bundle = {
            "fusion_model": fusion_model,
            "audio_model": audio_model,
            "audio_scaler": audio_scaler,
            "visual_model": visual_model,
            "text_tokenizer": text_tokenizer,
            "text_model": text_model,
            "device": device,
            "n_aus": visual_meta["n_aus"],
            "seq_len": visual_meta["seq_len"]
        }

        self._models[key] = bundle
        print("[ModelLoader] Depression Bundle loaded successfully.", flush=True)
        return bundle
>>>>>>> ff182c9fdac30379da638d9ac6fea7dfb94ed4ad
