"""
Depression Inference Service
Handles modality-specific inference for the DAIC-WOZ pipeline.
"""
import os
import torch
import numpy as np
import joblib
from typing import Dict, Any, Optional, List

class DepressionTextInference:
    def __init__(self, tokenizer, model, device):
        self.tokenizer = tokenizer
        self.model = model
        self.device = device

    def predict(self, questionnaire_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Concatenates depression_q_0_text through depression_q_7_text and predicts.
        """
        text_answers = []
        for i in range(8):
            key = f"depression_q_{i}_text"
            val = questionnaire_data.get(key, "")
            if val:
                text_answers.append(val)
        
        combined_text = " ".join(text_answers).strip()
        if not combined_text:
            return {"prediction": 0, "confidence": 0.0, "details": {"error": "No text content"}}

        inputs = self.tokenizer(combined_text, return_tensors="pt", truncation=True, max_length=512, padding="max_length")
        inputs = {k: v.to(self.device) for k, v in inputs.items()}
        
        with torch.no_grad():
            outputs = self.model(**inputs)
            logits = outputs.logits
            prob = torch.softmax(logits, dim=-1)[0][1].item()
        
        return {
            "prediction": int(prob >= 0.5),
            "confidence": float(prob),
            "details": {"text_len": len(combined_text)}
        }

class DepressionAudioInference:
    def __init__(self, model, scaler):
        self.model = model
        self.scaler = scaler

    async def predict(self, audio_features: Dict[str, Any]) -> Dict[str, Any]:
        """
        Takes extracted audio features and predicts depression.
        Note: The LightGBM model was trained on 438 features.
        We expect audio_features["combined"] to match this.
        """
        if "error" in audio_features:
            return {"prediction": 0, "confidence": 0.0, "details": {"error": audio_features["error"]}}

        raw_vec = audio_features.get("combined", [])
        
        # Match the 438 features used in training if possible, otherwise pad/truncate
        # The COVAREP statistics used in training are: mean, std, min, max, skew, median
        # for each of the 73-74 features. 73 * 6 = 438.
        if len(raw_vec) != 438:
            print(f"[DepressionAudio] WARNING: Feature dimension mismatch. Expected 438, got {len(raw_vec)}.", flush=True)
            vec = np.zeros(438)
            n = min(len(raw_vec), 438)
            vec[:n] = raw_vec[:n]
        else:
            vec = raw_vec

        X = np.array(vec, dtype=np.float32).reshape(1, -1)
        X_scaled = self.scaler.transform(X)
        
        prob = float(self.model.predict_proba(X_scaled)[0][1])
        
        return {
            "prediction": int(prob >= 0.5),
            "confidence": float(prob),
            "details": {"feature_dim": len(vec)}
        }

class DepressionFacialInference:
    def __init__(self, model, device, n_aus: int = 14, seq_len: int = 300):
        self.model = model
        self.device = device
        self.n_aus = n_aus
        self.seq_len = seq_len

    async def predict(self, au_sequence: List[List[float]]) -> Dict[str, Any]:
        """
        Takes AU sequence and predicts depression using BiLSTM.
        """
        if not au_sequence:
            return {"prediction": 0, "confidence": 0.0, "details": {"error": "No AU sequence detected"}}

        # Pad/Truncate
        seq = np.zeros((self.seq_len, self.n_aus), dtype=np.float32)
        for i, frame_aus in enumerate(au_sequence):
            if i >= self.seq_len:
                break
            for j in range(min(len(frame_aus), self.n_aus)):
                seq[i, j] = frame_aus[j]
                    
        X = torch.tensor(seq).unsqueeze(0).to(self.device)
        
        with torch.no_grad():
            logits = self.model(X)
            prob = torch.sigmoid(logits).item()
        
        return {
            "prediction": int(prob >= 0.5),
            "confidence": float(prob),
            "details": {"frames": len(au_sequence)}
        }
