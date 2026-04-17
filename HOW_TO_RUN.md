# 🚀 How to Run — Mindful (AI Mental Health)

> Step-by-step guide to run the **backend** and **frontend** on **Windows** and **macOS**.

---

## 📋 Prerequisites

| Tool            | Version         | Download                                      |
|-----------------|-----------------|-----------------------------------------------|
| **Python**      | 3.10 – 3.12     | https://www.python.org/downloads/             |
| **Flutter**     | ≥ 3.7.0         | https://docs.flutter.dev/get-started/install  |
| **Git**         | Any recent      | https://git-scm.com/downloads                |
| **Android Studio** | Latest       | https://developer.android.com/studio          |
| **FFmpeg** *(optional)* | Any     | https://ffmpeg.org/download.html              |

> **Note:** Make sure `python`, `pip`, `flutter`, and `git` are available in your terminal/PATH.

---

## 1️⃣ Clone the Repository

```bash
git clone https://github.com/A7med580/AI-mental-Health.git
cd AI-mental-Health
```

---

## 2️⃣ Environment Variables (`.env`)

The project uses `.env` files that are **gitignored** — you must create them manually.

### Root `.env` (optional, for backend model path overrides)
```bash
# Copy the example file
cp .env.example .env          # macOS / Linux
copy .env.example .env        # Windows (CMD)
```
Edit `.env` and fill in any values you need. Most backend model paths default automatically, so you can leave them blank.

### Frontend `.env` (required)
```bash
# Create file: frontend/.env
```
Add these two lines with your **Supabase** credentials:
```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
```
> ⚠️ Without this file, the Flutter app will **fail to build** with:
> `No file or variants found for asset: .env`

---

## 3️⃣ Backend Setup & Run

### 🪟 Windows (PowerShell)

```powershell
# Navigate to backend
cd backend

# Create virtual environment (first time only)
python -m venv .venv

# Activate the virtual environment
.\.venv\Scripts\Activate

# Install dependencies
pip install -r requirements.txt

# Start the server
uvicorn main:app --host 0.0.0.0 --port 8000
```

> **Troubleshooting:** If `pandas==2.0.3` fails to build on Python 3.12+, install a newer version:
> ```powershell
> pip install pandas>=2.1.0
> pip install -r requirements.txt
> ```

### 🍎 macOS (Terminal)

```bash
# Navigate to backend
cd backend

# Create virtual environment (first time only)
python3 -m venv .venv

# Activate the virtual environment
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start the server
uvicorn main:app --host 0.0.0.0 --port 8000
```

**Or use the helper script (macOS only):**
```bash
chmod +x run_backend.sh
./run_backend.sh
```
> This script auto-detects your LAN IP, updates `api_config.dart`, and starts the server.

### ✅ Verify Backend is Running
Open your browser and visit:
```
http://localhost:8000/health
```
You should see a health-check JSON response.

---

## 4️⃣ Frontend Setup & Run

### 🪟 Windows (PowerShell)

```powershell
# Navigate to frontend
cd frontend

# Install Flutter dependencies
flutter pub get

# List available devices
flutter devices

# Launch Android emulator (if not running)
flutter emulators --launch <emulator_id>
# Example: flutter emulators --launch Pixel_9_Pro

# Run the app on the emulator
flutter run -d emulator-5554
```

### 🍎 macOS (Terminal)

```bash
# Navigate to frontend
cd frontend

# Install Flutter dependencies
flutter pub get

# List available devices
flutter devices

# Option A: Run on iOS Simulator
open -a Simulator
flutter run

# Option B: Run on Android Emulator
flutter emulators --launch <emulator_id>
flutter run -d emulator-5554

# Option C: Run on a physical iPhone (connected via USB)
flutter run
```

---

## 5️⃣ Connecting Frontend ↔ Backend

The Flutter app auto-selects the correct backend URL based on the platform. The config is in:

```
frontend/lib/core/config/api_config.dart
```

| Platform              | URL                        | When to use                         |
|-----------------------|----------------------------|-------------------------------------|
| Android Emulator      | `http://10.0.2.2:8000`    | Automatically used on emulator      |
| iOS Simulator         | `http://127.0.0.1:8000`   | Automatically used on simulator     |
| Physical Device (LAN) | `http://<YOUR_IP>:8000`   | Update `PHYSICAL_DEVICE_IP` in file |
| Web                   | `http://localhost:8000`    | Automatically used on web           |

### Running on a Physical Device

1. Find your computer's **LAN IP**:
   - **Windows:** `ipconfig` → look for `IPv4 Address`
   - **macOS:** `ipconfig getifaddr en0`

2. Update `PHYSICAL_DEVICE_IP` in `api_config.dart`:
   ```dart
   static const String PHYSICAL_DEVICE_IP = 'http://192.168.x.x:8000';
   ```

3. Make sure both your phone and computer are on the **same Wi-Fi network**.

---

## 🔄 Quick Reference (TL;DR)

### Windows — Full startup
```powershell
# Terminal 1: Backend
cd backend
.\.venv\Scripts\Activate
uvicorn main:app --host 0.0.0.0 --port 8000

# Terminal 2: Frontend
cd frontend
flutter run -d emulator-5554
```

### macOS — Full startup
```bash
# Terminal 1: Backend
cd backend
source .venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000

# Terminal 2: Frontend
cd frontend
flutter run
```

---

## ❓ Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| `No file or variants found for asset: .env` | Create `frontend/.env` with Supabase credentials |
| `ModuleNotFoundError: No module named 'mediapipe'` | Run `pip install mediapipe` inside the activated venv |
| `pandas==2.0.3` build fails on Python 3.12+ | Run `pip install pandas>=2.1.0` first, then re-run `pip install -r requirements.txt` |
| `run_backend.sh` does nothing on Windows | Use the PowerShell commands above — the script is macOS-only |
| Emulator not detected | Run `flutter emulators --launch <id>`, wait for it to boot, then retry |
| App can't reach backend on physical device | Update `PHYSICAL_DEVICE_IP` in `api_config.dart` with your LAN IP |
| `gradle assembleDebug` fails with cache errors | Run `cd frontend/android && ./gradlew clean` then retry |

---

## 📁 Project Structure Overview

```
AI-mental-Health/
├── backend/
│   ├── main.py                 # FastAPI entry point
│   ├── requirements.txt        # Python dependencies
│   ├── config/model_config.py  # Model paths & thresholds
│   ├── routers/                # API route handlers
│   ├── services/               # ML model services
│   ├── Models/                 # Trained model files (.pkl, .h5, .keras)
│   └── run_backend.sh          # macOS auto-run script
├── frontend/
│   ├── lib/                    # Flutter/Dart source code
│   ├── pubspec.yaml            # Flutter dependencies
│   ├── .env                    # ⚠️ YOU CREATE THIS (Supabase keys)
│   └── android/ / ios/         # Platform-specific configs
├── .env.example                # Template for environment variables
└── HOW_TO_RUN.md               # ← You are here
```
