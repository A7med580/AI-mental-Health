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
# NOTE: services/depression_inference.py and services/depression_fusion.py are
# dead code after the SVM rewrite — left on disk but no longer imported.
from services.adhd_inference import ADHDFacialSequenceInference


# Module-level DistilBERT cache (loaded once on first depression request).
_bert_tokenizer = None
_bert_model = None


def get_bert():
    """
    Load the local DistilBERT (depression text model dir) exactly once.
    Returns (tokenizer, model) or (None, None) on failure.
    """
    global _bert_tokenizer, _bert_model
    if _bert_tokenizer is not None and _bert_model is not None:
        return _bert_tokenizer, _bert_model
    try:
        from transformers import AutoTokenizer, AutoModel
        local_dir = str(ModelConfig.DEP_TEXT_MODEL_DIR)
        print(f"[BERT] Loading DistilBERT from local dir {local_dir} (one-time)...", flush=True)
        tok = AutoTokenizer.from_pretrained(local_dir)
        mdl = AutoModel.from_pretrained(local_dir)
        mdl.eval()
        _bert_tokenizer = tok
        _bert_model = mdl
        print("[BERT] Cached.", flush=True)
        return _bert_tokenizer, _bert_model
    except Exception as e:
        print(f"[BERT] Load failed: {e}", flush=True)
        return None, None


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
        - Runs prediction in a subprocess to isolate potential segfaults
          from scikit-learn version mismatches (pickled with 1.6.1, running 1.7.2)
        - Majority vote for prediction + average probability for confidence
        Returns Flutter-friendly output: "Autism"/"Non-Autism"
        """
        import subprocess, sys, json as _json

        # Normalize input
        if isinstance(questionnaire_data, dict):
            answers = questionnaire_data.get("answers")
        else:
            answers = questionnaire_data

        if answers is None:
            raise ValueError("AQ-10 answers are required (expected key: 'answers').")

        if not isinstance(answers, (list, tuple)) or len(answers) != 10:
            raise ValueError("AQ-10 answers must be a list of length 10.")

        print(f"[ASD/text] Predicting for answers: {answers}", flush=True)

        # Collect available model paths
        model_paths: list[tuple[str, str]] = []
        for model_name in ["adaboost", "xgboost", "randomforest"]:
            model_path = config.get(model_name)
            if not model_path:
                continue
            if not os.path.exists(model_path):
                print(f"[ASD/text] WARNING: model file missing: {model_path}", flush=True)
                continue
            model_paths.append((model_name, model_path))

        if not model_paths:
            print("[ASD/text] Warning: No model files found. Using scoring fallback.", flush=True)
            return self._asd_text_score_fallback(answers)

        # Run prediction in a subprocess to isolate C-level segfaults
        # from sklearn version mismatches
        preds: list[int] = []
        probs: list[float] = []
        models_used: list[str] = []

        for model_name, model_path in model_paths:
            try:
                result = await self._run_sklearn_predict_subprocess(model_path, answers)
                if result is not None:
                    preds.append(result["prediction"])
                    probs.append(result["probability"])
                    models_used.append(model_name)
                    print(f"[ASD/text] {model_name}: pred={result['prediction']} prob={result['probability']:.3f}", flush=True)
                else:
                    print(f"[ASD/text] WARNING: {model_name} subprocess returned None", flush=True)
            except Exception as e:
                print(f"[ASD/text] WARNING: {model_name} subprocess failed: {e}", flush=True)
                continue

        if not preds:
            print("[ASD/text] All model subprocesses failed. Using scoring fallback.", flush=True)
            return self._asd_text_score_fallback(answers)

        final_prediction_int = 1 if sum(preds) >= (len(preds) / 2.0) else 0
        final_confidence = float(sum(probs) / len(probs))

        result = {
            "prediction": "Autism" if final_prediction_int == 1 else "Non-Autism",
            "confidence": round(final_confidence, 3),
            "models_used": models_used,
        }
        print(f"[ASD/text] Final Result: {result}", flush=True)
        return result

    def _asd_text_score_fallback(self, answers: list) -> Dict[str, Any]:
        """Scoring-based fallback when sklearn models can't be loaded/run."""
        total_score = sum(answers)
        is_autism = (total_score >= 6)
        prediction = "Autism" if is_autism else "Non-Autism"
        confidence = round(total_score / 10.0, 3)
        return {
            "prediction": prediction,
            "confidence": confidence,
            "threshold": 0.5,
            "details": {"note": "Score-based fallback (models unavailable)", "score": total_score},
            "models_used": []
        }

    async def _run_sklearn_predict_subprocess(self, model_path: str, answers: list) -> Optional[Dict[str, Any]]:
        """
        Run a single sklearn model prediction in an isolated subprocess.
        This prevents segfaults from crashing the main server process.
        """
        import asyncio

        # Python script that loads and runs the model in isolation
        script = f'''
import sys, json, joblib, numpy as np, warnings
warnings.filterwarnings("ignore")
try:
    model = joblib.load("{model_path}")
    X = np.array({answers}, dtype=np.float32).reshape(1, -1)
    pred = int(model.predict(X)[0])
    if hasattr(model, "predict_proba"):
        prob = float(model.predict_proba(X)[0][1])
    else:
        prob = float(pred)
    print(json.dumps({{"prediction": pred, "probability": prob}}))
except Exception as e:
    print(json.dumps({{"error": str(e)}}), file=sys.stderr)
    sys.exit(1)
'''
        try:
            import sys
            proc = await asyncio.create_subprocess_exec(
                sys.executable, "-c", script,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=30)

            if proc.returncode != 0:
                err_msg = stderr.decode().strip() if stderr else f"exit code {proc.returncode}"
                print(f"[ASD/text] Subprocess error for {os.path.basename(model_path)}: {err_msg}", flush=True)
                return None

            import json as _json
            output = stdout.decode().strip()
            if not output:
                return None
            return _json.loads(output)

        except asyncio.TimeoutError:
            print(f"[ASD/text] Subprocess timed out for {os.path.basename(model_path)}", flush=True)
            return None
        except Exception as e:
            print(f"[ASD/text] Subprocess exception for {os.path.basename(model_path)}: {e}", flush=True)
            return None

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
        try:
            # Optional TensorFlow/Keras Check
            try:
                from tensorflow import keras
                TF_AVAILABLE = True
            except ImportError:
                TF_AVAILABLE = False
                keras = None

            if not TF_AVAILABLE:
                return {
                    "prediction": "Non-Autism",
                    "confidence": 0.0,
                    "error": "TensorFlow is not available on this server.",
                    "is_fallback": True
                }

            print(f"Starting predict_asd_face for {image_url}...", flush=True)

            model_path = config.get("model_path")
            class_indices_path = config.get("class_indices")

            if not model_path or not class_indices_path:
                raise ValueError("ASD face_url config must include model_path (.h5) and class_indices (.json).")

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

            if not os.path.exists(model_path):
                return {
                    "prediction": "Non-Autism",
                    "confidence": 0.0,
                    "face_detected": True,
                    "error": f"Model file missing: {os.path.basename(model_path)}",
                    "is_fallback": True
                }

            print(f"Loading keras model from {model_path}...", flush=True)
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
            threshold = float(config.get("confidence_threshold", 0.5))
            autism_prob = pred_conf if predicted_class == "autistic" else (1.0 - pred_conf)
            label = "Autism" if autism_prob >= threshold else "Non-Autism"

            result = {
                "prediction": label,
                "confidence": round(float(autism_prob), 3),
                "face_detected": True,
                "faces_count": int(fx.get("faces_count", 1)),
                "bbox": fx.get("bbox"),
                "threshold": threshold,
                "class": predicted_class,
            }
            print(f"[ASD/face] Final Result: {result}", flush=True)
            return result
        except Exception as e:
            print(f"[Router] ASD face model fatal error: {e}", flush=True)
            return {
                "prediction": "Non-Autism",
                "confidence": 0.0,
                "error": f"Internal error: {str(e)}",
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
    # ADHD: Behavior (CatBoost) — DISABLED
    # The trained model expects 787 ACC__* tsfresh accelerometer features
    # but the app collects questionnaire answers. Inputs are unrelated to
    # the model's feature space, so predictions were identical for every user.
    # -----------------------------
    async def predict_adhd_behavior(self, features: Dict[str, Any]) -> Dict[str, Any]:
        print("[ADHD/behavior] DISABLED: feature-space mismatch with trained model")
        return {
            "prediction": 0,
            "confidence": 0.0,
            "unavailable": True,
            "details": {"reason": "behavior model disabled (feature-space mismatch)"},
        }

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
    @staticmethod
    def _heuristic_eye_confidence(eye_features: Dict[str, Any]) -> float:
        """
        Direct feature-based ADHD eye score.
        The trained sklearn model (v1.6.1) is incompatible with the current sklearn
        version and always outputs P(ADHD)=0.  We compute confidence directly from
        the extracted MediaPipe iris features instead.

        Reference ranges (natural face video, self-report):
          saccade_frequency:  0 (very still) → 1.5+ (restless)
          gaze_dispersion_deg: 0 → 2.0+
          blink_rate_per_min: 15 (low) → 60+ (high / stressed)
          eye_deviation:      0 → 0.30+
        """
        sf  = float(eye_features.get("saccade_frequency", 0.0))
        gd  = float(eye_features.get("gaze_dispersion_deg", 0.0))
        br  = float(eye_features.get("blink_rate_per_min", 20.0))
        ed  = float(eye_features.get("eye_deviation", 0.0))

        # If ALL movement features are zero, no face was reliably detected
        if sf == 0.0 and gd == 0.0 and ed == 0.0:
            return 0.0

        sf_score = min(1.0, sf  / 1.5)
        gd_score = min(1.0, gd  / 2.0)
        br_score = min(1.0, max(0.0, (br - 15.0) / 45.0))
        ed_score = min(1.0, ed  / 0.30)

        return round(sf_score * 0.40 + gd_score * 0.30 + br_score * 0.15 + ed_score * 0.15, 4)

    async def predict_adhd_eye_from_video(self, video_path: str) -> Dict[str, Any]:
        try:
            eye_features = await self.feature_extractor.extract_eye_features_from_path(video_path)
            proba = self._heuristic_eye_confidence(eye_features)
            pred  = int(proba >= 0.50)
            print(f"[ADHD/eye] proba={proba:.4f} pred={pred} (heuristic-iris)")
            return {"prediction": pred, "confidence": proba, "probability": proba, "eye_features": eye_features}
        except Exception as e:
            raise Exception(f"ADHD eye prediction failed: {e}")

    # -----------------------------
    # ADHD: Voice — DISABLED
    # voice_svm_model.pkl is an 8-class emotion classifier (classes_=[0..7]);
    # treating class index 1 as "P(ADHD)" is meaningless.
    # voice_cnn_model.h5 is a 132-byte Git LFS pointer (not a real model).
    # -----------------------------
    async def predict_adhd_voice_from_audio(self, audio_path: str) -> Dict[str, Any]:
        print("[ADHD/voice] DISABLED: SVM is an emotion model, CNN file is an LFS stub")
        return {
            "prediction": 0,
            "confidence": 0.0,
            "unavailable": True,
            "details": {"reason": "voice model disabled (emotion classifier, not ADHD)"},
        }

    async def _predict_adhd_voice_from_audio_DISABLED(self, audio_path: str) -> Dict[str, Any]:
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
        AU-variance fallback: sequence model missing → measure facial expressiveness
        directly from Action Unit variance across frames.

        High AU variance = more facial movement (hyperactivity proxy).
        Typical variance ranges (MediaPipe AU proxies, natural video):
          < 0.0005  → very still / no face detected
          0.001–0.003 → relaxed / low expressiveness
          0.003–0.008 → moderate
          > 0.008  → high expressiveness / restless
        """
        try:
            au_sequence = await self.feature_extractor.extract_facial_aus_sequence(video_path, max_frames=300)
            if not au_sequence:
                return {"prediction": 0, "confidence": 0.0, "details": {"error": "No face detected in video"}}

            au_arr = np.array(au_sequence, dtype=np.float32)
            mean_variance = float(np.var(au_arr, axis=0).mean())

            if mean_variance <= 0.0:
                return {"prediction": 0, "confidence": 0.0, "details": {"error": "No facial movement detected"}}

            # Log-scale mapping: log10 range [-4, -1.5] → confidence [0.05, 0.85]
            import math
            log_var = math.log10(mean_variance + 1e-10)
            normalized = (log_var - (-4.0)) / ((-1.5) - (-4.0))
            proba = round(max(0.05, min(0.85, normalized)), 4)

            pred = int(proba >= 0.50)
            print(f"[ADHD/facial] AU variance={mean_variance:.6f} proba={proba:.4f} pred={pred} (AU-variance fallback)")
            return {
                "prediction": pred,
                "confidence": proba,
                "au_mean_variance": mean_variance,
                "frames_analyzed": len(au_sequence),
                "is_fallback": True,
            }
        except Exception:
            return {"prediction": 0, "confidence": 0.0, "details": {"error": "Fallback failed"}}

    # =========================================================
    # DEPRESSION — TEXT + VISUAL (AU-variance) FUSION
    # The DAIC-WOZ SVM expects COVAREP/CLNF features we cannot extract,
    # so audio and video are NOT fed to the SVM. Instead:
    #   • Text   → BERT [CLS] → SVM → text_confidence   (weight 0.65)
    #   • Visual → AU variance from face video           (weight 0.35)
    # Final fused confidence = weighted average of available modalities.
    # =========================================================
    async def execute_depression_screening(
        self,
        video_path: Optional[str],
        questionnaire_data: Optional[Dict[str, Any]],
    ) -> Dict[str, Any]:
        import sys, math

        # ── 1. Text via BERT → SVM ──────────────────────────────────────────
        svm_dir = str(ModelConfig.DEPRESSION_SVM_DIR)
        if svm_dir not in sys.path:
            sys.path.append(svm_dir)

        text_confidence: Optional[float] = None
        modalities_used: List[str] = []
        unavailable_modalities: List[str] = []

        try:
            from inference import DepressionScreener
            model_path = os.path.join(svm_dir, "best_model.pkl")
            screener = DepressionScreener(model_path=model_path)
        except Exception as e:
            print(f"[Depression/SVM] Failed to load DepressionScreener: {e}")
            screener = None

        if screener and questionnaire_data:
            TEXT_DIM  = 768
            AUDIO_DIM = 296
            VIDEO_DIM = 560
            text_features  = np.zeros(TEXT_DIM,  dtype=np.float32)
            audio_features = np.zeros(AUDIO_DIM, dtype=np.float32)
            video_features = np.zeros(VIDEO_DIM, dtype=np.float32)

            text_answers = [
                questionnaire_data.get(f"depression_q_{i}_text", "")
                for i in range(8)
            ]
            combined_text = " ".join(t for t in text_answers if t).strip()

            if combined_text:
                tokenizer, bert_model = get_bert()
                if tokenizer is not None and bert_model is not None:
                    try:
                        import torch
                        tokens = tokenizer(
                            combined_text, return_tensors="pt",
                            max_length=512, truncation=True, padding=True,
                        )
                        with torch.no_grad():
                            out = bert_model(**tokens)
                        feat = out.last_hidden_state[:, 0, :].squeeze().numpy().astype(np.float32)
                        n = min(len(feat), TEXT_DIM)
                        text_features[:n] = feat[:n]
                        print("[Depression/Text] BERT extraction successful.", flush=True)

                        result = screener.predict(audio_features, video_features, text_features)
                        print(f"[Depression/SVM] Result: {result}", flush=True)
                        text_confidence = float(result.get("depression_probability", 0.0))
                        modalities_used.append("text")
                    except Exception as e:
                        print(f"[Depression/Text] BERT/SVM failed: {e}", flush=True)
                        unavailable_modalities.append("text")
                else:
                    unavailable_modalities.append("text")
            else:
                unavailable_modalities.append("text")

        # ── 2. Visual via AU variance ────────────────────────────────────────
        visual_confidence: Optional[float] = None
        if video_path and os.path.exists(video_path):
            try:
                au_sequence = await self.feature_extractor.extract_facial_aus_sequence(
                    video_path, max_frames=300
                )
                if au_sequence:
                    au_arr = np.array(au_sequence, dtype=np.float32)
                    mean_variance = float(np.var(au_arr, axis=0).mean())
                    if mean_variance > 0.0:
                        # Log-scale mapping: variance range [1e-4, ~0.03] → [0.05, 0.85]
                        log_var = math.log10(mean_variance + 1e-10)
                        normalized = (log_var - (-4.0)) / ((-1.5) - (-4.0))
                        visual_confidence = round(max(0.05, min(0.85, normalized)), 4)
                        modalities_used.append("visual")
                        print(f"[Depression/Visual] AU variance={mean_variance:.6f} conf={visual_confidence:.4f}", flush=True)
                    else:
                        unavailable_modalities.append("visual")
                else:
                    unavailable_modalities.append("visual")
            except Exception as e:
                print(f"[Depression/Visual] AU extraction failed: {e}", flush=True)
                unavailable_modalities.append("visual")
        else:
            unavailable_modalities.append("visual")

        # ── 3. Fuse ──────────────────────────────────────────────────────────
        if text_confidence is None and visual_confidence is None:
            return {
                "success": False,
                "condition": "depression",
                "detected_condition": None,
                "confidence": 0.0,
                "fused_result": {
                    "fused_prediction": 0,
                    "fused_confidence": 0.0,
                    "severity": "Low",
                    "message": "No modalities could be assessed.",
                },
                "individual_results": [],
                "modalities_used": [],
                "unavailable_modalities": unavailable_modalities,
            }

        TEXT_WEIGHT   = 0.65
        VISUAL_WEIGHT = 0.35

        if text_confidence is not None and visual_confidence is not None:
            fused_confidence = round(
                text_confidence * TEXT_WEIGHT + visual_confidence * VISUAL_WEIGHT, 4
            )
        elif text_confidence is not None:
            fused_confidence = round(text_confidence, 4)
        else:
            fused_confidence = round(visual_confidence, 4)  # type: ignore[arg-type]

        fused_confidence = min(0.95, fused_confidence)
        fused_prediction = 1 if fused_confidence >= 0.50 else 0

        sub_results: List[Dict[str, Any]] = []
        if text_confidence is not None:
            sub_results.append({
                "model_type": "text",
                "confidence": round(text_confidence, 4),
                "prediction": 1 if text_confidence >= 0.50 else 0,
            })
        if visual_confidence is not None:
            sub_results.append({
                "model_type": "visual",
                "confidence": round(visual_confidence, 4),
                "prediction": 1 if visual_confidence >= 0.50 else 0,
            })

        severity = "High" if fused_confidence >= 0.70 else ("Medium" if fused_confidence >= 0.50 else "Low")

        return {
            "success": True,
            "condition": "depression",
            "detected_condition": "Depression" if fused_prediction == 1 else None,
            "confidence": fused_confidence,
            "fused_result": {
                "fused_prediction": fused_prediction,
                "fused_confidence": fused_confidence,
                "severity": severity,
                "message": f"Depression screening completed ({', '.join(modalities_used)}).",
            },
            "individual_results": sub_results,
            "all_results": [],
            "modalities_used": modalities_used,
            "unavailable_modalities": unavailable_modalities,
        }

