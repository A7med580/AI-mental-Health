"""
FastAPI Backend Server for Mental Health Screening System
Handles model inference, feature extraction, and routing logic
"""

from typing import List, Optional, Dict, Any

import json
import uvicorn
from fastapi import FastAPI, File, UploadFile, HTTPException, Form, Body
from fastapi.middleware.cors import CORSMiddleware

from services.model_router import ModelRouter
from services.feature_extractor import FeatureExtractor
from services.adhd_fusion import ADHDFusion
from config.model_config import ModelConfig


app = FastAPI(title="Mental Health Screening API")

# CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
model_router = ModelRouter()
feature_extractor = FeatureExtractor()
model_config = ModelConfig()


@app.get("/")
async def root():
    return {"message": "Mental Health Screening API", "status": "running"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


@app.post("/extract-features")
async def extract_features(
    modality: str = Form(...),
    video_file: Optional[UploadFile] = File(None),
    audio_file: Optional[UploadFile] = File(None),
    text_data: Optional[str] = Form(None),
):
    """
    Extract features from different modalities.
    modality: video | audio | face | eye | text
    """
    try:
        if modality == "video" and video_file is not None:
            features = await feature_extractor.extract_from_video(video_file)
            return {"success": True, "features": features, "modality": modality}

        if modality == "audio" and audio_file is not None:
            features = await feature_extractor.extract_from_audio(audio_file)
            return {"success": True, "features": features, "modality": modality}

        if modality == "face" and video_file is not None:
            features = await feature_extractor.extract_face_features(video_file)
            return {"success": True, "features": features, "modality": modality}

        if modality == "eye" and video_file is not None:
            features = await feature_extractor.extract_eye_features(video_file)
            return {"success": True, "features": features, "modality": modality}

        if modality == "text" and text_data:
            features = await feature_extractor.extract_text_features(text_data)
            return {"success": True, "features": features, "modality": modality}

        raise HTTPException(status_code=400, detail="Invalid modality or missing required input")

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Feature extraction failed: {str(e)}")


@app.post("/run-screening")
async def run_screening(
    ranked_conditions: str = Form(...),
    available_modalities: str = Form(...),
    video_file: Optional[UploadFile] = File(None),
    audio_file: Optional[UploadFile] = File(None),
    questionnaire_data: Optional[str] = Form(None),
):
    """
    Main screening endpoint - routes to appropriate models based on ranked conditions.
    ranked_conditions & available_modalities are JSON strings.
    """
    try:
        ranked_conditions_list = json.loads(ranked_conditions)
        available_modalities_list = json.loads(available_modalities)

        questionnaire_dict = None
        if questionnaire_data:
            questionnaire_dict = json.loads(questionnaire_data)

        result = await model_router.execute_screening(
            ranked_conditions=ranked_conditions_list,
            available_modalities=available_modalities_list,
            video_file=video_file,
            audio_file=audio_file,
            questionnaire_data=questionnaire_dict,
        )

        return {"success": True, "result": result}

    except json.JSONDecodeError as e:
        raise HTTPException(status_code=400, detail=f"Invalid JSON in form fields: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Screening failed: {str(e)}")


# -------------------------
# ADHD Individual Predictors
# -------------------------

@app.post("/predict/adhd/behavior")
async def predict_adhd_behavior(features: Dict[str, Any] = Body(...)):
    """ADHD Behavior model prediction"""
    try:
        result = await model_router.predict_adhd_behavior(features)
        return {"success": True, "prediction": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/predict/adhd/eye")
async def predict_adhd_eye(features: Dict[str, Any] = Body(...)):
    """ADHD Eye-tracking model prediction"""
    try:
        result = await model_router.predict_adhd_eye(features)
        return {"success": True, "prediction": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/predict/adhd/voice")
async def predict_adhd_voice(audio_file: UploadFile = File(...)):
    """ADHD Voice model prediction"""
    try:
        result = await model_router.predict_adhd_voice(audio_file)
        return {"success": True, "prediction": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/predict/adhd/facial")
async def predict_adhd_facial(video_file: UploadFile = File(...)):
    """ADHD Facial expression model prediction"""
    try:
        result = await model_router.predict_adhd_facial(video_file)
        return {"success": True, "prediction": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# -------------------------
# ADHD Full Screening + Fusion
# -------------------------

@app.post("/screening/adhd")
async def screen_adhd(
    video_file: Optional[UploadFile] = File(None),
    audio_file: Optional[UploadFile] = File(None),
    questionnaire_data: Optional[str] = Form(None),
):
    """
    ADHD-specific screening endpoint that runs all available ADHD models and fuses their results.
    """
    try:
        questionnaire_dict = None
        if questionnaire_data:
            questionnaire_dict = json.loads(questionnaire_data)

        available_modalities: List[str] = []
        if questionnaire_dict:
            available_modalities.append("questionnaire")
        if video_file is not None:
            available_modalities.append("video")
        if audio_file is not None:
            available_modalities.append("audio")

        adhd_configs = model_config.get_model_config("ADHD")
        model_results: List[Dict[str, Any]] = []

        for model_type, config in adhd_configs.items():
            required_modalities = config.get("required_modalities", [])
            if not all(mod in available_modalities for mod in required_modalities):
                continue

            try:
                prediction_payload = None
                input_type = config.get("input_type")

                if input_type == "features_dict" and questionnaire_dict:
                    pred_result = await model_router.predict_adhd_behavior(questionnaire_dict)
                    prediction_payload = {
                        "model_type": "behavior",
                        "confidence": float(pred_result.get("confidence", 0.0)),
                        "prediction": pred_result.get("prediction", 0),
                        "details": pred_result,
                    }

                elif input_type == "eye_features" and video_file is not None:
                    eye_features = await feature_extractor.extract_eye_features(video_file)
                    pred_result = await model_router.predict_adhd_eye(eye_features)
                    prediction_payload = {
                        "model_type": "eye",
                        "confidence": float(pred_result.get("confidence", 0.0)),
                        "prediction": pred_result.get("prediction", 0),
                        "details": pred_result,
                    }

                elif input_type == "audio_file" and audio_file is not None:
                    # keep config param if your router expects it
                    pred_result = await model_router.predict_adhd_voice(audio_file, config)
                    prediction_payload = {
                        "model_type": "voice",
                        "confidence": float(pred_result.get("confidence", 0.0)),
                        "prediction": pred_result.get("prediction", 0),
                        "details": pred_result,
                    }

                elif input_type == "video_file" and video_file is not None:
                    if model_type == "facial":
                        pred_result = await model_router.predict_adhd_facial(video_file, config)
                        prediction_payload = {
                            "model_type": "facial",
                            "confidence": float(pred_result.get("confidence", 0.0)),
                            "prediction": pred_result.get("prediction", 0),
                            "details": pred_result,
                        }
                    elif model_type == "eye":
                        eye_features = await feature_extractor.extract_eye_features(video_file)
                        pred_result = await model_router.predict_adhd_eye(eye_features)
                        prediction_payload = {
                            "model_type": "eye",
                            "confidence": float(pred_result.get("confidence", 0.0)),
                            "prediction": pred_result.get("prediction", 0),
                            "details": pred_result,
                        }

                if prediction_payload:
                    model_results.append(
                        {
                            "model_type": model_type,
                            "confidence": prediction_payload["confidence"],
                            "prediction": prediction_payload["prediction"],
                            "details": prediction_payload["details"],
                        }
                    )

            except Exception as e:
                # don't crash full screening if one submodel fails
                print(f"Error executing ADHD/{model_type}: {str(e)}")
                continue

        fused_result = ADHDFusion.fuse_adhd_results(model_results)

        return {
            "success": True,
            "condition": "ADHD",
            "fused_result": fused_result,
            "individual_results": model_results,
            "modalities_used": available_modalities,
        }

    except json.JSONDecodeError as e:
        raise HTTPException(status_code=400, detail=f"Invalid questionnaire JSON: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"ADHD screening failed: {str(e)}")


# -------------------------
# Other predictors
# -------------------------

@app.post("/predict/anxiety")
async def predict_anxiety(features: Dict[str, Any] = Body(...)):
    """Anxiety model prediction"""
    try:
        result = await model_router.predict_anxiety(features)
        return {"success": True, "prediction": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/predict/asd/face")
async def predict_asd_face(video_file: UploadFile = File(...)):
    """ASD Face model prediction"""
    try:
        result = await model_router.predict_asd_face(video_file)
        return {"success": True, "prediction": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/predict/asd/text")
async def predict_asd_text(aq10_scores: List[int] = Body(...)):
    """ASD Text model prediction (AQ-10 scores)"""
    try:
        result = await model_router.predict_asd_text(aq10_scores)
        return {"success": True, "prediction": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)