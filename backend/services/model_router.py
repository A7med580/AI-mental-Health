"""
Model Router Service
Routes screening requests to appropriate models based on ranked conditions
"""

import numpy as np
import pandas as pd
from typing import List, Dict, Any, Optional
from fastapi import UploadFile
import tempfile
import os
import cv2

from services.model_loader import ModelLoader
from services.feature_extractor import FeatureExtractor
from config.model_config import ModelConfig

# Try to import TensorFlow
try:
    import tensorflow as tf
    from tensorflow import keras
    from tensorflow.keras.preprocessing import image
    TF_AVAILABLE = True
except ImportError:
    TF_AVAILABLE = False


class ModelRouter:
    """Routes screening requests to appropriate models"""
    
    def __init__(self):
        self.model_loader = ModelLoader()
        self.feature_extractor = FeatureExtractor()
        self.config = ModelConfig()
    
    async def execute_screening(
        self,
        ranked_conditions: List[Dict[str, float]],
        available_modalities: List[str],
        video_file: Optional[UploadFile] = None,
        audio_file: Optional[UploadFile] = None,
        questionnaire_data: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Execute screening sequentially based on ranked conditions
        
        Args:
            ranked_conditions: [{"condition": "ADHD", "probability": 0.75}, ...]
            available_modalities: ["video", "audio", "text"]
            video_file: Optional video file
            audio_file: Optional audio file
            questionnaire_data: Optional questionnaire responses
        
        Returns:
            Screening result with condition, confidence, and details
        """
        results = []
        
        # Process each condition in order
        for condition_data in ranked_conditions:
            condition = condition_data.get("condition")
            initial_probability = condition_data.get("probability", 0.0)
            
            if not condition:
                continue
            
            # Get model configuration for this condition
            model_configs = self.config.get_model_config(condition)
            
            if not model_configs:
                continue
            
            # Try each model type for this condition
            for model_type, config in model_configs.items():
                required_modalities = config.get("required_modalities", [])
                
                # Check if required modalities are available
                if not all(mod in available_modalities for mod in required_modalities):
                    continue
                
                try:
                    # Execute model prediction
                    prediction = await self._execute_model_prediction(
                        condition=condition,
                        model_type=model_type,
                        config=config,
                        video_file=video_file,
                        audio_file=audio_file,
                        questionnaire_data=questionnaire_data
                    )
                    
                    if prediction:
                        confidence = prediction.get("confidence", 0.0)
                        threshold = config.get("confidence_threshold", 0.5)
                        
                        results.append({
                            "condition": condition,
                            "model_type": model_type,
                            "confidence": confidence,
                            "threshold": threshold,
                            "prediction": prediction.get("prediction"),
                            "details": prediction
                        })
                        
                        # If confidence meets threshold, return result
                        if confidence >= threshold:
                            return {
                                "success": True,
                                "detected_condition": condition,
                                "confidence": confidence,
                                "model_type": model_type,
                                "all_results": results,
                                "message": f"Strong indicators detected for {condition}"
                            }
                
                except Exception as e:
                    print(f"Error executing {condition}/{model_type}: {str(e)}")
                    continue
        
        # No strong indicators found
        return {
            "success": True,
            "detected_condition": None,
            "confidence": 0.0,
            "all_results": results,
            "message": "No strong indicators detected. Consider consulting a healthcare professional."
        }
    
    async def _execute_model_prediction(
        self,
        condition: str,
        model_type: str,
        config: Dict[str, Any],
        video_file: Optional[UploadFile] = None,
        audio_file: Optional[UploadFile] = None,
        questionnaire_data: Optional[Dict[str, Any]] = None
    ) -> Optional[Dict[str, Any]]:
        """Execute prediction for a specific model"""
        
        input_type = config.get("input_type")
        
        if input_type == "features_dict":
            return await self._predict_from_features_dict(condition, model_type, config, questionnaire_data)
        
        elif input_type == "eye_features":
            return await self._predict_adhd_eye(questionnaire_data)
        
        elif input_type == "audio_file":
            if audio_file:
                return await self._predict_adhd_voice(audio_file, config)
            return None
        
        elif input_type == "video_file":
            if video_file:
                if condition == "ADHD" and model_type == "facial":
                    return await self._predict_adhd_facial(video_file, config)
                elif condition == "ASD" and model_type == "face":
                    return await self._predict_asd_face(video_file, config)
            return None
        
        elif input_type == "aq10_scores":
            return await self._predict_asd_text(questionnaire_data, config)
        
        return None
    
    async def _predict_from_features_dict(
        self,
        condition: str,
        model_type: str,
        config: Dict[str, Any],
        questionnaire_data: Optional[Dict[str, Any]]
    ) -> Optional[Dict[str, Any]]:
        """Predict from feature dictionary (for behavior models)"""
        if not questionnaire_data:
            return None
        
        try:
            if condition == "ADHD" and model_type == "behavior":
                return await self.predict_adhd_behavior(questionnaire_data)
            elif condition == "Anxiety" and model_type == "main":
                return await self.predict_anxiety(questionnaire_data)
        except Exception as e:
            print(f"Error in _predict_from_features_dict: {str(e)}")
            return None
    
    async def predict_adhd_behavior(self, features: Dict[str, Any]) -> Dict[str, Any]:
        """Predict ADHD using behavior model"""
        try:
            model_path = self.config.ADHD_BEHAVIOR_MODEL
            features_path = self.config.ADHD_BEHAVIOR_FEATURES
            
            model = self.model_loader.load_model(model_path)
            feature_names = self.model_loader.load_json(features_path)
            
            # Build feature vector
            feature_vector = []
            for feat_name in feature_names:
                feature_vector.append(features.get(feat_name, 0.0))
            
            feature_array = np.array(feature_vector).reshape(1, -1)
            
            # Predict
            proba = model.predict_proba(feature_array)[0, 1]
            pred = int(model.predict(feature_array)[0])
            
            return {
                "prediction": pred,
                "confidence": float(proba),
                "probability": float(proba)
            }
        except Exception as e:
            raise Exception(f"ADHD behavior prediction failed: {str(e)}")
    
    async def predict_adhd_eye(self, eye_features: Dict[str, Any]) -> Dict[str, Any]:
        """Predict ADHD using eye-tracking model"""
        try:
            model_path = self.config.ADHD_EYE_MODEL
            model_bundle = self.model_loader.load_model(model_path)
            
            # Model bundle contains model and feature_cols
            if isinstance(model_bundle, dict):
                model = model_bundle["model"]
                feature_cols = model_bundle["feature_cols"]
            else:
                model = model_bundle
                feature_cols = [
                    "mean_fixation_duration_ms", "fixation_count", "saccade_count",
                    "blink_rate_per_min", "gaze_dispersion_deg", "pupil_diameter_mean_mm",
                    "omission_errors", "commission_errors", "reaction_time_mean_ms",
                    "reaction_time_std_ms"
                ]
            
            # Build feature vector
            feature_vector = [eye_features.get(col, 0.0) for col in feature_cols]
            feature_df = pd.DataFrame([feature_vector], columns=feature_cols)
            
            # Predict
            if hasattr(model, "predict_proba"):
                proba = model.predict_proba(feature_df)[0, 1]
            else:
                proba = float(model.predict(feature_df)[0])
            
            pred = int(proba >= 0.5)
            
            return {
                "prediction": pred,
                "confidence": float(proba),
                "probability": float(proba)
            }
        except Exception as e:
            raise Exception(f"ADHD eye prediction failed: {str(e)}")
    
    async def predict_adhd_voice(self, audio_file: UploadFile, config: Dict[str, Any]) -> Dict[str, Any]:
        """Predict ADHD using voice model"""
        try:
            # Extract audio features
            audio_features = await self.feature_extractor.extract_from_audio(audio_file)
            
            if "error" in audio_features:
                raise Exception(audio_features["error"])
            
            # Load models
            cnn_model = self.model_loader.load_model(config["cnn_model"], "keras")
            svm_model = self.model_loader.load_model(config["svm_model"])
            scaler = self.model_loader.load_model(config["scaler"])
            
            # Prepare features
            features = np.array(audio_features["combined"]).reshape(1, -1)
            features_scaled = scaler.transform(features)
            
            # SVM prediction
            svm_pred = svm_model.predict(features_scaled)[0]
            
            # CNN prediction
            features_cnn = np.expand_dims(features_scaled, axis=2)
            cnn_proba = cnn_model.predict(features_cnn, verbose=0)[0]
            cnn_pred = int(np.argmax(cnn_proba))
            
            # Average predictions
            avg_confidence = (float(svm_pred) + float(cnn_proba[1])) / 2.0
            
            return {
                "prediction": int(avg_confidence >= 0.5),
                "confidence": avg_confidence,
                "svm_prediction": int(svm_pred),
                "cnn_prediction": cnn_pred,
                "cnn_probability": float(cnn_proba[1])
            }
        except Exception as e:
            raise Exception(f"ADHD voice prediction failed: {str(e)}")
    
    async def predict_adhd_facial(self, video_file: UploadFile, config: Dict[str, Any]) -> Dict[str, Any]:
        """Predict ADHD using facial expression model"""
        try:
            if not TF_AVAILABLE:
                raise Exception("TensorFlow not available")
            
            model_path = config["model_path"]
            model = self.model_loader.load_model(model_path, "keras")
            
            # Extract face features
            face_features = await self.feature_extractor.extract_face_features(video_file)
            
            if not face_features.get("face_frames"):
                raise Exception("No faces detected in video")
            
            # Use first face frame
            face_frame = face_features["face_frames"][0]
            
            # Preprocess for ResNet50
            face_frame_rgb = cv2.cvtColor(face_frame, cv2.COLOR_BGR2RGB)
            face_frame_resized = cv2.resize(face_frame_rgb, (224, 224))
            face_array = np.expand_dims(face_frame_resized / 255.0, axis=0)
            
            # Predict
            predictions = model.predict(face_array, verbose=0)[0]
            max_prob = float(np.max(predictions))
            
            # Map to ADHD probability (simplified - would need proper mapping)
            adhd_probability = max_prob * 0.7  # Scale down as this is emotion, not direct ADHD
            
            return {
                "prediction": int(adhd_probability >= 0.5),
                "confidence": adhd_probability,
                "emotion_probabilities": predictions.tolist()
            }
        except Exception as e:
            raise Exception(f"ADHD facial prediction failed: {str(e)}")
    
    async def predict_anxiety(self, features: Dict[str, Any]) -> Dict[str, Any]:
        """Predict anxiety using RandomForest model"""
        try:
            model_path = self.config.ANXIETY_MODEL
            model = self.model_loader.load_model(model_path)
            
            # Build feature vector (would need proper feature mapping)
            # For now, use features as-is
            feature_vector = list(features.values())[:18]  # Limit to 18 features
            
            feature_array = np.array(feature_vector).reshape(1, -1)
            
            # Predict
            proba = model.predict_proba(feature_array)[0, 1]
            pred = int(model.predict(feature_array)[0])
            
            return {
                "prediction": pred,
                "confidence": float(proba),
                "probability": float(proba)
            }
        except Exception as e:
            raise Exception(f"Anxiety prediction failed: {str(e)}")
    
    async def predict_asd_face(self, video_file: UploadFile, config: Dict[str, Any]) -> Dict[str, Any]:
        """Predict ASD using face model"""
        try:
            if not TF_AVAILABLE:
                raise Exception("TensorFlow not available")
            
            model_path = config["model_path"]
            class_indices_path = config["class_indices"]
            
            model = self.model_loader.load_model(model_path, "h5")
            class_indices = self.model_loader.load_json(class_indices_path)
            
            # Extract face features
            face_features = await self.feature_extractor.extract_face_features(video_file)
            
            if not face_features.get("face_frames"):
                raise Exception("No faces detected in video")
            
            # Use first face frame
            face_frame = face_features["face_frames"][0]
            
            # Preprocess
            face_frame_rgb = cv2.cvtColor(face_frame, cv2.COLOR_BGR2RGB)
            face_frame_resized = cv2.resize(face_frame_rgb, (224, 224))
            face_array = np.expand_dims(face_frame_resized / 255.0, axis=0)
            
            # Predict
            predictions = model.predict(face_array, verbose=0)[0]
            pred_idx = int(np.argmax(predictions))
            confidence = float(predictions[pred_idx])
            
            # Map class index to label
            class_names = {v: k for k, v in class_indices.items()}
            predicted_class = class_names.get(pred_idx, "unknown")
            
            # ASD probability (1 if autistic, 0 if non_autistic)
            asd_probability = confidence if predicted_class == "autistic" else (1 - confidence)
            
            return {
                "prediction": int(asd_probability >= 0.5),
                "confidence": asd_probability,
                "class": predicted_class,
                "probabilities": predictions.tolist()
            }
        except Exception as e:
            raise Exception(f"ASD face prediction failed: {str(e)}")
    
    async def predict_asd_text(self, aq10_scores: List[int], config: Dict[str, Any]) -> Dict[str, Any]:
        """Predict ASD using text models (AQ-10 scores)"""
        try:
            # Load all three models
            adaboost = self.model_loader.load_model(config["adaboost"])
            xgboost = self.model_loader.load_model(config["xgboost"])
            randomforest = self.model_loader.load_model(config["randomforest"])
            
            # Prepare input
            feature_array = np.array(aq10_scores).reshape(1, -1)
            
            # Get predictions from all models
            ada_proba = adaboost.predict_proba(feature_array)[0, 1]
            xgb_proba = xgboost.predict_proba(feature_array)[0, 1]
            rf_proba = randomforest.predict_proba(feature_array)[0, 1]
            
            # Average probabilities
            avg_proba = (ada_proba + xgb_proba + rf_proba) / 3.0
            
            return {
                "prediction": int(avg_proba >= 0.5),
                "confidence": float(avg_proba),
                "adaboost_probability": float(ada_proba),
                "xgboost_probability": float(xgb_proba),
                "randomforest_probability": float(rf_proba)
            }
        except Exception as e:
            raise Exception(f"ASD text prediction failed: {str(e)}")

