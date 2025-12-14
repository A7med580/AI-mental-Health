"""
Model Configuration
Defines model paths, thresholds, and required modalities
"""

import os
from pathlib import Path

# Base paths
BASE_DIR = Path(__file__).parent.parent.parent
MODELS_DIR = BASE_DIR / "Graduation Project"

# Model paths
ADHD_MODELS_DIR = MODELS_DIR / "ADHD" / "ADHD_final" / "ADHD_Models"
ANXIETY_MODELS_DIR = MODELS_DIR / "anxitey"
ASD_MODELS_DIR = MODELS_DIR / "asd" / "models" / "ASD"


class ModelConfig:
    """Configuration for all models"""
    
    # ADHD Models
    ADHD_BEHAVIOR_MODEL = str(ADHD_MODELS_DIR / "adhd_behavior_catboost.pkl")
    ADHD_BEHAVIOR_FEATURES = str(ADHD_MODELS_DIR / "adhd_behavior_feature_names.pkl")
    ADHD_EYE_MODEL = str(ADHD_MODELS_DIR / "adhd_eye_best_model.pkl")
    ADHD_VOICE_CNN = str(ADHD_MODELS_DIR / "voice_cnn_model.h5")
    ADHD_VOICE_SVM = str(ADHD_MODELS_DIR / "voice_svm_model.pkl")
    ADHD_VOICE_SCALER = str(ADHD_MODELS_DIR / "voice_scaler.pkl")
    ADHD_FACIAL_MODEL = str(ADHD_MODELS_DIR / "young_affectnet_best_emotion_model_ResNet50.keras")
    
    # Anxiety Models
    ANXIETY_MODEL = str(ANXIETY_MODELS_DIR / "anxiety_detection_model.pkl")
    
    # ASD Models
    ASD_FACE_MODEL = str(ASD_MODELS_DIR / "face" / "asd_vgg19.h5")
    ASD_FACE_CLASSES = str(ASD_MODELS_DIR / "face" / "class_indices.json")
    ASD_TEXT_ADABOOST = str(ASD_MODELS_DIR / "text" / "adaboost_model.joblib")
    ASD_TEXT_XGBOOST = str(ASD_MODELS_DIR / "text" / "xgboost_model.joblib")
    ASD_TEXT_RANDOMFOREST = str(ASD_MODELS_DIR / "text" / "random_forest_model.joblib")
    
    # Model configurations
    MODELS = {
        "ADHD": {
            "behavior": {
                "model_path": ADHD_BEHAVIOR_MODEL,
                "features_path": ADHD_BEHAVIOR_FEATURES,
                "required_modalities": ["questionnaire"],
                "confidence_threshold": 0.65,
                "input_type": "features_dict"
            },
            "eye": {
                "model_path": ADHD_EYE_MODEL,
                "required_modalities": ["video"],
                "confidence_threshold": 0.60,
                "input_type": "eye_features"
            },
            "voice": {
                "cnn_model": ADHD_VOICE_CNN,
                "svm_model": ADHD_VOICE_SVM,
                "scaler": ADHD_VOICE_SCALER,
                "required_modalities": ["audio"],
                "confidence_threshold": 0.55,
                "input_type": "audio_file"
            },
            "facial": {
                "model_path": ADHD_FACIAL_MODEL,
                "required_modalities": ["video"],
                "confidence_threshold": 0.60,
                "input_type": "video_file"
            }
        },
        "Anxiety": {
            "main": {
                "model_path": ANXIETY_MODEL,
                "required_modalities": ["questionnaire"],
                "confidence_threshold": 0.70,
                "input_type": "features_dict"
            }
        },
        "ASD": {
            "face": {
                "model_path": ASD_FACE_MODEL,
                "class_indices": ASD_FACE_CLASSES,
                "required_modalities": ["video"],
                "confidence_threshold": 0.75,
                "input_type": "video_file"
            },
            "text": {
                "adaboost": ASD_TEXT_ADABOOST,
                "xgboost": ASD_TEXT_XGBOOST,
                "randomforest": ASD_TEXT_RANDOMFOREST,
                "required_modalities": ["questionnaire"],
                "confidence_threshold": 0.80,
                "input_type": "aq10_scores"
            }
        }
    }
    
    @staticmethod
    def get_model_config(condition: str, model_type: str = None):
        """Get configuration for a specific model"""
        if model_type:
            return ModelConfig.MODELS.get(condition, {}).get(model_type)
        return ModelConfig.MODELS.get(condition, {})
    
    @staticmethod
    def get_required_modalities(condition: str, model_type: str = None):
        """Get required modalities for a model"""
        config = ModelConfig.get_model_config(condition, model_type)
        if config:
            return config.get("required_modalities", [])
        return []
    
    @staticmethod
    def get_confidence_threshold(condition: str, model_type: str = None):
        """Get confidence threshold for a model"""
        config = ModelConfig.get_model_config(condition, model_type)
        if config:
            return config.get("confidence_threshold", 0.5)
        return 0.5

