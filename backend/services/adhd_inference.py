import torch
import numpy as np
from typing import Dict, Any, List
from services.adhd_sequence_model import ADHDSequenceLSTM

class ADHDFacialSequenceInference:
    def __init__(self, model, device, n_aus: int = 17, seq_len: int = 300):
        self.model = model
        self.device = device
        self.n_aus = n_aus
        self.seq_len = seq_len

    async def predict(self, au_sequence: List[List[float]]) -> Dict[str, Any]:
        """
        Takes AU sequence and predicts ADHD using BiLSTM.
        """
        if not au_sequence:
            return {"prediction": 0, "confidence": 0.0, "details": {"error": "No AU sequence detected"}}

        # Pad/Truncate for the sequence model
        seq = np.zeros((self.seq_len, self.n_aus), dtype=np.float32)
        for i, frame_aus in enumerate(au_sequence):
            if i >= self.seq_len:
                break
            for j in range(min(len(frame_aus), self.n_aus)):
                seq[i, j] = frame_aus[j]
                    
        X = torch.tensor(seq).unsqueeze(0).to(self.device)
        
        # Ensure model is in eval mode
        self.model.eval()
        with torch.no_grad():
            logits = self.model(X)
            # Apply sigmoid since it's likely a probability output for binary classification
            prob = torch.sigmoid(logits).item() if not hasattr(self.model, "softmax") else torch.softmax(logits, dim=-1)[0][1].item()
        
        return {
            "prediction": int(prob >= 0.5),
            "confidence": float(prob),
            "details": {"frames_processed": len(au_sequence)}
        }
