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
from fastapi import FastAPI, File, UploadFile, HTTPException, Form, Body, BackgroundTasks, Depends, Security
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security.api_key import APIKeyHeader

# API Key authentication
API_KEY = os.getenv("BACKEND_API_KEY")
api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)

async def verify_api_key(key: str = Security(api_key_header)):
    if API_KEY and key != API_KEY:
        raise HTTPException(status_code=403, detail="Invalid API key")

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
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "http://localhost,http://localhost:3000").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Authorization", "Content-Type"],
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

# File upload limits and validation
MAX_UPLOAD_BYTES = 100 * 1024 * 1024  # 100 MB
ALLOWED_VIDEO_TYPES = {"video/mp4", "video/quicktime", "video/webm", "application/octet-stream"}
ALLOWED_AUDIO_TYPES = {"audio/wav", "audio/x-wav", "audio/mpeg", "application/octet-stream"}

os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(os.path.join(UPLOAD_DIR, "adhd"), exist_ok=True)
os.makedirs(os.path.join(UPLOAD_DIR, "depression"), exist_ok=True)
os.makedirs(RESULTS_DIR, exist_ok=True)


@app.on_event("startup")
async def cleanup_old_files():
    """Clean up temp files older than 24 hours on startup"""
    import time, glob
    cutoff = time.time() - 86400
    for pattern in ["uploads/**/*", "results/*.json"]:
        for f in glob.glob(pattern, recursive=True):
            if os.path.isfile(f) and os.path.getmtime(f) < cutoff:
                try:
                    os.remove(f)
                except Exception:
                    pass


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
        # File size and type validation
        if video_file is not None:
            vcontent = await video_file.read()
            if len(vcontent) > MAX_UPLOAD_BYTES:
                raise HTTPException(413, "File too large (max 100 MB)")
            await video_file.seek(0)
            if video_file.content_type not in ALLOWED_VIDEO_TYPES:
                raise HTTPException(400, f"Invalid video type: {video_file.content_type}")
        if audio_file is not None:
            acontent = await audio_file.read()
            if len(acontent) > MAX_UPLOAD_BYTES:
                raise HTTPException(413, "File too large (max 100 MB)")
            await audio_file.seek(0)
            if audio_file.content_type not in ALLOWED_AUDIO_TYPES:
                raise HTTPException(400, f"Invalid audio type: {audio_file.content_type}")

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
        # File size and type validation
        if video_file is not None:
            vcontent = await video_file.read()
            if len(vcontent) > MAX_UPLOAD_BYTES:
                raise HTTPException(413, "File too large (max 100 MB)")
            await video_file.seek(0)
            if video_file.content_type not in ALLOWED_VIDEO_TYPES:
                raise HTTPException(400, f"Invalid video type: {video_file.content_type}")
        if audio_file is not None:
            acontent = await audio_file.read()
            if len(acontent) > MAX_UPLOAD_BYTES:
                raise HTTPException(413, "File too large (max 100 MB)")
            await audio_file.seek(0)
            if audio_file.content_type not in ALLOWED_AUDIO_TYPES:
                raise HTTPException(400, f"Invalid audio type: {audio_file.content_type}")

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
        # File size and type validation
        vcontent = await video_file.read()
        if len(vcontent) > MAX_UPLOAD_BYTES:
            raise HTTPException(413, "File too large (max 100 MB)")
        await video_file.seek(0)
        if video_file.content_type not in ALLOWED_VIDEO_TYPES:
            raise HTTPException(400, f"Invalid video type: {video_file.content_type}")

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
        # File size and type validation
        acontent = await audio_file.read()
        if len(acontent) > MAX_UPLOAD_BYTES:
            raise HTTPException(413, "File too large (max 100 MB)")
        await audio_file.seek(0)
        if audio_file.content_type not in ALLOWED_AUDIO_TYPES:
            raise HTTPException(400, f"Invalid audio type: {audio_file.content_type}")

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
        # File size and type validation
        vcontent = await video_file.read()
        if len(vcontent) > MAX_UPLOAD_BYTES:
            raise HTTPException(413, "File too large (max 100 MB)")
        await video_file.seek(0)
        if video_file.content_type not in ALLOWED_VIDEO_TYPES:
            raise HTTPException(400, f"Invalid video type: {video_file.content_type}")

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
        # File size and type validation
        if video_file is not None:
            vcontent = await video_file.read()
            if len(vcontent) > MAX_UPLOAD_BYTES:
                raise HTTPException(413, "File too large (max 100 MB)")
            await video_file.seek(0)
            if video_file.content_type not in ALLOWED_VIDEO_TYPES:
                raise HTTPException(400, f"Invalid video type: {video_file.content_type}")
        if audio_file is not None:
            acontent = await audio_file.read()
            if len(acontent) > MAX_UPLOAD_BYTES:
                raise HTTPException(413, "File too large (max 100 MB)")
            await audio_file.seek(0)
            if audio_file.content_type not in ALLOWED_AUDIO_TYPES:
                raise HTTPException(400, f"Invalid audio type: {audio_file.content_type}")

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
            # Behavior and voice are disabled (broken feature spaces / wrong model).
            DISABLED_ADHD_MODALITIES = ["behavior", "voice"]

            for model_type, cfg in adhd_configs.items():
                if model_type in DISABLED_ADHD_MODALITIES:
                    continue
                required_modalities = cfg.get("required_modalities", [])
                if not all(mod in available_modalities for mod in required_modalities):
                    continue

                try:
                    if model_type == "eye" and video_path:
                        r = await model_router.predict_adhd_eye_from_video(video_path)
                        model_results.append({
                            "model_type": "eye",
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
                "condition": "adhd",
                "fused_result": fused,
                "individual_results": model_results,
                "modalities_used": available_modalities,
                "unavailable_modalities": DISABLED_ADHD_MODALITIES,
                "model_version": "v1_eye_only",
            }

        finally:
            feature_extractor.clear_cache(video_path)
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


def _score_adhd_questionnaire(questionnaire_dict: Dict[str, Any]) -> Dict[str, Any]:
    """
    DSM-5/ASRS-aligned scoring of ADHD chat + initial questionnaire answers.

    Text answers mapped to 0–1 probability scale:
      never / no / not at all  → 0.05
      rarely                   → 0.25
      sometimes / occasionally → 0.50
      often / usually / yes    → 0.75
      always / constantly      → 0.95

    Initial questionnaire answers are numeric (1–5 Likert):
      mapped as (value − 1) / 4  → 0..1
    """
    def text_to_prob(text: str) -> Optional[float]:
        t = str(text).strip().lower()
        if not t or t in ("", "none", "null", "n/a"):
            return None
        if any(w in t for w in ["always", "constantly", "definitely", "absolutely", "very often"]):
            return 0.95
        if any(w in t for w in ["often", "usually", "yes", "frequently", "most"]):
            return 0.75
        if any(w in t for w in ["sometimes", "occasionally", "sort of", "kind of", "moderate"]):
            return 0.50
        if any(w in t for w in ["rarely", "seldom", "not really", "barely"]):
            return 0.25
        if any(w in t for w in ["never", "not at all", "no", "nope", "nah"]):
            return 0.05
        # Unrecognised but non-empty → neutral
        return 0.50

    scores: List[float] = []

    # Chat text answers (chat_q_0_text .. chat_q_7_text)
    for i in range(8):
        val = questionnaire_dict.get(f"chat_q_{i}_text")
        if val is not None:
            p = text_to_prob(str(val))
            if p is not None:
                scores.append(p)

    # Initial numeric answers (initial_q_0 .. initial_q_N), scale 1–5
    for key, val in questionnaire_dict.items():
        if key.startswith("initial_q_"):
            try:
                v = float(val)
                # Map Likert 1–5 → 0–1
                scores.append(max(0.0, min(1.0, (v - 1.0) / 4.0)))
            except (ValueError, TypeError):
                pass

    if not scores:
        return {"confidence": 0.0, "prediction": 0, "answered": 0, "unavailable": True}

    avg = float(sum(scores) / len(scores))
    return {
        "confidence": round(avg, 4),
        "prediction": 1 if avg >= 0.60 else 0,
        "answered": len(scores),
        "unavailable": False,
    }


async def process_adhd_job(job_id: str, video_path: str, questionnaire_dict: Dict[str, Any]):
    """
    Background job processor.
    Runs questionnaire scorer + eye + facial models.
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

        try:
            wav_path = _extract_wav_from_video(video_path)
            available_modalities.append("audio")
        except Exception as e:
            print(f"[process_adhd_job] audio extraction failed: {e}")
            wav_path = None

        adhd_configs = model_config.get_model_config("ADHD")
        model_results: List[Dict[str, Any]] = []
        DISABLED_ADHD_MODALITIES = ["behavior", "voice"]

        # ── Questionnaire scorer (always runs when answers are provided) ──
        if questionnaire_dict:
            qs = _score_adhd_questionnaire(questionnaire_dict)
            if not qs.get("unavailable", False):
                model_results.append({
                    "model_type": "questionnaire",
                    "confidence": qs["confidence"],
                    "prediction": qs["prediction"],
                    "details": qs,
                })
                print(f"[process_adhd_job] questionnaire score={qs['confidence']:.3f} (n={qs['answered']})")

        # ── Video models ──
        for model_type, cfg in adhd_configs.items():
            if model_type in DISABLED_ADHD_MODALITIES:
                continue
            required_modalities = cfg.get("required_modalities", [])
            if not all(mod in available_modalities for mod in required_modalities):
                continue

            try:
                if model_type == "eye" and video_path:
                    r = await model_router.predict_adhd_eye_from_video(video_path)
                    model_results.append({
                        "model_type": "eye",
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
                print(f"[process_adhd_job] Error in {model_type}: {e}")
                continue

        fused = ADHDFusion.fuse_adhd_results(model_results)

        # write result JSON
        result_path = os.path.join(RESULTS_DIR, f"{job_id}.json")
        with open(result_path, "w") as f:
            json.dump({
                "success": True,
                "condition": "adhd",
                "fused_result": fused,
                "individual_results": model_results,
                "modalities_used": available_modalities,
                "model_version": "v2_questionnaire_eye_facial",
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


async def process_depression_job(job_id: str, video_path: Optional[str], questionnaire_data: Dict[str, Any]):
    """Background task for DAIC-WOZ Multimodal Depression Screening"""
    try:
        _update_job(job_id, status="processing")
        
        # The updated execute_depression_screening already returns the full formatted dict
        results = await model_router.execute_depression_screening(
            video_path=video_path,
            questionnaire_data=questionnaire_data
        )

        # write result JSON
        result_path = os.path.join(RESULTS_DIR, f"{job_id}.json")
        with open(result_path, "w") as f:
            json.dump(results, f)

        _update_job(job_id, status="completed", result_path=result_path)

    except Exception as e:
        _update_job(job_id, status="failed", error=str(e))
        print(f"[process_depression_job] FAILED job={job_id}: {e}")

    finally:
        # cleanup audio temp ONLY (extracted from video)
        # We don't delete the video_path because user wants to keep it in uploads/depression
        pass


@app.post("/jobs/adhd")
async def submit_adhd_job(
    background_tasks: BackgroundTasks,
    video_file: UploadFile = File(...),
    questionnaire_data: Optional[str] = Form(None),
):
    try:
        # File size and type validation
        vcontent = await video_file.read()
        if len(vcontent) > MAX_UPLOAD_BYTES:
            raise HTTPException(413, "File too large (max 100 MB)")
        await video_file.seek(0)
        if video_file.content_type not in ALLOWED_VIDEO_TYPES:
            raise HTTPException(400, f"Invalid video type: {video_file.content_type}")

        job_id = str(uuid.uuid4())
        questionnaire_dict = json.loads(questionnaire_data) if questionnaire_data else {}

        # Save video file to uploads/adhd
        safe_name = video_file.filename or "video.mp4"
        video_filename = f"{job_id}_{safe_name}"
        video_path = os.path.join(UPLOAD_DIR, "adhd", video_filename)

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

    except HTTPException:
        raise
    except json.JSONDecodeError as e:
        raise HTTPException(status_code=400, detail=f"Invalid questionnaire JSON: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to submit job: {str(e)}")


@app.post("/jobs/depression")
async def submit_depression_job(
    background_tasks: BackgroundTasks,
    video_file: Optional[UploadFile] = File(None),
    questionnaire_data: Optional[str] = Form(None),
):
    try:
        job_id = str(uuid.uuid4())
        questionnaire_dict = json.loads(questionnaire_data) if questionnaire_data else {}

        video_path = None
        if video_file:
            # File size and type validation
            vcontent = await video_file.read()
            if len(vcontent) > MAX_UPLOAD_BYTES:
                raise HTTPException(413, "File too large (max 100 MB)")
            await video_file.seek(0)
            if video_file.content_type not in ALLOWED_VIDEO_TYPES:
                raise HTTPException(400, f"Invalid video type: {video_file.content_type}")

            safe_name = video_file.filename or "video.mp4"
            video_filename = f"{job_id}_{safe_name}"
            video_path = os.path.join(UPLOAD_DIR, "depression", video_filename)

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

        # Attach depression job processor
        background_tasks.add_task(process_depression_job, job_id, video_path, questionnaire_dict)

        return {
            "job_id": job_id,
            "status": "queued",
            "message": "Depression screening job submitted successfully.",
        }

    except HTTPException:
        raise
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
