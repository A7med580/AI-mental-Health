# Mental Health Screening Backend API

FastAPI backend service for mental health screening system.

## Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Update model paths in `config/model_config.py` if needed.

3. Run the server:
```bash
python main.py
```

Or using uvicorn:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## API Endpoints

### Health Check
- `GET /health` - Check if server is running

### Feature Extraction
- `POST /extract-features?modality={video|audio|face|eye}` - Extract features from media files

### Screening
- `POST /run-screening` - Execute full screening with ranked conditions

### Model Predictions
- `POST /predict/adhd/behavior` - ADHD behavior model
- `POST /predict/adhd/eye` - ADHD eye-tracking model
- `POST /predict/adhd/voice` - ADHD voice model
- `POST /predict/adhd/facial` - ADHD facial expression model
- `POST /predict/anxiety` - Anxiety model
- `POST /predict/asd/face` - ASD face model
- `POST /predict/asd/text` - ASD text model (AQ-10)

## Configuration

Update `config/model_config.py` to adjust:
- Model paths
- Confidence thresholds
- Required modalities

## Notes

- Models are loaded and cached on first use
- Video/audio files are temporarily stored during processing
- Ensure all model files are in the correct paths

