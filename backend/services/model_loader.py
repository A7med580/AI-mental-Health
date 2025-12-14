"""
Model Loader Service
Handles loading and caching of ML models
"""

import joblib
import json
import os
from typing import Optional, Any, Dict
from pathlib import Path

# Try to import TensorFlow/Keras
try:
    import tensorflow as tf
    from tensorflow import keras
    TF_AVAILABLE = True
except ImportError:
    TF_AVAILABLE = False
    print("Warning: TensorFlow not available. Some models will not work.")


class ModelLoader:
    """Singleton model loader with caching"""
    
    _instance = None
    _models = {}
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(ModelLoader, cls).__new__(cls)
        return cls._instance
    
    def load_model(self, model_path: str, model_type: str = "joblib") -> Any:
        """Load a model from disk with caching"""
        if model_path in self._models:
            return self._models[model_path]
        
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model file not found: {model_path}")
        
        try:
            if model_type == "joblib":
                model = joblib.load(model_path)
            elif model_type == "keras" and TF_AVAILABLE:
                model = keras.models.load_model(model_path)
            elif model_type == "h5" and TF_AVAILABLE:
                model = keras.models.load_model(model_path)
            else:
                raise ValueError(f"Unsupported model type: {model_type}")
            
            self._models[model_path] = model
            return model
        except Exception as e:
            raise RuntimeError(f"Failed to load model from {model_path}: {str(e)}")
    
    def load_json(self, json_path: str) -> Dict:
        """Load JSON file"""
        if json_path in self._models:
            return self._models[json_path]
        
        with open(json_path, 'r') as f:
            data = json.load(f)
        self._models[json_path] = data
        return data
    
    def clear_cache(self):
        """Clear model cache"""
        self._models.clear()

