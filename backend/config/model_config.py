"""
Model Configuration
Defines model paths, thresholds, and required modalities
(Updated: stable backend-relative paths + ENV overrides)
"""

import os
from pathlib import Path


class ModelConfig:
    """
    Notes:
    - Recommended structure:
        backend/
          models/
            adhd/
              adhd_behavior_catboost.pkl
              adhd_behavior_feature_names.pkl
              adhd_eye_best_model.pkl
              voice_cnn_model.h5
              voice_scaler.pkl
              voice_svm_model.pkl
              young_affectnet_best_emotion_model_ResNet50.keras
    - You can override by environment variables without touching code.
    """

    # backend/config -> backend
    BACKEND_DIR = Path(__file__).resolve().parent.parent
    DEFAULT_ADHD_DIR = BACKEND_DIR / "Models" / "adhd"

    # ADHD Models (ENV override supported)
    ADHD_MODELS_DIR = Path(os.getenv("ADHD_MODELS_DIR", str(DEFAULT_ADHD_DIR)))

    ADHD_BEHAVIOR_MODEL = os.getenv("ADHD_BEHAVIOR_MODEL", str(ADHD_MODELS_DIR / "adhd_behavior_catboost.pkl"))
    ADHD_BEHAVIOR_FEATURES = os.getenv("ADHD_BEHAVIOR_FEATURES", str(ADHD_MODELS_DIR / "adhd_behavior_feature_names.pkl"))
    ADHD_EYE_MODEL = os.getenv("ADHD_EYE_MODEL", str(ADHD_MODELS_DIR / "adhd_eye_best_model.pkl"))
    ADHD_VOICE_CNN = os.getenv("ADHD_VOICE_CNN", str(ADHD_MODELS_DIR / "voice_cnn_model.h5"))
    ADHD_VOICE_SVM = os.getenv("ADHD_VOICE_SVM", str(ADHD_MODELS_DIR / "voice_svm_model.pkl"))
    ADHD_VOICE_SCALER = os.getenv("ADHD_VOICE_SCALER", str(ADHD_MODELS_DIR / "voice_scaler.pkl"))
    ADHD_FACIAL_MODEL = os.getenv("ADHD_FACIAL_MODEL", str(ADHD_MODELS_DIR / "young_affectnet_best_emotion_model_ResNet50.keras"))

    # Anxiety / ASD (keep your existing dirs if you want, but support env too)
    ANXIETY_MODEL = os.getenv("ANXIETY_MODEL", str(BACKEND_DIR / "Models" / "anxiety" / "anxiety_detection_model.pkl"))

    ASD_FACE_MODEL = os.getenv("ASD_FACE_MODEL", str(BACKEND_DIR / "Models" / "asd" / "face" / "asd_vgg19_fixed.h5"))
    ASD_FACE_CLASSES = os.getenv("ASD_FACE_CLASSES", str(BACKEND_DIR / "Models" / "asd" / "face" / "class_indices.json"))
    ASD_TEXT_ADABOOST = os.getenv("ASD_TEXT_ADABOOST", str(BACKEND_DIR / "Models" / "asd" / "text" / "adaboost_model.joblib"))
    ASD_TEXT_XGBOOST = os.getenv("ASD_TEXT_XGBOOST", str(BACKEND_DIR / "Models" / "asd" / "text" / "xgboost_model.joblib"))
    ASD_TEXT_RANDOMFOREST = os.getenv("ASD_TEXT_RANDOMFOREST", str(BACKEND_DIR / "Models" / "asd" / "text" / "random_forest_model.joblib"))

    MODELS = {
        "ADHD": {
            "behavior": {
                "model_path": ADHD_BEHAVIOR_MODEL,
                "features_path": ADHD_BEHAVIOR_FEATURES,
                "required_modalities": ["questionnaire"],
                "confidence_threshold": 0.65,
                "input_type": "features_dict",
            },
            "eye": {
                "model_path": ADHD_EYE_MODEL,
                "required_modalities": ["video"],
                "confidence_threshold": 0.60,
                "input_type": "eye_features",
            },
            "voice": {
                "cnn_model": ADHD_VOICE_CNN,
                "svm_model": ADHD_VOICE_SVM,
                "scaler": ADHD_VOICE_SCALER,
                "required_modalities": ["audio"],
                "confidence_threshold": 0.55,
                "input_type": "audio_file",
            },
            "facial": {
                "model_path": ADHD_FACIAL_MODEL,
                "required_modalities": ["video"],
                "confidence_threshold": 0.60,
                "input_type": "video_file",
            },
        },
        "Anxiety": {
            "main": {
                "model_path": ANXIETY_MODEL,
                "required_modalities": ["questionnaire"],
                "confidence_threshold": 0.70,
                "input_type": "features_dict",
            }
        },
        "ASD": {
            "face": {
                "model_path": ASD_FACE_MODEL,
                "class_indices": ASD_FACE_CLASSES,
                "required_modalities": ["video"],
                "confidence_threshold": 0.75,
                "input_type": "video_file",
            },
            "face_url": {
                "model_path": ASD_FACE_MODEL,
                "class_indices": ASD_FACE_CLASSES,
                "required_modalities": ["image_url"],
                "confidence_threshold": 0.75,
                "input_type": "image_url_tf",
            },
            "text": {
                "adaboost": ASD_TEXT_ADABOOST,
                "xgboost": ASD_TEXT_XGBOOST,
                "randomforest": ASD_TEXT_RANDOMFOREST,
                "required_modalities": ["questionnaire"],
                "confidence_threshold": 0.80,
                "input_type": "aq10_scores",
            },
        },
    }

    @staticmethod
    def get_model_config(condition: str, model_type: str = None):
        if model_type:
            return ModelConfig.MODELS.get(condition, {}).get(model_type)
        return ModelConfig.MODELS.get(condition, {})
