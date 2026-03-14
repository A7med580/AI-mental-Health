"""
Depression Fusion Service
Integrates scores from multimodal inputs and calculates PHQ-8 severity.
"""
from typing import List, Dict, Any

class DepressionFusion:
    
    @staticmethod
    def fuse_results(individual_results: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Takes list of individual model results and applies weighted fusion.
        Weights: text=0.45, audio=0.30, facial=0.25
        """
        modalities = {res["model_type"]: res["confidence"] for res in individual_results}
        
        # Default weights
        weights = {"text": 0.45, "audio": 0.30, "visual": 0.25}
        
        # Calculate weighted average based on available modalities
        total_weight = 0.0
        weighted_sum = 0.0
        
        used_modalities = []
        for mod, score in modalities.items():
            if mod in weights:
                weighted_sum += score * weights[mod]
                total_weight += weights[mod]
                used_modalities.append(mod)
        
        if total_weight == 0:
            return {
                "fused_prediction": 0,
                "fused_confidence": 0.0,
                "phq8_score": 0,
                "severity": "Minimal",
                "message": "No data available for fusion"
            }
            
        fused_confidence = weighted_sum / total_weight
        fused_prediction = 1 if fused_confidence >= 0.5 else 0
        
        # Map 0.0-1.0 confidence to 0-24 PHQ-8 range
        # Note: In a real app, we'd use the regressor, but based on prompt requirements:
        phq8_score = int(round(fused_confidence * 24))
        
        # Determine severity level
        # Minimal (0-4), Mild (5-9), Moderate (10-14), Moderately Severe (15-19), Severe (20-24)
        if phq8_score <= 4:
            severity = "Minimal"
            message = "Minimal signs of depression"
        elif phq8_score <= 9:
            severity = "Mild"
            message = "Mild signs of depression"
        elif phq8_score <= 14:
            severity = "Moderate"
            message = "Moderate clinical depression"
        elif phq8_score <= 19:
            severity = "Moderately Severe"
            message = "Moderately severe clinical depression"
        else:
            severity = "Severe"
            message = "Severe clinical depression"
        
        if fused_prediction == 0 and phq8_score < 10:
            message = "No significant depression detected"
            
        return {
            "fused_prediction": fused_prediction,
            "fused_confidence": round(float(fused_confidence), 3),
            "phq8_score": phq8_score,
            "severity": severity,
            "message": message
        }
