# Quick Start Guide

## 🚀 Getting Started

### Step 1: Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Create virtual environment (recommended):**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Verify model paths:**
   - Check `config/model_config.py`
   - Ensure all model files exist in the specified paths
   - Models should be in `Graduation Project/` directory

5. **Start the server:**
   ```bash
   python main.py
   ```
   
   Server will run on `http://localhost:8000`

### Step 2: Flutter App Setup

1. **Navigate to Flutter app:**
   ```bash
   cd Mindfull_App-master/Mindfull_App-master
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Update backend URL:**
   - Open `lib/services/model_service.dart`
   - Update `baseUrl` based on your environment:
     - **Android Emulator**: `http://10.0.2.2:8000`
     - **iOS Simulator**: `http://localhost:8000`
     - **Physical Device**: `http://YOUR_COMPUTER_IP:8000` (find IP with `ipconfig` on Windows or `ifconfig` on Mac/Linux)

4. **Run the app:**
   ```bash
   flutter run
   ```

## 📋 System Components

### Backend (`backend/`)
- **main.py**: FastAPI server with all endpoints
- **config/model_config.py**: Model configurations and thresholds
- **services/model_router.py**: Decision engine for model routing
- **services/feature_extractor.py**: Feature extraction from video/audio
- **services/model_loader.py**: Model loading and caching

### Flutter App (`Mindfull_App-master/Mindfull_App-master/lib/`)
- **services/model_service.dart**: API client for backend communication
- **screens/screening_chat_screen.dart**: Screening interface with video recording
- **results_screen.dart**: Results display screen
- **chat_screen.dart**: Original chat interface (can be enhanced)

## 🔄 Workflow

1. **User logs in** → Authentication via Supabase
2. **Questionnaire** → 12 questions (to be implemented by you)
3. **Condition Ranking** → Calculate probabilities for ADHD, Anxiety, ASD
4. **Screening Chat** → Navigate to `ScreeningChatScreen` with ranked conditions
5. **Video Recording** → User records response (30-60 seconds)
6. **Feature Extraction** → Backend extracts features from video
7. **Model Execution** → Sequential model execution based on ranking
8. **Results Display** → Show screening outcomes

## 🎯 Key Features Implemented

✅ **Backend API** with FastAPI
✅ **Model Router** for sequential execution
✅ **Feature Extraction** from video/audio
✅ **Flutter Integration** with API client
✅ **Video Recording** in chat screen
✅ **Results Display** screen
✅ **Model Configuration** system

## ⚠️ Important Notes

1. **Questionnaire Screen**: You mentioned you'll add the 12-question questionnaire. Once added, it should:
   - Calculate probability scores for each condition
   - Navigate to `ScreeningChatScreen` with ranked conditions:
     ```dart
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => ScreeningChatScreen(
           rankedConditions: [
             {"condition": "ADHD", "probability": 0.75},
             {"condition": "Anxiety", "probability": 0.60},
             {"condition": "ASD", "probability": 0.45},
           ],
         ),
       ),
     );
     ```

2. **Model Paths**: Ensure all model files are in the correct locations as specified in `config/model_config.py`

3. **Permissions**: The app requests camera and microphone permissions automatically

4. **Backend URL**: Make sure to update the backend URL in `model_service.dart` for your environment

## 🐛 Troubleshooting

### Backend won't start
- Check Python version (3.8+)
- Verify all dependencies installed
- Check model file paths exist

### Flutter can't connect to backend
- Verify backend is running
- Check backend URL is correct for your environment
- Check firewall settings
- For physical device, ensure phone and computer are on same network

### Models not loading
- Verify model files exist in specified paths
- Check file permissions
- Review error logs in backend console

## 📝 Next Steps

1. **Add Questionnaire Screen**: Implement the 12-question initial screening
2. **Test Integration**: Test the full flow from questionnaire to results
3. **Tune Thresholds**: Adjust confidence thresholds in `model_config.py` based on testing
4. **Enhance UI**: Improve user experience and add loading states
5. **Error Handling**: Add comprehensive error handling and user feedback

## 📚 API Documentation

Once backend is running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## 🔒 Security Notes

- Update CORS settings in `main.py` for production
- Use environment variables for sensitive data
- Implement proper authentication for API endpoints
- Encrypt sensitive user data

