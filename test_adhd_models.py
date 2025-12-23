"""
Standalone script to test ADHD models with a video file
Usage: python test_adhd_models.py <path_to_video_file>
"""

import sys
import os
from pathlib import Path
import numpy as np
import pandas as pd
import cv2
import joblib
import json

# Add backend directory to path
sys.path.insert(0, str(Path(__file__).parent / "backend"))

from backend.services.model_loader import ModelLoader
from backend.services.feature_extractor import FeatureExtractor
from backend.config.model_config import ModelConfig

# Try to import TensorFlow
try:
    import tensorflow as tf
    from tensorflow import keras
    TF_AVAILABLE = True
except ImportError:
    TF_AVAILABLE = False
    print("Warning: TensorFlow not available. Facial model will not work.")


def test_adhd_behavior_model(questionnaire_data=None):
    """Test ADHD Behavior Model (requires questionnaire data)"""
    print("\n" + "="*60)
    print("TESTING ADHD BEHAVIOR MODEL")
    print("="*60)
    
    if questionnaire_data is None:
        print("⚠️  Behavior model requires questionnaire data")
        print("   Skipping behavior model...")
        return None
    
    try:
        config = ModelConfig()
        model_loader = ModelLoader()
        
        # Load model and feature names
        model_path = config.ADHD_BEHAVIOR_MODEL
        features_path = config.ADHD_BEHAVIOR_FEATURES
        
        print(f"Loading model from: {model_path}")
        model = model_loader.load_model(model_path)
        feature_names = model_loader.load_json(features_path)
        
        print(f"Model expects {len(feature_names)} features")
        print(f"Feature names: {feature_names[:10]}...")  # Show first 10
        
        # Build feature vector
        feature_vector = []
        for feat_name in feature_names:
            feature_vector.append(questionnaire_data.get(feat_name, 0.0))
        
        feature_array = np.array(feature_vector).reshape(1, -1)
        
        # Predict
        proba = model.predict_proba(feature_array)[0, 1]
        pred = int(model.predict(feature_array)[0])
        
        result = {
            "model_type": "behavior",
            "prediction": pred,
            "confidence": float(proba),
            "probability": float(proba)
        }
        
        print(f"✅ Result: Prediction={pred}, Confidence={proba:.3f}")
        return result
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return None


def test_adhd_eye_model(video_path):
    """Test ADHD Eye-Tracking Model"""
    print("\n" + "="*60)
    print("TESTING ADHD EYE MODEL")
    print("="*60)
    
    try:
        config = ModelConfig()
        model_loader = ModelLoader()
        feature_extractor = FeatureExtractor()
        
        model_path = config.ADHD_EYE_MODEL
        print(f"Loading model from: {model_path}")
        
        model_bundle = model_loader.load_model(model_path)
        
        # Extract eye features from video
        print(f"Extracting eye features from: {video_path}")
        
        # Create a mock UploadFile-like object
        class MockUploadFile:
            def __init__(self, path):
                self.path = path
                self.filename = os.path.basename(path)
        
        mock_video = MockUploadFile(video_path)
        
        # Extract eye features (this is async in the real code, but we'll call it directly)
        # Note: This is a simplified version - the real extractor uses async
        eye_features = feature_extractor._extract_eye_from_frames(
            feature_extractor._extract_frames(video_path)
        )
        
        print(f"Extracted eye features: {list(eye_features.keys())}")
        
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
        
        result = {
            "model_type": "eye",
            "prediction": pred,
            "confidence": float(proba),
            "probability": float(proba),
            "features_used": eye_features
        }
        
        print(f"✅ Result: Prediction={pred}, Confidence={proba:.3f}")
        return result
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return None


def test_adhd_voice_model(audio_path=None):
    """Test ADHD Voice Model (requires audio file)"""
    print("\n" + "="*60)
    print("TESTING ADHD VOICE MODEL")
    print("="*60)
    
    if audio_path is None:
        print("⚠️  Voice model requires audio file")
        print("   Skipping voice model...")
        return None
    
    try:
        config = ModelConfig()
        model_loader = ModelLoader()
        feature_extractor = FeatureExtractor()
        
        print(f"Loading models from: {config.ADHD_MODELS_DIR}")
        
        # Load models
        cnn_model = model_loader.load_model(config.ADHD_VOICE_CNN, "keras")
        svm_model = model_loader.load_model(config.ADHD_VOICE_SVM)
        scaler = model_loader.load_model(config.ADHD_VOICE_SCALER)
        
        print("Extracting audio features...")
        
        # Extract audio features
        audio_features = feature_extractor._extract_audio_features(audio_path)
        
        if "error" in audio_features:
            raise Exception(audio_features["error"])
        
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
        
        result = {
            "model_type": "voice",
            "prediction": int(avg_confidence >= 0.5),
            "confidence": avg_confidence,
            "svm_prediction": int(svm_pred),
            "cnn_prediction": cnn_pred,
            "cnn_probability": float(cnn_proba[1])
        }
        
        print(f"✅ Result: Prediction={result['prediction']}, Confidence={avg_confidence:.3f}")
        print(f"   SVM: {svm_pred}, CNN: {cnn_proba[1]:.3f}")
        return result
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return None


def test_adhd_facial_model(video_path):
    """Test ADHD Facial Expression Model"""
    print("\n" + "="*60)
    print("TESTING ADHD FACIAL MODEL")
    print("="*60)
    
    if not TF_AVAILABLE:
        print("⚠️  TensorFlow not available")
        print("   Skipping facial model...")
        return None
    
    try:
        config = ModelConfig()
        model_loader = ModelLoader()
        feature_extractor = FeatureExtractor()
        
        model_path = config.ADHD_FACIAL_MODEL
        print(f"Loading model from: {model_path}")
        
        model = model_loader.load_model(model_path, "keras")
        
        # Extract face features from video
        print(f"Extracting face features from: {video_path}")
        
        frames = feature_extractor._extract_frames(video_path)
        face_features = feature_extractor._extract_face_from_frames(frames)
        
        if not face_features.get("face_frames"):
            raise Exception("No faces detected in video")
        
        # Use first face frame
        face_frame = face_features["face_frames"][0]
        
        # Preprocess for ResNet50
        face_frame_rgb = cv2.cvtColor(face_frame, cv2.COLOR_BGR2RGB)
        face_frame_resized = cv2.resize(face_frame_rgb, (224, 224))
        face_array = np.expand_dims(face_frame_resized / 255.0, axis=0)
        
        print(f"Face array shape: {face_array.shape}")
        
        # Predict
        predictions = model.predict(face_array, verbose=0)[0]
        max_prob = float(np.max(predictions))
        
        # Map to ADHD probability (simplified - would need proper mapping)
        adhd_probability = max_prob * 0.7  # Scale down as this is emotion, not direct ADHD
        
        result = {
            "model_type": "facial",
            "prediction": int(adhd_probability >= 0.5),
            "confidence": adhd_probability,
            "emotion_probabilities": predictions.tolist(),
            "max_emotion_prob": max_prob
        }
        
        print(f"✅ Result: Prediction={result['prediction']}, Confidence={adhd_probability:.3f}")
        print(f"   Max emotion probability: {max_prob:.3f}")
        return result
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return None


def main():
    """Main function to test all ADHD models"""
    
    if len(sys.argv) < 2:
        print("Usage: python test_adhd_models.py <video_file_path> [audio_file_path] [questionnaire_json]")
        print("\nExample:")
        print("  python test_adhd_models.py video.mp4")
        print("  python test_adhd_models.py video.mp4 audio.wav")
        print("  python test_adhd_models.py video.mp4 audio.wav '{\"ACC\":1,\"HRV\":1}'")
        sys.exit(1)
    
    video_path = sys.argv[1]
    audio_path = sys.argv[2] if len(sys.argv) > 2 else None
    questionnaire_json = sys.argv[3] if len(sys.argv) > 3 else None
    
    # Check if video file exists
    if not os.path.exists(video_path):
        print(f"❌ Error: Video file not found: {video_path}")
        sys.exit(1)
    
    print("="*60)
    print("ADHD MODELS TESTING")
    print("="*60)
    print(f"Video file: {video_path}")
    if audio_path:
        print(f"Audio file: {audio_path}")
    if questionnaire_json:
        print(f"Questionnaire data: {questionnaire_json}")
    print("="*60)
    
    # Parse questionnaire data if provided
    questionnaire_data = None
    if questionnaire_json:
        try:
            questionnaire_data = json.loads(questionnaire_json)
        except json.JSONDecodeError:
            print("⚠️  Invalid JSON for questionnaire data, ignoring...")
    
    # Test each model
    results = {}
    
    # 1. Behavior Model (requires questionnaire)
    if questionnaire_data:
        results['behavior'] = test_adhd_behavior_model(questionnaire_data)
    else:
        print("\n⚠️  Skipping behavior model (no questionnaire data)")
    
    # 2. Eye Model (requires video)
    results['eye'] = test_adhd_eye_model(video_path)
    
    # 3. Voice Model (requires audio)
    if audio_path and os.path.exists(audio_path):
        results['voice'] = test_adhd_voice_model(audio_path)
    else:
        print("\n⚠️  Skipping voice model (no audio file)")
    
    # 4. Facial Model (requires video)
    results['facial'] = test_adhd_facial_model(video_path)
    
    # Summary
    print("\n" + "="*60)
    print("SUMMARY OF RESULTS")
    print("="*60)
    
    for model_type, result in results.items():
        if result:
            print(f"{model_type.upper():12} | Prediction: {result['prediction']} | Confidence: {result['confidence']:.3f}")
        else:
            print(f"{model_type.upper():12} | Not available")
    
    # Calculate simple average if multiple models ran
    available_results = [r for r in results.values() if r is not None]
    if len(available_results) > 1:
        avg_confidence = sum(r['confidence'] for r in available_results) / len(available_results)
        print(f"\nAverage Confidence: {avg_confidence:.3f}")
    
    print("="*60)
    
    # Return results as JSON
    return results


if __name__ == "__main__":
    results = main()
    
    # Optionally save results to JSON
    import json
    output_file = "adhd_test_results.json"
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2, default=str)
    print(f"\nResults saved to: {output_file}")

