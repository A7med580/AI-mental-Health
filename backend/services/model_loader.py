"""
Model Loader Service
Handles loading and caching of ML models + ADHD bundle
"""

import os
import json
import joblib
from typing import Any, Dict
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

        # Load models individually and gracefully handle failures
        behavior_model = None
        behavior_feature_names = None
        eye_model = None
        voice_svm = None
        voice_scaler = None
        voice_cnn = None
        emotion_model = None

        try:
            behavior_model = self.load_model(cfg.ADHD_BEHAVIOR_MODEL, "joblib")
            behavior_feature_names = self.load_model(cfg.ADHD_BEHAVIOR_FEATURES, "joblib")
        except Exception as e:
            print(f"[ModelLoader] Failed to load behavior models: {e}")

        try:
            eye_model = self.load_model(cfg.ADHD_EYE_MODEL, "joblib")
        except Exception as e:
            print(f"[ModelLoader] Failed to load eye model: {e}")

        try:
            voice_svm = self.load_model(cfg.ADHD_VOICE_SVM, "joblib")
            voice_scaler = self.load_model(cfg.ADHD_VOICE_SCALER, "joblib")
        except Exception as e:
            print(f"[ModelLoader] Failed to load voice SVM/scaler: {e}")

        try:
            import tensorflow
            try:
                # Compile=False prevents optimizer errors from Keras 3 models
                from tensorflow import keras
                voice_cnn = keras.models.load_model(cfg.ADHD_VOICE_CNN, compile=False)
                self._models[cfg.ADHD_VOICE_CNN] = voice_cnn
            except Exception as e:
                print(f"[ModelLoader] Failed to load voice_cnn: {e}")

            try:
                emotion_model = keras.models.load_model(cfg.ADHD_FACIAL_MODEL, compile=False)
                self._models[cfg.ADHD_FACIAL_MODEL] = emotion_model
            except Exception as e:
                print(f"[ModelLoader] Failed to load emotion_model: {e}")

        except ImportError:
            print("[ModelLoader] TensorFlow/Keras not available, skipping deep learning models")

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
