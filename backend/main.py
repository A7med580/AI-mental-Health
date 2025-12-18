"""
FastAPI Backend Server for Mental Health Screening System
Handles model inference, feature extraction, and routing logic
"""

from typing import List, Optional, Dict, Any
import json
import os
import uuid
import asyncio
import shutil
from datetime import datetime

import uvicorn
from fastapi import FastAPI, File, UploadFile, HTTPException, Form, Body, BackgroundTasks
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

# Job store (in-memory for development)
# In production, use Redis, database, or similar
job_store: Dict[str, Dict[str, Any]] = {}
UPLOAD_DIR = "uploads"
RESULTS_DIR = "results"

# Create directories if they don't exist
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(RESULTS_DIR, exist_ok=True)


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


# -------------------------
# Job Management Endpoints
# -------------------------

async def process_adhd_job(job_id: str, video_path: str, questionnaire_data: Dict[str, Any]):
    """Background task to process ADHD screening job"""
    try:
        # Update job status to processing
        job_store[job_id]["status"] = "processing"
        job_store[job_id]["updated_at"] = datetime.now().isoformat()

        # Read video file and create UploadFile-like object
        video_file_handle = open(video_path, "rb")
        video_upload = UploadFile(file=video_file_handle, filename=os.path.basename(video_path))

        # Run ADHD screening (reuse existing logic)
        available_modalities: List[str] = []
        if questionnaire_data:
            available_modalities.append("questionnaire")
        available_modalities.append("video")  # Video is always available in this context

        adhd_configs = model_config.get_model_config("ADHD")
        model_results: List[Dict[str, Any]] = []

        for model_type, config in adhd_configs.items():
            required_modalities = config.get("required_modalities", [])
            if not all(mod in available_modalities for mod in required_modalities):
                continue

            try:
                prediction_payload = None
                input_type = config.get("input_type")

                if input_type == "features_dict" and questionnaire_data:
                    pred_result = await model_router.predict_adhd_behavior(questionnaire_data)
                    prediction_payload = {
                        "model_type": "behavior",
                        "confidence": float(pred_result.get("confidence", 0.0)),
                        "prediction": pred_result.get("prediction", 0),
                        "details": pred_result,
                    }

                elif input_type == "eye_features":
                    # Reset file pointer
                    video_file_handle.seek(0)
                    video_upload.file.seek(0)
                    eye_features = await feature_extractor.extract_eye_features(video_upload)
                    pred_result = await model_router.predict_adhd_eye(eye_features)
                    prediction_payload = {
                        "model_type": "eye",
                        "confidence": float(pred_result.get("confidence", 0.0)),
                        "prediction": pred_result.get("prediction", 0),
                        "details": pred_result,
                    }

                elif input_type == "video_file":
                    # Reset file pointer
                    video_file_handle.seek(0)
                    video_upload.file.seek(0)
                    if model_type == "facial":
                        pred_result = await model_router.predict_adhd_facial(video_upload, config)
                        prediction_payload = {
                            "model_type": "facial",
                            "confidence": float(pred_result.get("confidence", 0.0)),
                            "prediction": pred_result.get("prediction", 0),
                            "details": pred_result,
                        }
                    elif model_type == "eye":
                        video_file_handle.seek(0)
                        video_upload.file.seek(0)
                        eye_features = await feature_extractor.extract_eye_features(video_upload)
                        pred_result = await model_router.predict_adhd_eye(eye_features)
                        prediction_payload = {
                            "model_type": "eye",
                            "confidence": float(pred_result.get("confidence", 0.0)),
                            "prediction": pred_result.get("prediction", 0),
                            "details": pred_result,
                        }

                if prediction_payload:
                    model_results.append({
                        "model_type": model_type,
                        "confidence": prediction_payload["confidence"],
                        "prediction": prediction_payload["prediction"],
                        "details": prediction_payload["details"],
                    })

            except Exception as e:
                print(f"Error executing ADHD/{model_type}: {str(e)}")
                continue

        # Fuse results
        fused_result = ADHDFusion.fuse_adhd_results(model_results)

        # Prepare final result
        result = {
            "success": True,
            "condition": "ADHD",
            "fused_result": fused_result,
            "individual_results": model_results,
            "modalities_used": available_modalities,
            "is_adhd": fused_result.get("fused_prediction", 0) == 1,
            "confidence": fused_result.get("fused_confidence", 0.0),
            "summary": fused_result.get("explanation", ""),
        }

        # Save result
        result_path = os.path.join(RESULTS_DIR, f"{job_id}.json")
        with open(result_path, "w") as f:
            json.dump(result, f, indent=2)

        # Update job store
        job_store[job_id]["status"] = "done"
        job_store[job_id]["result_path"] = result_path
        job_store[job_id]["updated_at"] = datetime.now().isoformat()

        # Delete raw video file (privacy)
        try:
            os.remove(video_path)
            print(f"Deleted raw video file: {video_path}")
        except Exception as e:
            print(f"Warning: Could not delete video file: {e}")

        # Close file
        video_file_handle.close()

    except Exception as e:
        print(f"Error processing job {job_id}: {str(e)}")
        job_store[job_id]["status"] = "failed"
        job_store[job_id]["error"] = str(e)
        job_store[job_id]["updated_at"] = datetime.now().isoformat()
        if "video_file_handle" in locals():
            video_file_handle.close()


@app.post("/jobs/adhd")
async def submit_adhd_job(
    background_tasks: BackgroundTasks,
    video_file: UploadFile = File(...),
    questionnaire_data: Optional[str] = Form(None),
):
    """
    Submit an ADHD screening job for async processing.
    Returns job_id immediately, processing happens in background.
    """
    try:
        # Generate job ID
        job_id = str(uuid.uuid4())

        # Parse questionnaire data
        questionnaire_dict = None
        if questionnaire_data:
            questionnaire_dict = json.loads(questionnaire_data)

        # Save uploaded video
        video_filename = f"{job_id}_{video_file.filename}"
        video_path = os.path.join(UPLOAD_DIR, video_filename)
        
        with open(video_path, "wb") as f:
            shutil.copyfileobj(video_file.file, f)

        # Create job entry
        job_store[job_id] = {
            "job_id": job_id,
            "status": "queued",
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "video_path": video_path,
        }

        # Start background task
        background_tasks.add_task(
            process_adhd_job,
            job_id,
            video_path,
            questionnaire_dict or {},
        )

        return {
            "job_id": job_id,
            "status": "queued",
            "message": "Job submitted successfully. Use GET /jobs/{job_id} to check status.",
        }

    except json.JSONDecodeError as e:
        raise HTTPException(status_code=400, detail=f"Invalid questionnaire JSON: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to submit job: {str(e)}")


@app.get("/jobs/{job_id}")
async def get_job_status(job_id: str):
    """Get the status of a job"""
    if job_id not in job_store:
        raise HTTPException(status_code=404, detail="Job not found")

    job = job_store[job_id]
    return {
        "job_id": job_id,
        "status": job["status"],
        "created_at": job["created_at"],
        "updated_at": job["updated_at"],
        "error": job.get("error"),
    }


@app.get("/jobs/{job_id}/result")
async def get_job_result(job_id: str):
    """Get the result of a completed job"""
    if job_id not in job_store:
        raise HTTPException(status_code=404, detail="Job not found")

    job = job_store[job_id]

    if job["status"] != "done":
        raise HTTPException(
            status_code=400,
            detail=f"Job is not done yet. Current status: {job['status']}",
        )

    result_path = job.get("result_path")
    if not result_path or not os.path.exists(result_path):
        raise HTTPException(status_code=404, detail="Result file not found")

    with open(result_path, "r") as f:
        result = json.load(f)

    return result


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)