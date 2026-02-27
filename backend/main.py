"""
FastAPI Backend Server for Mental Health Screening System
Handles model inference, feature extraction, and routing logic
(Updated: startup warmup + stable ADHD screening using ModelRouter path-based flow)
"""

from typing import List, Optional, Dict, Any
import json
import os
import uuid
import shutil
from datetime import datetime
import asyncio
import subprocess
import tempfile


import uvicorn
from fastapi import FastAPI, File, UploadFile, HTTPException, Form, Body, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware

from services.model_router import ModelRouter
from services.feature_extractor import FeatureExtractor
from services.adhd_fusion import ADHDFusion
from services.model_loader import ModelLoader
from config.model_config import ModelConfig
from pydantic import BaseModel, Field, HttpUrl

# -------------------------
# Request models (contracts)
# -------------------------

class ASDTextRequest(BaseModel):
    answers: List[int] = Field(..., min_length=10, max_length=10)


class ASDFaceUrlRequest(BaseModel):
    image_url: HttpUrl


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
model_loader = ModelLoader()
model_config = ModelConfig()
feature_extractor = FeatureExtractor()
model_router = ModelRouter()  # will warm-load ADHD bundle internally

# Job store (in-memory for development)
job_store: Dict[str, Dict[str, Any]] = {}
UPLOAD_DIR = "uploads"
RESULTS_DIR = "results"

os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(RESULTS_DIR, exist_ok=True)


@app.on_event("startup")
async def startup_event():
    """
    Warmup: load ADHD bundle once so first request isn't slow and no silent fallbacks.
    DISABLED: Causes TensorFlow mutex lock on macOS. Models will lazy-load on first request.
    """
    print("[Startup] Skipping ADHD model warm-load to avoid TensorFlow mutex lock.")
    print("[Startup] Models will load on first inference request.")
    # try:
    #     _ = model_loader.load_adhd_bundle()
    #     print("[Startup] ADHD models loaded successfully.")
    # except Exception as e:
    #     print(f"[Startup] WARNING: Could not load ADHD models: {e}")


@app.get("/")
async def root():
    return {"message": "Mental Health Screening API", "status": "running"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


# -------------------------
# Feature Extraction
# -------------------------
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


# -------------------------
# General Screening (ranked)
# -------------------------
@app.post("/run-screening")
async def run_screening(
    ranked_conditions: str = Form(...),
    available_modalities: str = Form(...),
    video_file: Optional[UploadFile] = File(None),
    audio_file: Optional[UploadFile] = File(None),
    questionnaire_data: Optional[str] = Form(None),
):
    """
    ranked_conditions & available_modalities are JSON strings.
    """
    try:
        ranked_conditions_list = json.loads(ranked_conditions)
        available_modalities_list = json.loads(available_modalities)

        questionnaire_dict = json.loads(questionnaire_data) if questionnaire_data else None

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
# ASD - REQUIRED PIPELINE ENDPOINTS
# -------------------------

@app.post("/asd/text/predict")
async def asd_text_predict(payload: ASDTextRequest):
    """
    AQ-10 answers -> ASD Text model -> Autism / Non-Autism
    """
    try:
        config = model_config.get_model_config("ASD", "text")
        if not config:
            raise HTTPException(status_code=500, detail="ASD text model config not found")

        result = await model_router.predict_asd_text({"answers": payload.answers}, config)
        return {"success": True, "prediction": result}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/asd/face/predict-url")
async def asd_face_predict_url(payload: ASDFaceUrlRequest):
    """
    image_url -> face crop (224x224) -> ASD Face TF model (.h5) -> Autism/Non-Autism + confidence
    """
    try:
        config = model_config.get_model_config("ASD", "face_url")
        if not config:
            raise HTTPException(status_code=500, detail="ASD face_url config not found")

        # Run synchronous TF prediction in a thread so it doesn't block the event loop
        import asyncio
        result = await asyncio.to_thread(
            model_router.predict_asd_face_from_image_url_tf,
            str(payload.image_url),
            config,
        )
        return {"success": True, "prediction": result}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# -------------------------
# ADHD Individual Predictors (Updated signatures)
# -------------------------
@app.post("/predict/adhd/behavior")
async def predict_adhd_behavior(features: Dict[str, Any] = Body(...)):
    try:
        result = await model_router.predict_adhd_behavior(features)
        return {"success": True, "prediction": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/predict/adhd/eye")
async def predict_adhd_eye(video_file: UploadFile = File(...)):
    """
    Updated: Eye model needs video to extract eye features
    """
    try:
        # Save and route via path-based API
        import tempfile
        tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".mp4")
        tmp_path = tmp.name
        tmp.close()

        await video_file.seek(0)
        with open(tmp_path, "wb") as f:
            shutil.copyfileobj(video_file.file, f)
        await video_file.seek(0)

        result = await model_router.predict_adhd_eye_from_video(tmp_path)
        try:
            os.remove(tmp_path)
        except Exception:
            pass

        return {"success": True, "prediction": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/predict/adhd/voice")
async def predict_adhd_voice(audio_file: UploadFile = File(...)):
    """
    Updated: Voice model needs audio file; run via path-based API
    """
    try:
        import tempfile
        tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".wav")
        tmp_path = tmp.name
        tmp.close()

        await audio_file.seek(0)
        with open(tmp_path, "wb") as f:
            shutil.copyfileobj(audio_file.file, f)
        await audio_file.seek(0)

        result = await model_router.predict_adhd_voice_from_audio(tmp_path)
        try:
            os.remove(tmp_path)
        except Exception:
            pass

        return {"success": True, "prediction": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/predict/adhd/facial")
async def predict_adhd_facial(video_file: UploadFile = File(...)):
    """
    Updated: Facial model needs video file; run via path-based API
    """
    try:
        import tempfile
        tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".mp4")
        tmp_path = tmp.name
        tmp.close()

        await video_file.seek(0)
        with open(tmp_path, "wb") as f:
            shutil.copyfileobj(video_file.file, f)
        await video_file.seek(0)

        result = await model_router.predict_adhd_facial_from_video(tmp_path)
        try:
            os.remove(tmp_path)
        except Exception:
            pass

        return {"success": True, "prediction": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# -------------------------
# ADHD Full Screening + Fusion (UPDATED: stable paths + no repeated reads)
# -------------------------
@app.post("/screening/adhd")
async def screen_adhd(
    video_file: Optional[UploadFile] = File(None),
    audio_file: Optional[UploadFile] = File(None),
    questionnaire_data: Optional[str] = Form(None),
):
    """
    Runs behavior + eye + voice + facial if available and fuses results.
    Uses stable temp paths to avoid 'same result' due to empty streams.
    """
    try:
        questionnaire_dict = json.loads(questionnaire_data) if questionnaire_data else None

        available_modalities: List[str] = []
        if questionnaire_dict:
            available_modalities.append("questionnaire")
        if video_file is not None:
            available_modalities.append("video")
        if audio_file is not None:
            available_modalities.append("audio")

        # Save files once
        import tempfile
        video_path = None
        audio_path = None

        try:
            if video_file is not None:
                vf = tempfile.NamedTemporaryFile(delete=False, suffix=".mp4")
                video_path = vf.name
                vf.close()
                await video_file.seek(0)
                with open(video_path, "wb") as f:
                    shutil.copyfileobj(video_file.file, f)
                await video_file.seek(0)

            if audio_file is not None:
                af = tempfile.NamedTemporaryFile(delete=False, suffix=".wav")
                audio_path = af.name
                af.close()
                await audio_file.seek(0)
                with open(audio_path, "wb") as f:
                    shutil.copyfileobj(audio_file.file, f)
                await audio_file.seek(0)

            adhd_configs = model_config.get_model_config("ADHD")
            model_results: List[Dict[str, Any]] = []

            for model_type, cfg in adhd_configs.items():
                required_modalities = cfg.get("required_modalities", [])
                if not all(mod in available_modalities for mod in required_modalities):
                    continue

                try:
                    if model_type == "behavior" and questionnaire_dict:
                        r = await model_router.predict_adhd_behavior(questionnaire_dict)
                        model_results.append({
                            "model_type": "behavior",
                            "confidence": float(r.get("confidence", 0.0)),
                            "prediction": int(r.get("prediction", 0)),
                            "details": r,
                        })

                    elif model_type == "eye" and video_path:
                        r = await model_router.predict_adhd_eye_from_video(video_path)
                        model_results.append({
                            "model_type": "eye",
                            "confidence": float(r.get("confidence", 0.0)),
                            "prediction": int(r.get("prediction", 0)),
                            "details": r,
                        })

                    elif model_type == "voice" and audio_path:
                        r = await model_router.predict_adhd_voice_from_audio(audio_path)
                        model_results.append({
                            "model_type": "voice",
                            "confidence": float(r.get("confidence", 0.0)),
                            "prediction": int(r.get("prediction", 0)),
                            "details": r,
                        })

                    elif model_type == "facial" and video_path:
                        r = await model_router.predict_adhd_facial_from_video(video_path)
                        model_results.append({
                            "model_type": "facial",
                            "confidence": float(r.get("confidence", 0.0)),
                            "prediction": int(r.get("prediction", 0)),
                            "details": r,
                        })

                except Exception as e:
                    print(f"[screening/adhd] Error in {model_type}: {e}")
                    continue

            fused = ADHDFusion.fuse_adhd_results(model_results)

            return {
                "success": True,
                "condition": "ADHD",
                "fused_result": fused,
                "individual_results": model_results,
                "modalities_used": available_modalities,
            }

        finally:
            if video_path and os.path.exists(video_path):
                try:
                    os.remove(video_path)
                except Exception:
                    pass
            if audio_path and os.path.exists(audio_path):
                try:
                    os.remove(audio_path)
                except Exception:
                    pass

    except json.JSONDecodeError as e:
        raise HTTPException(status_code=400, detail=f"Invalid questionnaire JSON: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"ADHD screening failed: {str(e)}")


# -------------------------
# Jobs (FIXED: actual processor attached + status transitions)
# -------------------------

def _update_job(job_id: str, **kwargs):
    if job_id in job_store:
        job_store[job_id].update(kwargs)
        job_store[job_id]["updated_at"] = datetime.now().isoformat()


def _extract_wav_from_video(video_path: str) -> str:
    """
    Extract WAV from MP4 using ffmpeg (16k mono PCM).
    Returns path to temp wav. Caller must delete it.
    """
    fd, wav_path = tempfile.mkstemp(suffix=".wav", prefix="audio_from_video_")
    os.close(fd)

    cmd = [
        "ffmpeg",
        "-y",
        "-i", video_path,
        "-vn",
        "-ac", "1",
        "-ar", "16000",
        "-f", "wav",
        wav_path,
    ]

    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if proc.returncode != 0:
        # clean temp file
        try:
            os.remove(wav_path)
        except Exception:
            pass
        raise RuntimeError(f"ffmpeg failed: {proc.stderr[-800:]}")

    if not os.path.exists(wav_path) or os.path.getsize(wav_path) < 2000:
        try:
            os.remove(wav_path)
        except Exception:
            pass
        raise RuntimeError("Extracted audio wav is empty/too small")

    return wav_path


def process_adhd_job(job_id: str, video_path: str, questionnaire_dict: Dict[str, Any]):
    """
    Background job processor.
    Runs behavior + eye + facial + voice (voice from audio extracted from the same video).
    Updates job_store status: queued -> processing -> completed/failed
    """
    _update_job(job_id, status="processing", error=None)

    wav_path = None
    try:
        # Build available modalities
        available_modalities: List[str] = []
        if questionnaire_dict:
            available_modalities.append("questionnaire")
        if video_path:
            available_modalities.append("video")

        # extract audio from video so voice model can work
        # (even if caller did not send a separate audio file)
        try:
            wav_path = _extract_wav_from_video(video_path)
            available_modalities.append("audio")
        except Exception as e:
            # voice becomes unavailable; continue other modalities
            print(f"[process_adhd_job] audio extraction failed: {e}")
            wav_path = None

        adhd_configs = model_config.get_model_config("ADHD")
        model_results: List[Dict[str, Any]] = []

        for model_type, cfg in adhd_configs.items():
            required_modalities = cfg.get("required_modalities", [])
            if not all(mod in available_modalities for mod in required_modalities):
                continue

            try:
                if model_type == "behavior" and questionnaire_dict:
                    r = asyncio.run(model_router.predict_adhd_behavior(questionnaire_dict))
                    model_results.append({
                        "model_type": "behavior",
                        "confidence": float(r.get("confidence", 0.0)),
                        "prediction": int(r.get("prediction", 0)),
                        "details": r,
                    })

                elif model_type == "eye" and video_path:
                    r = asyncio.run(model_router.predict_adhd_eye_from_video(video_path))
                    model_results.append({
                        "model_type": "eye",
                        "confidence": float(r.get("confidence", 0.0)),
                        "prediction": int(r.get("prediction", 0)),
                        "details": r,
                    })

                elif model_type == "facial" and video_path:
                    r = asyncio.run(model_router.predict_adhd_facial_from_video(video_path))
                    model_results.append({
                        "model_type": "facial",
                        "confidence": float(r.get("confidence", 0.0)),
                        "prediction": int(r.get("prediction", 0)),
                        "details": r,
                    })

                elif model_type == "voice" and wav_path:
                    r = asyncio.run(model_router.predict_adhd_voice_from_audio(wav_path))
                    model_results.append({
                        "model_type": "voice",
                        "confidence": float(r.get("confidence", 0.0)),
                        "prediction": int(r.get("prediction", 0)),
                        "details": r,
                    })

            except Exception as e:
                print(f"[process_adhd_job] Error in {model_type}: {e}")
                continue

        fused = ADHDFusion.fuse_adhd_results(model_results)

        # write result JSON
        result_path = os.path.join(RESULTS_DIR, f"{job_id}.json")
        with open(result_path, "w") as f:
            json.dump({
                "success": True,
                "condition": "ADHD",
                "fused_result": fused,
                "individual_results": model_results,
                "modalities_used": available_modalities,
            }, f)

        _update_job(job_id, status="completed", result_path=result_path)

    except Exception as e:
        _update_job(job_id, status="failed", error=str(e))
        print(f"[process_adhd_job] FAILED job={job_id}: {e}")

    finally:
        # cleanup audio temp
        if wav_path and os.path.exists(wav_path):
            try:
                os.remove(wav_path)
            except Exception:
                pass


@app.post("/jobs/adhd")
async def submit_adhd_job(
    background_tasks: BackgroundTasks,
    video_file: UploadFile = File(...),
    questionnaire_data: Optional[str] = Form(None),
):
    try:
        job_id = str(uuid.uuid4())
        questionnaire_dict = json.loads(questionnaire_data) if questionnaire_data else {}

        # Save video file to uploads
        safe_name = video_file.filename or "video.mp4"
        video_filename = f"{job_id}_{safe_name}"
        video_path = os.path.join(UPLOAD_DIR, video_filename)

        await video_file.seek(0)
        with open(video_path, "wb") as f:
            shutil.copyfileobj(video_file.file, f)
        await video_file.seek(0)

        job_store[job_id] = {
            "job_id": job_id,
            "status": "queued",
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "video_path": video_path,
            "result_path": None,
            "error": None,
        }

        # ✅ IMPORTANT: attach job processor
        background_tasks.add_task(process_adhd_job, job_id, video_path, questionnaire_dict)

        return {
            "job_id": job_id,
            "status": "queued",
            "message": "Job submitted successfully.",
        }

    except json.JSONDecodeError as e:
        raise HTTPException(status_code=400, detail=f"Invalid questionnaire JSON: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to submit job: {str(e)}")


@app.get("/jobs/{job_id}")
async def get_job_status(job_id: str):
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
    if job_id not in job_store:
        raise HTTPException(status_code=404, detail="Job not found")

    job = job_store[job_id]
    if job["status"] != "completed":
        raise HTTPException(status_code=400, detail=f"Job is not completed yet. Current status: {job['status']}")

    result_path = job.get("result_path")
    if not result_path or not os.path.exists(result_path):
        raise HTTPException(status_code=404, detail="Result file not found")

    with open(result_path, "r") as f:
        return json.load(f)


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
