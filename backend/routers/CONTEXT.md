# Overview
This directory (and the root `main.py`) defines the RESTful API endpoints for the FastAPI backend. It receives data from the Flutter frontend and routes it to the appropriate Machine Learning pipelines (e.g., ASD, ADHD, DAIC-WOZ).

# Primary Files & Responsibilities

* **`main.py`** (Root Level Router): Currently acts as the primary router for the application. It handles:
  * Modal feature extraction endpoints (`/extract-features`).
  * Direct, synchronous model inferences (`/asd/text/predict`, `/predict/adhd/voice`).
  * Heavy, background job submissions for multi-modal analysis (`/jobs/adhd`, `/screening/adhd`).
  * Job status polling endpoints (`/jobs/{job_id}`, `/jobs/{job_id}/result`).
* **`routers/`** directory: Intended to house modularized FastAPI decorators (`APIRouter`) as the application scales out of `main.py` (e.g., separating user authentication, reporting, and different condition screenings into distinct files like `asd_router.py`, `adhd_router.py`).

# Key Logic Flow & Edge Cases

1. **Synchronous vs. Asynchronous:** Light models (like tabular text inference) are configured to run synchronously (or via `asyncio.to_thread` for TensorFlow to prevent blocking). Heavy multi-modal video/audio screenings use `BackgroundTasks` to process data without keeping the HTTP connection alive.
2. **File Handling:** The router layer is responsible for creating temporary files via `tempfile` for uploaded videos/audios, ensuring these are safely destructed `finally:` blocks even if ML inference crashes.
3. **Threading & Mutex:** Due to macOS/TensorFlow mutex locks, the application explicitly avoids warm-loading TF bundles on startup in `main.py`, deferring load until the first specific inference request.
