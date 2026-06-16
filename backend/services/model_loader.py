"""
Model Loader Service
Handles loading and caching of ML models + ADHD bundle
"""

import os
import json
import joblib
from pathlib import Path
from typing import Any, Dict

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

class ADHDSequenceLSTM(nn.Module):
    def __init__(self, input_dim: int = 17, hidden_dim: int = 64, num_layers: int = 2, dropout: float = 0.3):
        super().__init__()
        self.lstm = nn.LSTM(
            input_size=input_dim,
            hidden_size=hidden_dim,
            num_layers=num_layers,
            batch_first=True,
            bidirectional=True,
            dropout=dropout if num_layers > 1 else 0.0,
        )
        self.attention = nn.Linear(hidden_dim * 2, 1)
        self.classifier = nn.Sequential(
            nn.Dropout(dropout),
            nn.Linear(hidden_dim * 2, 32),
            nn.ReLU(),
            nn.Linear(32, 1),
        )

    def forward(self, x):
        out, _ = self.lstm(x)
        attn_weights = torch.softmax(self.attention(out), dim=1)
        context = (out * attn_weights).sum(dim=1)
        return self.classifier(context).squeeze(-1)


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
        Handles missing files gracefully.
        """
        from config.model_config import ModelConfig

        key = "__ADHD_BUNDLE__"
        if key in self._models:
            return self._models[key]

        cfg = ModelConfig()

        def safe_load(path, mtype, name):
            try:
                return self.load_model(path, mtype)
            except Exception as e:
                print(f"[ModelLoader] Warning: Could not load {name} at {path}: {e}", flush=True)
                return None

        print("[ModelLoader] Loading ADHD Bundle...", flush=True)
        bundle = {
            "behavior_model": safe_load(cfg.ADHD_BEHAVIOR_MODEL, "joblib", "behavior_model"),
            "behavior_feature_names": safe_load(cfg.ADHD_BEHAVIOR_FEATURES, "joblib", "behavior_features"),
            "eye_model": safe_load(cfg.ADHD_EYE_MODEL, "joblib", "eye_model"),
            "voice_svm": safe_load(cfg.ADHD_VOICE_SVM, "joblib", "voice_svm"),
            "voice_scaler": safe_load(cfg.ADHD_VOICE_SCALER, "joblib", "voice_scaler"),
        }

        # TensorFlow models
        # voice_cnn_model.h5 is a Git-LFS pointer stub on this branch — skip loading.
        bundle["voice_cnn"] = None
        try:
            from tensorflow import keras
            bundle["emotion_model"] = safe_load(cfg.ADHD_FACIAL_MODEL, "keras", "emotion_model")
        except ImportError:
            print("[ModelLoader] TensorFlow not available, skipping emotion model", flush=True)
            bundle["emotion_model"] = None

        # Sequence Model (PyTorch)
        bundle["sequence_model"] = self._load_adhd_sequence_model()

        self._models[key] = bundle
        print("[ModelLoader] ADHD Bundle loaded.", flush=True)
        return bundle

    def _load_adhd_sequence_model(self) -> Any:
        # Try uppercase first (actual directory name), then lowercase for cross-platform compat
        base = Path(__file__).resolve().parent.parent / "Models"
        model_path = str(base / "ADHD" / "adhd_facial_sequence_best.pt")
        if not os.path.exists(model_path):
            model_path = str(base / "adhd" / "adhd_facial_sequence_best.pt")

        # STABILITY FIX: Force CPU on macOS to avoid MPS Segfaults
        import platform
        if platform.system() == "Darwin":
            device = torch.device('cpu')
            print("[ModelLoader] macOS detected: Forcing CPU for ADHD Sequence stability.", flush=True)
        else:
            device = torch.device('mps' if torch.backends.mps.is_available() else ('cuda' if torch.cuda.is_available() else 'cpu'))

        try:
            model = ADHDSequenceLSTM(input_dim=17, hidden_dim=64, num_layers=2)
            if os.path.exists(model_path):
                model.load_state_dict(torch.load(model_path, map_location=device, weights_only=True))
                model.to(device)
                model.eval()
                # Verify trained weights loaded (not random init)
                param_mean = next(model.parameters()).data.mean().item()
                print(f"[ModelLoader] ADHD Sequence model loaded from {model_path}", flush=True)
                return {"model": model, "device": device}
            else:
                print(f"[ModelLoader] ERROR: ADHD Sequence model NOT FOUND at {model_path}", flush=True)
                return None
        except Exception as e:
            print(f"[ModelLoader] ADHD Sequence model loading error: {e}", flush=True)
            return None

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
        print("[ModelLoader] Loading fusion and audio models...", flush=True)
        try:
            fusion_model = self.load_model(dep_cfg["fusion_model"], "joblib")
        except Exception as e:
            print(f"[ModelLoader] Warning: Fusion model missing: {e}", flush=True)
            fusion_model = None

        try:
            audio_model = self.load_model(dep_cfg["audio_model"], "joblib")
            audio_scaler = self.load_model(dep_cfg["audio_scaler"], "joblib")
        except Exception as e:
            print(f"[ModelLoader] Warning: Audio model/scaler missing: {e}", flush=True)
            audio_model = None
            audio_scaler = None

        # 2. Visual Model (PyTorch BiLSTM)
        print("[ModelLoader] Loading visual BiLSTM...", flush=True)
        visual_model_path = dep_cfg["visual_model"]
        visual_meta_path = dep_cfg["visual_meta"]
        
        # STABILITY FIX: Force CPU on macOS
        import platform
        if platform.system() == "Darwin":
            device = torch.device('cpu')
            print("[ModelLoader] macOS detected: Forcing CPU for Depression Visual stability.", flush=True)
        else:
            device = torch.device('mps' if torch.backends.mps.is_available() else ('cuda' if torch.cuda.is_available() else 'cpu'))

        visual_model = None
        visual_meta = None

        if os.path.exists(visual_model_path) and os.path.exists(visual_meta_path):
            try:
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
                print("[ModelLoader] Visual model loaded successfully.", flush=True)
            except Exception as e:
                print(f"[ModelLoader] Error loading visual model: {e}", flush=True)
        else:
            print(f"[ModelLoader] Warning: Visual model files missing at {visual_model_path}", flush=True)

        # 3. Text Model (HuggingFace Transformers DistilBERT)
        print("[ModelLoader] Loading text Transformer...", flush=True)
        text_model = None
        text_tokenizer = None
        text_dir = dep_cfg["text_dir"]
        if os.path.exists(text_dir):
            try:
                from transformers import AutoTokenizer, AutoModelForSequenceClassification
                text_tokenizer = AutoTokenizer.from_pretrained(text_dir)
                text_model = AutoModelForSequenceClassification.from_pretrained(text_dir)
                text_model.to(device)
                text_model.eval()
                print("[ModelLoader] Text model loaded successfully.", flush=True)
            except Exception as e:
                print(f"[ModelLoader] Error loading text model: {e}", flush=True)
        else:
            print(f"[ModelLoader] Warning: Text model directory missing: {text_dir}", flush=True)

        bundle = {
            "fusion_model": fusion_model,
            "audio_model": audio_model,
            "audio_scaler": audio_scaler,
            "visual_model": visual_model,
            "text_tokenizer": text_tokenizer,
            "text_model": text_model,
            "device": device,
            "n_aus": visual_meta["n_aus"] if visual_meta else 14,
            "seq_len": visual_meta["seq_len"] if visual_meta else 300
        }

        self._models[key] = bundle
        print("[ModelLoader] Depression Bundle loaded fully.", flush=True)
        return bundle
