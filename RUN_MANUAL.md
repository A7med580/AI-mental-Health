# Unified Mental Health App - Running Manual

This guide explains how to run the unified ADHD & Autism screening application.

## Prerequisites
- **Python 3.9+** (for Backend)
- **Flutter SDK** (for App)
- **VS Code** or **Android Studio** (Recommended IDEs)

---

## 1. Backend Setup (The Brain)
The backend processes IQ/screening data and hosts the AI models.

### Step 1.1: Navigate to Backend
Open your terminal and go to the `backend` folder:
```bash
cd backend
```

### Step 1.2: Create/Activate Virtual Environment
If you haven't created one yet:
```bash
python -m venv venv
```

**Activate it:**
- **Windows:** `venv\Scripts\activate`
- **Mac/Linux:** `source venv/bin/activate`

### Step 1.3: Install Dependencies
```bash
pip install -r requirements.txt
```
*Note: If you get errors about missing libraries (like `librosa` or `tensorflow`), run individual installs:*
```bash
pip install librosa tensorflow reportlab
```

### Step 1.4: Run the Server
```bash
python main.py
```
> **Success:** You should see: `Uvicorn running on http://0.0.0.0:8000`

---

## 2. Frontend Setup (The App)

### Step 2.1: Configure IP Address (CRITICAL ⚠️)
Since you are likely testing on a physical phone or an emulator that needs to talk to your laptop:

1.  Find your laptop's **Local LAN IP**:
    *   **Mac:** System Settings -> Wi-Fi -> Details (e.g., `192.168.1.10`)
    *   **Windows:** `ipconfig` (Look for IPv4 Address)
2.  Open `frontend/lib/core/config/api_config.dart`.
3.  Update the `PHYSICAL_DEVICE_IP` constant:
    ```dart
    // MUST include http:// prefix!
    static const String PHYSICAL_DEVICE_IP = 'http://YOUR_LAN_IP:8000';
    ```
    *Example:* `static const String PHYSICAL_DEVICE_IP = 'http://192.168.1.45:8000';`

### Step 2.2: Run the App
Open a new terminal tab, navigate to `frontend`, and run:

```bash
cd frontend
flutter pub get
flutter run
```

---

## 3. Usage Flow (Triage System)

1.  **Home Screen**: Click **"Start Mental Health Screening"**.
2.  **Triage**: Answer 7 questions (ADHD + Autism + Impact).
3.  **Routing**: The app automatically detects which condition to investigate deeper.
4.  **Specific Flow**:
    *   **Autism**: Detailed AQ-10 questions -> Face Analysis -> Report.
    *   **ADHD**: Chat Assessment -> Eye/Voice checks -> Report.

---

## 4. Troubleshooting

**Error: `Scheme not starting with alphabetic character`**
*   **Cause**: You forgot `http://` in your IP address in `api_config.dart`.
*   **Fix**: Change `192.168.x.x:8000` to `http://192.168.x.x:8000`.

**Error: `Connection refused`**
*   **Cause**: The phone cannot reach the laptop.
*   **Fix**: Ensure both are on the SAME Wi-Fi. Check your firewall. Ensure Backend is running.

**Error: Missing Backend Models**
*   **Cause**: You didn't copy the model files to `backend/models`.
*   **Fix**: Ensure you have folders `backend/models/adhd` and `backend/models/asd` populating with `.pkl`, `.h5` files.
