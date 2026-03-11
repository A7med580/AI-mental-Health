"""
Lightweight Backend Server (Phase 2 Testing)
Runs only the new Phase 2 endpoints without loading Phase 1 ADHD models.
Use this for testing the orchestrator and risk assessment services.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Import new routers
from routers.assessment_router import router as assessment_router

app = FastAPI(title="Mental Health Screening API - Phase 2")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(assessment_router)


@app.get("/")
async def root():
    return {
        "message": "Mental Health Screening API - Phase 2",
        "status": "running",
        "endpoints": [
            "POST /api/v1/assess",
            "GET /api/v1/assessments/{user_id}/history",
            "GET /api/v1/doctor/flagged-patients"
        ]
    }


@app.get("/health")
async def health_check():
    return {"status": "healthy", "phase": "2"}


if __name__ == "__main__":
    import uvicorn
    print("[Phase 2 Server] Starting without ADHD models...")
    print("[Phase 2 Server] Available endpoints:")
    print("  POST /api/v1/assess")
    print("  GET /api/v1/assessments/{user_id}/history")
    print("  GET /api/v1/doctor/flagged-patients")
    uvicorn.run(app, host="0.0.0.0", port=8000)
