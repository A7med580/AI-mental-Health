"""
ADHD Model Fusion Logic
Combines predictions from multiple ADHD models (behavior, eye, voice, facial)
to produce a unified ADHD screening result.
"""

from typing import Dict, List, Any, Optional
from fastapi import UploadFile
import numpy as np


class ADHDFusion:
    """
    Fuses results from multiple ADHD models:
    - Behavior (questionnaire-based)
    - Eye-tracking (video-based)
    - Voice (audio-based)
    - Facial expression (video-based)
    """
    
    # Model weights for fusion (can be adjusted based on validation)
    MODEL_WEIGHTS = {
        "behavior": 0.35,  # Questionnaire is most reliable
        "eye": 0.25,       # Eye-tracking provides behavioral signals
        "voice": 0.20,     # Voice patterns
        "facial": 0.20     # Facial expressions (emotion proxy)
    }
    
    # Minimum confidence threshold for final ADHD result
    FINAL_THRESHOLD = 0.60
    
    @staticmethod
    def fuse_adhd_results(
        model_results: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Fuse multiple ADHD model results into a single prediction.
        
        Args:
            model_results: List of dicts, each containing:
                {
                    "model_type": "behavior" | "eye" | "voice" | "facial",
                    "confidence": float (0.0-1.0),
                    "prediction": int (0 or 1),
                    "details": {...}  # Model-specific details
                }
        
        Returns:
            {
                "fused_confidence": float,
                "fused_prediction": int (0 or 1),
                "confidence_level": "High" | "Medium" | "Low",
                "model_contributions": [
                    {"model_type": str, "confidence": float, "weight": float}
                ],
                "modalities_used": List[str],
                "explanation": str
            }
        """
        if not model_results:
            return {
                "fused_confidence": 0.0,
                "fused_prediction": 0,
                "confidence_level": "Low",
                "model_contributions": [],
                "modalities_used": [],
                "explanation": "No ADHD models were able to process the available data."
            }
        
        # Calculate weighted average confidence
        weighted_sum = 0.0
        total_weight = 0.0
        contributions = []
        modalities_used = []
        
        for result in model_results:
            model_type = result.get("model_type", "unknown")
            confidence = result.get("confidence", 0.0)
            weight = ADHDFusion.MODEL_WEIGHTS.get(model_type, 0.1)
            
            weighted_sum += confidence * weight
            total_weight += weight
            
            contributions.append({
                "model_type": model_type,
                "confidence": float(confidence),
                "weight": weight,
                "contribution": float(confidence * weight)
            })
            
            # Map model types to modalities
            modality_map = {
                "behavior": "questionnaire",
                "eye": "video",
                "voice": "audio",
                "facial": "video"
            }
            modality = modality_map.get(model_type, "unknown")
            if modality not in modalities_used:
                modalities_used.append(modality)
        
        # Normalize weighted average
        if total_weight > 0:
            fused_confidence = weighted_sum / total_weight
        else:
            fused_confidence = 0.0
        
        # Binary prediction
        fused_prediction = 1 if fused_confidence >= ADHDFusion.FINAL_THRESHOLD else 0
        
        # Confidence level categorization
        if fused_confidence >= 0.75:
            confidence_level = "High"
        elif fused_confidence >= 0.60:
            confidence_level = "Medium"
        else:
            confidence_level = "Low"
        
        # Generate explanation
        explanation = ADHDFusion._generate_explanation(
            fused_confidence,
            confidence_level,
            contributions,
            modalities_used
        )
        
        return {
            "fused_confidence": float(fused_confidence),
            "fused_prediction": fused_prediction,
            "confidence_level": confidence_level,
            "model_contributions": contributions,
            "modalities_used": modalities_used,
            "explanation": explanation,
            "threshold_met": fused_confidence >= ADHDFusion.FINAL_THRESHOLD
        }
    
    @staticmethod
    def _generate_explanation(
        confidence: float,
        level: str,
        contributions: List[Dict],
        modalities: List[str]
    ) -> str:
        """Generate human-readable explanation of the fusion result."""
        
        if confidence < 0.40:
            return (
                "The screening results suggest low likelihood of ADHD patterns. "
                "However, this is not a medical diagnosis. If you have concerns, "
                "please consult a healthcare professional."
            )
        elif confidence < 0.60:
            return (
                f"The screening indicates some patterns that may be worth discussing "
                f"with a healthcare professional. This is a screening tool, not a diagnosis. "
                f"Multiple assessment methods ({', '.join(modalities)}) were used."
            )
        elif confidence < 0.75:
            return (
                f"The screening suggests moderate likelihood of ADHD-related patterns. "
                f"This assessment used {len(contributions)} different analysis methods "
                f"({', '.join(modalities)}). This is not a medical diagnosis - "
                f"please consult a healthcare professional for proper evaluation."
            )
        else:
            return (
                f"The screening indicates patterns consistent with ADHD characteristics. "
                f"This assessment combined {len(contributions)} different analysis methods "
                f"({', '.join(modalities)}). This is a screening result, not a medical diagnosis. "
                f"Please consult a qualified healthcare professional for proper evaluation and diagnosis."
            )

