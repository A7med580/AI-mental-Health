# Run Manual: ADHD Screening with Async Jobs & Notifications

This guide explains how to run the backend and Flutter app with the new async job system, video storage, and notifications.

## Prerequisites

- Python 3.8+ installed
- Flutter SDK installed
- Android Studio / Xcode (for mobile development)
- Backend models available in the configured paths

---

## 1. Backend Setup

### Step 1: Navigate to backend directory
```bash
cd "E:\Graduation project\backend"
```

### Step 2: Create and activate virtual environment
```bash
# Create venv
python -m venv venv

# Activate (Windows PowerShell)
.\venv\Scripts\Activate.ps1

# Or use direct Python (if activation fails)
# Use: venv\Scripts\python.exe instead of python
```

### Step 3: Install dependencies
```bash
python -m pip install --upgrade pip
pip install -r requirements.txt
```

### Step 4: Start the backend server
```bash
python main.py
```

The server will start on `http://0.0.0.0:8000` (accessible at `http://localhost:8000`).

**Important:** The backend creates two directories:
- `uploads/` - Temporary storage for uploaded videos (deleted after processing)
- `results/` - JSON results for completed jobs

---

## 2. Flutter App Setup

### Step 1: Navigate to Flutter app directory
```bash
cd "E:\Graduation project\Mindfull_App-master\Mindfull_App-master"
```

### Step 2: Install dependencies
```bash
flutter pub get
```

### Step 3: Configure API Base URL

The app uses environment-based URL detection, but for **physical devices**, you need to set a custom IP.

#### Option A: Set Custom IP in Code (Recommended for Physical Devices)

Edit `lib/core/config/api_config.dart` and call `ApiConfig.setCustomBaseUrl()` in `main.dart`:

```dart
// In lib/main.dart, after Supabase.initialize()
import 'package:mindful/core/config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(...);
  
  // Set your computer's LAN IP for physical device testing
  // Find your IP: Windows: ipconfig | findstr IPv4
  ApiConfig.setCustomBaseUrl('http://192.168.1.XXX:8000'); // Replace XXX with your IP
  
  runApp(const MyApp());
}
```

#### Option B: Default Behavior (Emulator/Simulator)

- **Android Emulator**: Automatically uses `http://10.0.2.2:8000`
- **iOS Simulator**: Automatically uses `http://127.0.0.1:8000`
- **Physical Device**: Requires Option A above

### Step 4: Find Your Computer's IP Address

**Windows:**
```bash
ipconfig
# Look for "IPv4 Address" under your active network adapter
# Example: 192.168.1.100
```

**Mac/Linux:**
```bash
ifconfig
# Look for inet address (usually under en0 or eth0)
```

### Step 5: Run the app
```bash
flutter run
```

---

## 3. Testing the Flow

### Complete ADHD Screening Flow:

1. **Login/Register** in the app
2. **Tap "Start Mental Health Screening"** on the chat screen
3. **Answer Initial Questionnaire** (12 questions)
4. **ADHD Chat Screen** appears (if ADHD is top condition)
5. **Answer Questions**:
   - Some questions allow text-only answers
   - Some questions require video recording
   - When recording video:
     - Tap "Record Video Response"
     - Speak your answer (30-60 seconds)
     - Tap "Stop Recording"
     - **Preview appears** with "Retake" and "Continue" buttons
     - Tap "Continue" to proceed
6. **Complete Screening**:
   - After all questions, tap "Complete Screening"
   - Job is submitted (shows "Submitting screening...")
   - Returns to chat screen
   - **Notification badge** appears on notifications icon
7. **View Results**:
   - Tap the **notifications icon** (bell icon) in header
   - See "Screening Result Ready" notification
   - Tap notification to view result details

---

## 4. API Endpoints

### Job Endpoints (New)

- `POST /jobs/adhd` - Submit ADHD screening job
  - Body: `multipart/form-data`
    - `video_file`: Video file (required)
    - `questionnaire_data`: JSON string (required)
  - Returns: `{ "job_id": "...", "status": "queued" }`

- `GET /jobs/{job_id}` - Get job status
  - Returns: `{ "job_id": "...", "status": "queued|processing|done|failed", ... }`

- `GET /jobs/{job_id}/result` - Get job result (only when status="done")
  - Returns: Full ADHD screening result with fused confidence, predictions, etc.

### Existing Endpoints (Still Available)

- `GET /health` - Health check
- `POST /screening/adhd` - Direct synchronous screening (legacy, still works)
- `POST /predict/adhd/*` - Individual model predictions

---

## 5. Troubleshooting

### "Connection refused" or "Server not connected"

**Problem:** Flutter app can't reach backend.

**Solutions:**
1. **Check backend is running**: Visit `http://localhost:8000/health` in browser
2. **Check IP address**: Ensure you set the correct LAN IP for physical devices
3. **Check firewall**: Windows Firewall may block port 8000
   - Allow Python through firewall or add port 8000 exception
4. **Check network**: Ensure phone and computer are on same WiFi network

### Backend fails to process video

**Problem:** Job status stays "processing" or becomes "failed".

**Solutions:**
1. Check backend logs for errors
2. Verify model files exist in configured paths (`config/model_config.py`)
3. Check `uploads/` directory has write permissions
4. Check video file format (should be .mp4)

### Video preview doesn't show

**Problem:** After recording, video preview doesn't appear.

**Solutions:**
1. Check camera permissions are granted
2. Check `video_player` package is installed (`flutter pub get`)
3. Check device storage permissions

### Notifications not appearing

**Problem:** No notification badge or notifications screen is empty.

**Solutions:**
1. Check `shared_preferences` package is installed
2. Verify job completed successfully (check backend logs)
3. Check notification is created in `JobService.getJobResult()` method

### Spaces in URL error

**Problem:** Error shows `http://localhost:8000/ screening/adhd` (space before endpoint).

**Solution:** This is fixed in `ApiConfig.getUrl()` - it removes leading slashes automatically.

---

## 6. File Structure

### Flutter Files Created/Modified:

**New Files:**
- `lib/core/config/api_config.dart` - API base URL configuration
- `lib/services/video_storage_service.dart` - Video file management
- `lib/services/notification_service.dart` - In-app notifications
- `lib/services/job_service.dart` - Async job submission and polling
- `lib/screens/notifications_screen.dart` - Notifications UI

**Modified Files:**
- `lib/services/model_service.dart` - Uses `ApiConfig` instead of hardcoded URL
- `lib/screens/adhd_chat_screen.dart` - Video preview, storage, job submission
- `lib/chat_screen.dart` - Added notifications button
- `lib/main.dart` - Added notifications route
- `pubspec.yaml` - Added `shared_preferences` and `path` dependencies

### Backend Files Modified:

- `backend/main.py` - Added job endpoints and background task processing

---

## 7. Development Notes

### Job Store (Backend)

Currently uses **in-memory dictionary** (`job_store`). For production:
- Use Redis for distributed systems
- Use database (PostgreSQL, MongoDB) for persistence
- Add job expiration/cleanup

### Video Storage (Flutter)

Videos are saved to:
- **Android**: `/data/data/com.example.mindful/app_flutter/app_videos/`
- **iOS**: App Documents directory
- Videos persist until manually deleted or app uninstalled

### Notifications (Flutter)

Notifications stored in `SharedPreferences` as JSON array. Each notification includes:
- `id`, `title`, `body`, `createdAt`, `isRead`, `payload`

---

## 8. Quick Test Commands

### Test Backend Health:
```bash
curl http://localhost:8000/health
```

### Test Job Submission (from Flutter app or Postman):
```bash
curl -X POST http://localhost:8000/jobs/adhd \
  -F "video_file=@test_video.mp4" \
  -F "questionnaire_data={\"q0\":3,\"q1\":4}"
```

### Check Job Status:
```bash
curl http://localhost:8000/jobs/{job_id}
```

### Get Job Result:
```bash
curl http://localhost:8000/jobs/{job_id}/result
```

---

## Summary

✅ **Networking**: Fixed with environment-based API config  
✅ **Video Storage**: Permanent storage with preview  
✅ **Async Jobs**: Background processing with status polling  
✅ **Notifications**: In-app notification system  
✅ **Error Handling**: Connection errors, retry buttons, clear messages  

The app now supports async ADHD screening with proper video management and user notifications!
