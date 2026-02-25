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
            raise RuntimeError("No ASD text models could be loaded. Check model paths in ModelConfig.")

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

            # feature_names may be list, np array, or dict wrapper
            if isinstance(feature_names, dict):
                if "features" in feature_names:
                    feature_names = feature_names["features"]
                else:
                    feature_names = list(feature_names.values())

            feature_names = list(feature_names)

            row = {name: features.get(name, 0.0) for name in feature_names}
            X = pd.DataFrame([row], columns=feature_names)

            if hasattr(model, "predict_proba"):
                proba = float(model.predict_proba(X)[0][1])
            else:
                # fallback: treat predict output as 0/1
                out = model.predict(X)[0]
                proba = float(out)

            pred = int(proba >= 0.5)

            print(f"[ADHD/behavior] proba={proba:.4f} pred={pred}")
            return {"prediction": pred, "confidence": proba, "probability": proba}

        except Exception as e:
            raise Exception(f"ADHD behavior prediction failed: {e}")

    # -----------------------------
    # ADHD: Eye (video -> eye_features -> model)
    # -----------------------------
    async def predict_adhd_eye_from_video(self, video_path: str) -> Dict[str, Any]:
        try:
            eye_features = await self.feature_extractor.extract_eye_features_from_path(video_path)

            adhd_bundle = self._get_adhd_bundle()
            model = adhd_bundle["eye_model"]

            # IMPORTANT: ensure exact 10 columns order expected by the model
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

            X = pd.DataFrame([[float(eye_features.get(c, 0.0)) for c in feature_cols]], columns=feature_cols)

            if hasattr(model, "predict_proba"):
                proba = float(model.predict_proba(X)[0][1])
            else:
                out = model.predict(X)
                proba = float(out[0]) if np.ndim(out) else float(out)

            pred = int(proba >= 0.5)

            print(f"[ADHD/eye] proba={proba:.4f} pred={pred}")
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
            if hasattr(svm, "predict_proba"):
                svm_proba = float(svm.predict_proba(Xs)[0][1])
                svm_pred = int(svm_proba >= 0.5)
            else:
                svm_pred = int(svm.predict(Xs)[0])
                svm_proba = float(svm_pred)

            # ---- CNN probability ----
            Xcnn = np.expand_dims(Xs, axis=2)  # (1, features, 1)
            out = cnn.predict(Xcnn, verbose=0)[0]
            out = np.array(out)

            if out.ndim == 0:
                cnn_proba = float(out)
            elif out.size == 1:
                # sigmoid
                cnn_proba = float(out[0])
            elif out.size == 2:
                # 2-class softmax
                cnn_proba = float(out[1])
            else:
                # multi-class (e.g., 8 emotions): fallback proxy until you provide label order
                top_idx = int(np.argmax(out))
                top_prob = float(out[top_idx])
                cnn_proba = min(0.95, max(0.05, top_prob * 0.7))

            cnn_pred = int(cnn_proba >= 0.5)

            # ---- Fuse voice ----
            avg_proba = (svm_proba + cnn_proba) / 2.0
            pred = int(avg_proba >= 0.5)

            print(f"[ADHD/voice] svm={svm_proba:.4f} cnn={cnn_proba:.4f} avg={avg_proba:.4f} pred={pred}")

            return {
                "prediction": pred,
                "confidence": float(avg_proba),
                "svm_prediction": svm_pred,
                "svm_probability": float(svm_proba),
                "cnn_prediction": cnn_pred,
                "cnn_probability": float(cnn_proba),
                "cnn_output_dim": int(out.size),
            }

        except Exception as e:
            raise Exception(f"ADHD voice prediction failed: {e}")

    # -----------------------------
    # ADHD: Facial/Emotion (video -> face frame -> emotion model)
    # -----------------------------
    async def predict_adhd_facial_from_video(self, video_path: str) -> Dict[str, Any]:
        """
        NOTE: this uses emotion model as proxy.
        """
        try:
            face_frame = await self.feature_extractor.extract_first_face_frame_from_path(video_path)
            if face_frame is None:
                raise Exception("No face detected in video")

            import cv2

            face_rgb = cv2.cvtColor(face_frame, cv2.COLOR_BGR2RGB)
            face_resized = cv2.resize(face_rgb, (224, 224))
            X = np.expand_dims(face_resized / 255.0, axis=0).astype(np.float32)

            adhd_bundle = self._get_adhd_bundle()
            model = adhd_bundle["emotion_model"]
            preds = model.predict(X, verbose=0)[0]
            preds = np.array(preds)

            max_prob = float(np.max(preds))

            # proxy mapping (will refine later if you want)
            adhd_prob = max_prob * 0.7
            pred = int(adhd_prob >= 0.5)

            print(f"[ADHD/facial] max_emotion={max_prob:.4f} adhd_prob={adhd_prob:.4f} pred={pred}")

            return {
                "prediction": pred,
                "confidence": float(adhd_prob),
                "emotion_probabilities": preds.tolist(),
            }

        except Exception as e:
            raise Exception(f"ADHD facial prediction failed: {e}")
