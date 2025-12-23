"""
Model Loader Service
Handles loading and caching of ML models + ADHD bundle
"""

import os
import json
import joblib
from typing import Any, Dict

try:
    from tensorflow import keras
    TF_AVAILABLE = True
except Exception:
    TF_AVAILABLE = False


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

        elif model_type in ("keras", "h5") and TF_AVAILABLE:
            model = keras.models.load_model(model_path)

        else:
            raise ValueError(f"Unsupported model type: {model_type} (TF_AVAILABLE={TF_AVAILABLE})")

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

        if not TF_AVAILABLE:
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
