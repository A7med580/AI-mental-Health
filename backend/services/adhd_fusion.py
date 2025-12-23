"""
ADHD Model Fusion Logic
Combines predictions from multiple ADHD models (behavior, eye, voice, facial)
to produce a unified ADHD screening result.
(Updated: direction-aware fusion + gating to avoid constant results)
"""

from typing import Dict, List, Any
import numpy as np


class ADHDFusion:
    # Base weights (you can tune later)
    MODEL_WEIGHTS = {
        "behavior": 0.35,
        "eye": 0.25,
        "voice": 0.20,
        "facial": 0.20,
    }

    # Final threshold
    FINAL_THRESHOLD = 0.60

    # If a submodel confidence below this, it contributes less (or can be ignored)
    MIN_MODEL_CONF = 0.10

    @staticmethod
    def fuse_adhd_results(model_results: List[Dict[str, Any]]) -> Dict[str, Any]:
        if not model_results:
            return {
                "fused_confidence": 0.0,
                "fused_prediction": 0,
                "confidence_level": "Low",
                "model_contributions": [],
                "modalities_used": [],
                "explanation": "No ADHD models were able to process the available data.",
                "threshold_met": False,
            }

        weighted_sum = 0.0
        total_weight = 0.0
        contributions = []
        modalities_used = []

        modality_map = {
            "behavior": "questionnaire",
            "eye": "video",
            "voice": "audio",
            "facial": "video",
        }

        for r in model_results:
            model_type = r.get("model_type", "unknown")
            conf = float(r.get("confidence", 0.0))
            pred = int(r.get("prediction", 0))

            base_w = float(ADHDFusion.MODEL_WEIGHTS.get(model_type, 0.10))

            # gate: if model is very low confidence, reduce its impact
            gate = 1.0
            if conf < ADHDFusion.MIN_MODEL_CONF:
                gate = 0.25  # keep tiny influence instead of zero

            w = base_w * gate

            # direction-aware: confidence should represent probability toward ADHD=1
            # if model predicted 0, treat it as (1 - conf) probability toward ADHD
            p_adhd = conf if pred == 1 else (1.0 - conf)

            weighted_sum += p_adhd * w
            total_weight += w

            contributions.append({
                "model_type": model_type,
                "prediction": pred,
                "raw_confidence": conf,
                "p_adhd": float(p_adhd),
                "base_weight": base_w,
                "gate": gate,
                "weight_used": w,
                "contribution": float(p_adhd * w),
            })

            mod = modality_map.get(model_type, "unknown")
            if mod not in modalities_used:
                modalities_used.append(mod)

        fused_conf = float(weighted_sum / total_weight) if total_weight > 0 else 0.0
        fused_pred = 1 if fused_conf >= ADHDFusion.FINAL_THRESHOLD else 0

        if fused_conf >= 0.75:
            level = "High"
        elif fused_conf >= 0.60:
            level = "Medium"
        else:
            level = "Low"

        explanation = ADHDFusion._generate_explanation(
            fused_conf,
            level,
            contributions,
            modalities_used
        )

        return {
            "fused_confidence": fused_conf,
            "fused_prediction": fused_pred,
            "confidence_level": level,
            "model_contributions": contributions,
            "modalities_used": modalities_used,
            "explanation": explanation,
            "threshold_met": fused_conf >= ADHDFusion.FINAL_THRESHOLD,
        }

    @staticmethod
    def _generate_explanation(confidence: float, level: str, contributions: List[Dict], modalities: List[str]) -> str:
        if confidence < 0.40:
            return (
                "The screening results suggest low likelihood of ADHD patterns. "
                "However, this is not a medical diagnosis. If you have concerns, "
                "please consult a healthcare professional."
            )
        elif confidence < 0.60:
            return (
                "The screening indicates some patterns that may be worth discussing "
                "with a healthcare professional. This is a screening tool, not a diagnosis. "
                f"Methods used: {', '.join(modalities)}."
            )
        elif confidence < 0.75:
            return (
                "The screening suggests moderate likelihood of ADHD-related patterns. "
                f"This assessment used {len(contributions)} analysis methods "
                f"({', '.join(modalities)}). This is not a medical diagnosis."
            )
        else:
            return (
                "The screening indicates patterns consistent with ADHD characteristics. "
                f"This assessment combined {len(contributions)} analysis methods "
                f"({', '.join(modalities)}). This is not a medical diagnosis."
            )
