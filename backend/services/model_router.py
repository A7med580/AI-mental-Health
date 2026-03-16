"""
Model Router Service
Routes screening requests to appropriate models based on ranked conditions
(FULL UPDATED VERSION: stable file handling + proper ADHD model attachment)
"""

import os
import numpy as np
import pandas as pd
from typing import List, Dict, Any, Optional
from fastapi import UploadFile

from services.model_loader import ModelLoader
from services.feature_extractor import FeatureExtractor
from config.model_config import ModelConfig
from services.depression_inference import DepressionTextInference, DepressionAudioInference, DepressionFacialInference
from services.depression_fusion import DepressionFusion
from services.adhd_inference import ADHDFacialSequenceInference


class ModelRouter:
    """Routes screening requests to appropriate models"""

    def __init__(self):
        self.model_loader = ModelLoader()
        self.feature_extractor = FeatureExtractor()
        self.config = ModelConfig()

        # Load ADHD bundle lazily when needed to prevent TensorFlow mutex lock on macOS
        self.adhd = None

    def _get_adhd_bundle(self) -> Dict[str, Any]:
        if self.adhd is None:
            self.adhd = self.model_loader.load_adhd_bundle()
        return self.adhd

    # =========================================================
    # ASD TEXT (AQ-10)
    # =========================================================
    async def predict_asd_text(self, questionnaire_data: Any, config: Dict[str, Any]) -> Dict[str, Any]:
        """
        Predict ASD from AQ-10 answers.
        - Accepts: {"answers":[...10...]} OR a raw list of 10 numbers
        - Loads available models from config keys: adaboost, xgboost, randomforest
        - Majority vote for prediction + average probability for confidence
        Returns Flutter-friendly output: "Autism"/"Non-Autism"
        """
        # Normalize input
        if isinstance(questionnaire_data, dict):
            answers = questionnaire_data.get("answers")
        else:
            answers = questionnaire_data

        if answers is None:
            raise ValueError("AQ-10 answers are required (expected key: 'answers').")

        if not isinstance(answers, (list, tuple)) or len(answers) != 10:
            raise ValueError("AQ-10 answers must be a list of length 10.")

        X = np.array(answers, dtype=np.float32).reshape(1, -1)

        loaded_models: List[tuple[str, Any]] = []
        for model_name in ["adaboost", "xgboost", "randomforest"]:
            model_path = config.get(model_name)
            if not model_path:
                continue
            try:
                model = self.model_loader.load_model(model_path, "joblib")
                loaded_models.append((model_name, model))
            except Exception:
                # ignore missing/broken models so deployment can still work with remaining ones
                continue

        if not loaded_models:
            print("[ASD/text] Warning: No models loaded. Using scoring fallback.")
            total_score = sum(answers)
            # Threshold 6: Commonly used for AQ-10 to indicate "strong indicators"
            is_autism = (total_score >= 6)
            prediction = "Autism" if is_autism else "Non-Autism"
            # Return 1.0 confidence if positive to ensure frontend navigation triggers
            confidence = 1.0 if is_autism else 0.0 
            return {
                "prediction": prediction,
                "confidence": confidence,
                "threshold": 0.5, # Explicitly low threshold for fallback
                "details": {"error": "No models loaded, using score fallback", "score": total_score},
                "models_used": []
            }

        preds: List[int] = []
        probs: List[float] = []

        for name, model in loaded_models:
            # prediction
            pred = int(model.predict(X)[0])
            preds.append(pred)

            # probability (if available)
            if hasattr(model, "predict_proba"):
                proba = float(model.predict_proba(X)[0][1])
            else:
                # fallback: treat pred as probability-like
                proba = float(pred)
            probs.append(proba)

        final_prediction_int = 1 if sum(preds) >= (len(preds) / 2.0) else 0
        final_confidence = float(sum(probs) / len(probs))

        return {
            "prediction": "Autism" if final_prediction_int == 1 else "Non-Autism",
            "confidence": round(final_confidence, 3),
            "models_used": [n for n, _ in loaded_models],
        }

    # =========================================================
    # ASD FACE from IMAGE URL
    # =========================================================
    def predict_asd_face_from_image_url_tf(self, image_url: str, config: Dict[str, Any]) -> Dict[str, Any]:
        """
        Predict ASD from a single image URL using TF/Keras model (.h5).
        Expects config:
          - model_path: path to .h5
          - class_indices: path to class_indices.json
          - confidence_threshold (optional, default 0.5)
        """
        # Optional TensorFlow/Keras Check
        try:
            from tensorflow import keras
            TF_AVAILABLE = True
        except ImportError:
            TF_AVAILABLE = False
            keras = None

        if not TF_AVAILABLE:
            raise RuntimeError("TensorFlow is not available, cannot run ASD TF face model.")

        print("Starting predict_asd_face...", flush=True)

        model_path = config.get("model_path")
        class_indices_path = config.get("class_indices")

        if not model_path or not class_indices_path:
            raise ValueError("ASD face_url config must include model_path (.h5) and class_indices (.json).")

        threshold = float(config.get("confidence_threshold", 0.5))

        print("Calling feature extractor...", flush=True)
        # 1) Get face crop (224x224 RGB) + bbox
        fx = self.feature_extractor.extract_face_crop_224_from_url(image_url)
        print("Feature extractor returned.", flush=True)

        if fx.get("face_rgb") is None:
            return {
                "prediction": "Non-Autism",
                "confidence": 0.0,
                "face_detected": False,
                "faces_count": int(fx.get("faces_count", 0)),
                "bbox": fx.get("bbox"),
                "error": fx.get("error", "No face detected"),
            }

        face_rgb = fx["face_rgb"]  # np.ndarray (224,224,3) RGB

        print("Loading keras model...", flush=True)
        # 2) Load TF model correctly (keras, not joblib)
        try:
            model = self.model_loader.load_model(model_path, "keras")
            print("Keras model loaded!", flush=True)
            class_indices = self.model_loader.load_json(class_indices_path)
            class_names = {v: k for k, v in class_indices.items()}

            # 3) Predict
            x = np.expand_dims(face_rgb.astype("float32") / 255.0, axis=0)
            preds = model.predict(x, verbose=0)[0]
            pred_idx = int(np.argmax(preds))
            pred_conf = float(preds[pred_idx])
            predicted_class = class_names.get(pred_idx, "unknown")

            # Convert to autism probability
            autism_prob = pred_conf if predicted_class == "autistic" else (1.0 - pred_conf)
            label = "Autism" if autism_prob >= threshold else "Non-Autism"

            return {
                "prediction": label,
                "confidence": round(float(autism_prob), 3),
                "face_detected": True,
                "faces_count": int(fx.get("faces_count", 1)),
                "bbox": fx.get("bbox"),
                "threshold": threshold,
                "class": predicted_class,
            }
        except Exception as e:
            print(f"[Router] WARNING: ASD face model error: {e}", flush=True)
            # Graceful fallback: report as non-autism but flag the error in detail
            return {
                "prediction": "Non-Autism",
                "confidence": 0.0,
                "face_detected": True,
                "faces_count": int(fx.get("faces_count", 1)),
                "bbox": fx.get("bbox"),
                "error": f"Model error: {str(e)}",
                "is_fallback": True
            }


    # -----------------------------
    # Helpers: safe temp file save
    # -----------------------------
    async def _save_upload_to_temp(self, up: UploadFile, suffix: str) -> str:
        """
        Save UploadFile to a temp path so it can be used multiple times reliably.
        """
        import tempfile

        tmp = tempfile.NamedTemporaryFile(delete=False, suffix=suffix)
        tmp_path = tmp.name
        tmp.close()

        await up.seek(0)
        with open(tmp_path, "wb") as f:
            while True:
                chunk = await up.read(1024 * 1024)
                if not chunk:
                    break
                f.write(chunk)
        await up.seek(0)
        return tmp_path

    def _cleanup_temp(self, path: Optional[str]) -> None:
        try:
            if path and os.path.exists(path):
                os.remove(path)
        except Exception:
            pass

    # -----------------------------
    # Main screening
    # -----------------------------
    async def execute_screening(
        self,
        ranked_conditions: List[Dict[str, float]],
        available_modalities: List[str],
        video_file: Optional[UploadFile] = None,
        audio_file: Optional[UploadFile] = None,
        questionnaire_data: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Execute screening sequentially based on ranked conditions.
        """

        results: List[Dict[str, Any]] = []

        video_path = None
        audio_path = None

        try:
            # Save files once so multiple models can read safely
            if video_file is not None:
                video_path = await self._save_upload_to_temp(video_file, suffix=".mp4")

            if audio_file is not None:
                audio_path = await self._save_upload_to_temp(audio_file, suffix=".wav")

            # Process each condition in order
            for condition_data in ranked_conditions:
                condition = condition_data.get("condition")
                if not condition:
                    continue

                model_configs = self.config.get_model_config(condition)
                if not model_configs:
                    continue

                for model_type, cfg in model_configs.items():
                    required = cfg.get("required_modalities", [])
                    if not all(m in available_modalities for m in required):
                        continue

                    try:
                        pred = await self._execute_model_prediction(
                            condition=condition,
                            model_type=model_type,
                            config=cfg,
                            video_path=video_path,
                            audio_path=audio_path,
                            questionnaire_data=questionnaire_data,
                        )

                        if not pred:
                            continue

                        confidence = float(pred.get("confidence", 0.0))
                        threshold = float(cfg.get("confidence_threshold", 0.5))

                        results.append(
                            {
                                "condition": condition,
                                "model_type": model_type,
                                "confidence": confidence,
                                "threshold": threshold,
                                "prediction": pred.get("prediction"),
                                "details": pred,
                            }
                        )

                        if confidence >= threshold:
                            return {
                                "success": True,
                                "detected_condition": condition,
                                "confidence": confidence,
                                "model_type": model_type,
                                "all_results": results,
                                "message": f"Strong indicators detected for {condition}",
                            }

                    except Exception as e:
                        print(f"[Router] Error executing {condition}/{model_type}: {e}")
                        continue

            return {
                "success": True,
                "detected_condition": None,
                "confidence": 0.0,
                "all_results": results,
                "message": "No strong indicators detected.",
            }

        finally:
            self._cleanup_temp(video_path)
            self._cleanup_temp(audio_path)

    async def _execute_model_prediction(
        self,
        condition: str,
        model_type: str,
        config: Dict[str, Any],
        video_path: Optional[str],
        audio_path: Optional[str],
        questionnaire_data: Optional[Dict[str, Any]],
    ) -> Optional[Dict[str, Any]]:
        """
        Execute prediction for a specific model. Uses file paths (stable).
        """
        input_type = config.get("input_type")

        if input_type == "features_dict":
            return await self._predict_from_features_dict(condition, model_type, questionnaire_data)

        if input_type == "eye_features":
            if not video_path:
                return None
            return await self.predict_adhd_eye_from_video(video_path)

        if input_type == "audio_file":
            if not audio_path:
                return None
            return await self.predict_adhd_voice_from_audio(audio_path)

        if input_type == "video_file":
            if not video_path:
                return None
            if condition == "ADHD" and model_type == "facial":
                return await self.predict_adhd_facial_from_video(video_path)
            # Keep ASD face if you want later
            return None

        if input_type == "aq10_scores":
            # Keep ASD text if you want later
            return None

        return None

    async def _predict_from_features_dict(
        self,
        condition: str,
        model_type: str,
        questionnaire_data: Optional[Dict[str, Any]],
    ) -> Optional[Dict[str, Any]]:
        if not questionnaire_data:
            return None

        if condition == "ADHD" and model_type == "behavior":
            return await self.predict_adhd_behavior(questionnaire_data)

        return None

    # -----------------------------
    # ADHD: Behavior (CatBoost)
    # -----------------------------
    async def predict_adhd_behavior(self, features: Dict[str, Any]) -> Dict[str, Any]:
        """
        Build DataFrame using correct feature order from adhd_behavior_feature_names.pkl
        """
        try:
            adhd_bundle = self._get_adhd_bundle()
            model = adhd_bundle["behavior_model"]
            feature_names = adhd_bundle["behavior_feature_names"]

            if not model:
                return {"prediction": 0, "confidence": 0.0, "details": {"error": "Behavior model not loaded"}}

            # Map incoming questionnaire data to clinical feature set
            mapped_row = self._map_behavioral_features(features, list(feature_names))
            X = pd.DataFrame([mapped_row], columns=feature_names)

            if hasattr(model, "predict_proba"):
                proba = float(model.predict_proba(X)[0][1])
            else:
                # fallback: treat predict output as 0/1, assign synthetic probability
                raw_pred = int(model.predict(X)[0])
                pred = 1 if raw_pred > 0 else 0
                proba = 0.85 if pred == 1 else 0.15

            pred = int(proba >= 0.5)

            print(f"[ADHD/behavior] proba={proba:.4f} pred={pred}")
            return {"prediction": pred, "confidence": proba, "probability": proba}

        except Exception as e:
            raise Exception(f"ADHD behavior prediction failed: {e}")

    def _map_behavioral_features(self, raw_features: Dict[str, Any], feature_names: List[str]) -> Dict[str, float]:
        """
        Heuristic mapping from raw questionnaire data/text to clinical model features.
        """
        def text_to_score(text: str) -> float:
            if not text: return 0.0
            low = text.lower()
            if any(w in low for w in ["never", "rarely", "none"]): return 0.0
            if any(w in low for w in ["sometimes", "occasionally"]): return 1.0
            if any(w in low for w in ["often", "usually"]): return 3.0
            if any(w in low for w in ["always", "constantly", "very often"]): return 4.0
            return 2.0 # Neutral

        mapped = {}
        for name in feature_names:
            if "score" in name:
                # chat_q_n_score
                q_idx = name.split("_")[2]
                text_key = f"chat_q_{q_idx}_text"
                mapped[name] = text_to_score(str(raw_features.get(text_key, "")))
            elif "initial_q" in name:
                # initial_q_n
                val = raw_features.get(name, 0)
                mapped[name] = float(val) / 2.0 if int(val) > 5 else float(val) # handle scale diffs
            elif name == "age":
                mapped[name] = float(raw_features.get("age", 25.0))
            else:
                mapped[name] = float(raw_features.get(name, 0.0))
        
        return mapped

    # -----------------------------
    # ADHD: Eye (video -> eye_features -> model)
    # -----------------------------
    async def predict_adhd_eye_from_video(self, video_path: str) -> Dict[str, Any]:
        try:
            eye_features = await self.feature_extractor.extract_eye_features_from_path(video_path)

            # Use the centralized model path from ModelConfig (supports env-var override)
            model_path = ModelConfig.ADHD_EYE_MODEL
            model = self.model_loader.load_model(model_path, "joblib")

            # IMPORTANT: ensure exact columns order expected by the model
            feature_cols = [
                "mean_fixation_duration_ms",
                "fixation_count",
                "saccade_count",
                "blink_rate_per_min",
                "gaze_dispersion_deg",
                "pupil_diameter_mean_mm",
                "omission_errors",
                "commission_errors",
                "reaction_time_mean_ms",
                "reaction_time_std_ms",
            ]

            if not model:
                return {"prediction": 0, "confidence": 0.0, "details": {"error": "Eye model not loaded"}}

            vals = []
            for c in feature_cols:
                vals.append(float(eye_features.get(c, 0.0)))
            
            X = pd.DataFrame([vals], columns=feature_cols)

            if hasattr(model, "predict_proba"):
                proba = float(model.predict_proba(X)[0][1])
            else:
                out = model.predict(X)
                raw_pred = int(out[0]) if np.ndim(out) else int(out)
                pred = 1 if raw_pred > 0 else 0
                proba = 0.85 if pred == 1 else 0.15

            pred = int(proba >= 0.5)

            print(f"[ADHD/eye] proba={proba:.4f} pred={pred} (Iris Enhanced)")
            return {"prediction": pred, "confidence": proba, "probability": proba, "eye_features": eye_features}

        except Exception as e:
            raise Exception(f"ADHD eye prediction failed: {e}")

    # -----------------------------
    # ADHD: Voice (audio -> features -> scaler -> SVM & CNN)
    # -----------------------------
    async def predict_adhd_voice_from_audio(self, audio_path: str) -> Dict[str, Any]:
        """
        Robust voice prediction:
        - supports SVM with/without predict_proba
        - supports CNN binary (sigmoid), 2-class softmax, or multi-class (e.g., emotions)
        """
        try:
            audio_features = await self.feature_extractor.extract_audio_features_from_path(audio_path)
            if isinstance(audio_features, dict) and "error" in audio_features:
                raise Exception(audio_features["error"])

            vec = audio_features["combined"] if isinstance(audio_features, dict) else audio_features
            X = np.array(vec, dtype=np.float32).reshape(1, -1)

            adhd_bundle = self._get_adhd_bundle()
            scaler = adhd_bundle["voice_scaler"]
            svm = adhd_bundle["voice_svm"]
            cnn = adhd_bundle["voice_cnn"]

            Xs = scaler.transform(X)

            # ---- SVM probability ----
            svm_proba = 0.5
            svm_pred = 0
            if svm:
                if hasattr(svm, "predict_proba"):
                    svm_proba = float(svm.predict_proba(Xs)[0][1])
                    svm_pred = int(svm_proba >= 0.5)
                else:
                    raw_pred = int(svm.predict(Xs)[0])
                    svm_pred = 1 if raw_pred > 0 else 0
                    svm_proba = 0.85 if svm_pred == 1 else 0.15
            else:
                print("[ADHD/voice] Warning: SVM model not found")

            # ---- CNN probability ----
            cnn_proba = 0.5
            cnn_pred = 0
            if cnn:
                Xcnn = np.expand_dims(Xs, axis=2)  # (1, features, 1)
                out = cnn.predict(Xcnn, verbose=0)[0]
                out = np.array(out)

                if out.ndim == 0:
                    cnn_proba = float(out)
                elif out.size == 1:
                    cnn_proba = float(out[0])
                elif out.size == 2:
                    cnn_proba = float(out[1])
                else:
                    top_idx = int(np.argmax(out))
                    top_prob = float(out[top_idx])
                    if top_idx in [0, 1]:
                        cnn_proba = 0.15
                    else:
                        cnn_proba = min(0.90, top_prob * 0.6 + 0.2)
                cnn_pred = int(cnn_proba >= 0.5)
            else:
                print("[ADHD/voice] Warning: CNN model not found")

            # ---- Fuse voice ----
            if svm and cnn:
                avg_proba = (svm_proba + cnn_proba) / 2.0
            elif svm:
                avg_proba = svm_proba
            elif cnn:
                avg_proba = cnn_proba
            else:
                return {"prediction": 0, "confidence": 0.0, "details": {"error": "Voice models not loaded"}}

            pred = int(avg_proba >= 0.5)

            print(f"[ADHD/voice] svm={svm_proba:.4f} cnn={cnn_proba:.4f} avg={avg_proba:.4f} pred={pred}")

            return {
                "prediction": pred,
                "confidence": float(avg_proba),
                "svm_prediction": svm_pred,
                "svm_probability": float(svm_proba),
                "cnn_prediction": cnn_pred,
                "cnn_probability": float(cnn_proba),
                "cnn_output_dim": int(out.size) if cnn else 0,
            }

        except Exception as e:
            raise Exception(f"ADHD voice prediction failed: {e}")

    # -----------------------------
    # ADHD: Facial/Emotion (video -> face frame -> emotion model)
    # -----------------------------
    async def predict_adhd_facial_from_video(self, video_path: str) -> Dict[str, Any]:
        """
        NEW: Sequence-based temporal facial analysis for ADHD.
        Transitioned from single-frame ResNet50 proxy to BiLSTM AU sequence modeling.
        """
        try:
            # 1. Extract AU Sequence (temporal features)
            au_sequence = await self.feature_extractor.extract_facial_aus_sequence(video_path, max_frames=300)
            
            if not au_sequence:
                raise Exception("No facial sequence detected in video")

            # 2. Get ADHD Sequence Model bundle
            adhd_bundle = self._get_adhd_bundle()
            seq_bundle = adhd_bundle.get("sequence_model")
            
            if not seq_bundle or not seq_bundle.get("model"):
                # Fallback to single-frame emotion model if sequence model is missing
                print("[ADHD/facial] Warning: Sequence model missing, falling back to emotion proxy")
                return await self._predict_adhd_facial_fallback(video_path)

            # 3. Create Inference instance
            inference = ADHDFacialSequenceInference(
                model=seq_bundle["model"],
                device=seq_bundle["device"],
                n_aus=17,
                seq_len=300
            )

            # 4. Predict
            result = await inference.predict(au_sequence)
            
            print(f"[ADHD/facial] sequence_proba={result['confidence']:.4f} pred={result['prediction']} (Temporal Enhanced)")
            return {
                "prediction": result["prediction"],
                "confidence": result["confidence"],
                "details": result["details"],
                "model_version": "v2_temporal"
            }

        except Exception as e:
            raise Exception(f"ADHD facial prediction failed: {e}")

    async def _predict_adhd_facial_fallback(self, video_path: str) -> Dict[str, Any]:
        """
        Fallback implementation for ADHD facial using single-frame emotion proxy.
        """
        try:
            face_frame = await self.feature_extractor.extract_first_face_frame_from_path(video_path)
            if face_frame is None:
                raise Exception("No face detected for fallback")

            import cv2
            face_resized = cv2.resize(cv2.cvtColor(face_frame, cv2.COLOR_BGR2RGB), (224, 224))
            X = np.expand_dims(face_resized / 255.0, axis=0).astype(np.float32)

            model = self._get_adhd_bundle().get("emotion_model")
            if not model:
                return {"prediction": 0, "confidence": 0.0, "details": {"error": "Fallback model missing"}}
            
            preds = model.predict(X, verbose=0)[0]
            max_prob = float(np.max(preds))
            top_idx = int(np.argmax(preds))
            
            # proxy mapping
            adhd_prob = 0.15 if top_idx in [0, 1] else min(0.90, max_prob * 0.6 + 0.2)
            return {"prediction": int(adhd_prob >= 0.5), "confidence": adhd_prob, "is_fallback": True}
        except Exception:
            return {"prediction": 0, "confidence": 0.0, "details": {"error": "Fallback failed"}}

    # =========================================================
    # DEPRESSION (DAIC-WOZ DAIC-WOZ)
    # =========================================================
    async def execute_depression_screening(
        self,
        video_path: Optional[str],
        questionnaire_data: Optional[Dict[str, Any]],
    ) -> Dict[str, Any]:
        """
        Executes the multimodal DAIC-WOZ depression screening using new services.
        """
        import torch

        # 1. LOAD BUNDLE
        bundle = self.model_loader.load_depression_bundle()
        device = bundle["device"]

        # Initialize inference workers
        text_inf = DepressionTextInference(bundle["text_tokenizer"], bundle["text_model"], device) if bundle["text_model"] else None
        audio_inf = DepressionAudioInference(bundle["audio_model"], bundle["audio_scaler"]) if bundle["audio_model"] else None
        visual_inf = DepressionFacialInference(bundle["visual_model"], device, bundle["n_aus"], bundle["seq_len"]) if bundle["visual_model"] else None

        individual_results = []
        modalities_used = []

        # 2. TEXT MODALITY
        if questionnaire_data and text_inf:
            try:
                res = text_inf.predict(questionnaire_data)
                res["model_type"] = "text"
                individual_results.append(res)
                modalities_used.append("text")
            except Exception as e:
                print(f"[Depression/Text] Inference error: {e}")

        # 3. VIDEO-BASED MODALITIES (Audio/Facial)
        if video_path and os.path.exists(video_path):
            # Extract Audio features
            if audio_inf:
                try:
                    # ffmpeg extraction (handled by feature_extractor)
                    audio_feats = await self.feature_extractor.extract_audio_from_video_path(video_path)
                    res = await audio_inf.predict(audio_feats)
                    res["model_type"] = "audio"
                    individual_results.append(res)
                    modalities_used.append("audio")
                except Exception as e:
                    print(f"[Depression/Audio] Inference error: {e}")
            
            # Extract Facial features
            if visual_inf:
                try:
                    au_seq = await self.feature_extractor.extract_facial_aus_sequence(video_path, max_frames=bundle["seq_len"])
                    res = await visual_inf.predict(au_seq)
                    res["model_type"] = "facial" # Frontend expects "facial"
                    individual_results.append(res)
                    modalities_used.append("video") # Frontend expects "video" in modalities_used
                except Exception as e:
                    print(f"[Depression/Visual] Inference error: {e}")

        # 4. FUSION / FALLBACK
        if not individual_results:
            if questionnaire_data:
                print("[Depression] No models available. Using questionnaire fallback.")
                # Basic PHQ-8 sum if keys exist
                total_q_score = 0
                valid_qs = 0
                for i in range(8):
                    val = questionnaire_data.get(f"depression_q_{i}")
                    if val is not None and isinstance(val, (int, float)):
                        total_q_score += int(val)
                        valid_qs += 1
                
                # Check initial questionnaire scores if deep-dive ones are missing
                if valid_qs == 0:
                    for i in range(6, 10):
                        val = questionnaire_data.get(f"initial_q_{i}")
                        if val is not None:
                            try:
                                total_q_score += int(val)
                                valid_qs += 1
                            except: pass
                
                # If we have at least some questions, calculate a proxy confidence
                # PHQ-8 range is 0-24. 10+ is usually Moderate. 
                # Note: initial questions are 0-4 scale, so 4 questions = max 16.
                # We'll normalize to 24 scale for severity mapping.
                max_possible = valid_qs * 4 if valid_qs > 0 else 1
                phq8_equivalent = int(round((total_q_score / max_possible) * 24)) if valid_qs > 0 else 0
                
                fused_confidence = float(phq8_equivalent / 24.0)
                fused_prediction = 1 if phq8_equivalent >= 10 else 0
                
                # Severity mapping
                if phq8_equivalent <= 4: severity = "Minimal"
                elif phq8_equivalent <= 9: severity = "Mild"
                elif phq8_equivalent <= 14: severity = "Moderate"
                elif phq8_equivalent <= 19: severity = "Moderately Severe"
                else: severity = "Severe"

                return {
                    "success": True,
                    "condition": "Depression",
                    "fused_result": {
                        "fused_prediction": fused_prediction,
                        "fused_confidence": round(fused_confidence, 3),
                        "phq8_score": total_q_score,
                        "severity": severity,
                        "message": "Result based on questionnaire fallback (models missing)."
                    },
                    "individual_results": [],
                    "modalities_used": ["questionnaire"]
                }

            return {
                "success": False,
                "condition": "Depression",
                "message": "Insufficient data/models to complete depression screening.",
                "fused_result": None,
                "individual_results": [],
                "modalities_used": []
            }

        fused = DepressionFusion.fuse_results(individual_results)
        
        # 5. ASSEMBLE FRONTEND RESPONSE
        return {
            "success": True,
            "condition": "Depression",
            "fused_result": {
                "fused_prediction": fused["fused_prediction"],
                "fused_confidence": fused["fused_confidence"],
                "phq8_score": fused["phq8_score"],
                "severity": fused["severity"],
                "message": fused["message"] # Optional helper
            },
            "individual_results": individual_results,
            "modalities_used": modalities_used
        }
