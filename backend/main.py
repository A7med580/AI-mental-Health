"""
FastAPI Backend Server for Mental Health Screening System
Handles model inference, feature extraction, and routing logic
"""

from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Optional, Dict, Any
import uvicorn
import json

from services.model_router import ModelRouter
from services.feature_extractor import FeatureExtractor
from config.model_config import ModelConfig

app = FastAPI(title="Mental Health Screening API")

# CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
model_router = ModelRouter()
feature_extractor = FeatureExtractor()
model_config = ModelConfig()


# ScreeningRequest removed - using form data instead


class FeatureExtractionRequest(BaseModel):
    """Request for feature extraction"""
    modality: str  # "video", "audio", "face", "eye"
    data: Optional[Any] = None


@app.get("/")
async def root():
    return {"message": "Mental Health Screening API", "status": "running"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


@app.post("/extract-features")
async def extract_features(
    modality: str,
    video_file: Optional[UploadFile] = File(None),
    audio_file: Optional[UploadFile] = File(None),
    text_data: Optional[str] = None
):
    """
    Extract features from different modalities
    """
    try:
        if modality == "video" and video_file:
            features = await feature_extractor.extract_from_video(video_file)
            return {"success": True, "features": features, "modality": modality}
        
        elif modality == "audio" and audio_file:
            features = await feature_extractor.extract_from_audio(audio_file)
            return {"success": True, "features": features, "modality": modality}
        
        elif modality == "face" and video_file:
            features = await feature_extractor.extract_face_features(video_file)
            return {"success": True, "features": features, "modality": modality}
        
        elif modality == "eye" and video_file:
            features = await feature_extractor.extract_eye_features(video_file)
            return {"success": True, "features": features, "modality": modality}
        
        elif modality == "text" and text_data:
            features = await feature_extractor.extract_text_features(text_data)
            return {"success": True, "features": features, "modality": modality}
        
        else:
            raise HTTPException(status_code=400, detail="Invalid modality or missing file")
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Feature extraction failed: {str(e)}")


@app.post("/run-screening")
async def run_screening(
    ranked_conditions: str = Form(...),
    available_modalities: str = Form(...),
    video_file: Optional[UploadFile] = File(None),
    audio_file: Optional[UploadFile] = File(None),
    questionnaire_data: Optional[str] = Form(None)
):
    """
    Main screening endpoint - routes to appropriate models based on ranked conditions
    """
    try:
        # Parse JSON strings
        ranked_conditions_list = json.loads(ranked_conditions)
        available_modalities_list = json.loads(available_modalities)
        
        # Parse questionnaire data if provided
        questionnaire_dict = None
        if questionnaire_data:
            questionnaire_dict = json.loads(questionnaire_data)
        
        result = await model_router.execute_screening(
            ranked_conditions=ranked_conditions_list,
            available_modalities=available_modalities_list,
            video_file=video_file,
            audio_file=audio_file,
            questionnaire_data=questionnaire_dict
        )
        return {"success": True, "result": result}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Screening failed: {str(e)}")


@app.post("/predict/adhd/behavior")
async def predict_adhd_behavior(features: Dict[str, Any]):
    """ADHD Behavior model prediction"""
    try:
        result = await model_router.predict_adhd_behavior(features)
        return {"success": True, "prediction": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/predict/adhd/eye")
async def predict_adhd_eye(features: Dict[str, Any]):
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


@app.post("/predict/anxiety")
async def predict_anxiety(features: Dict[str, Any]):
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
async def predict_asd_text(aq10_scores: List[int]):
    """ASD Text model prediction (AQ-10 scores)"""
    try:
        result = await model_router.predict_asd_text(aq10_scores)
        return {"success": True, "prediction": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)

