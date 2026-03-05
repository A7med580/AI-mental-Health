# 🚀 Quick Start Guide

Welcome to the **Mindful** project. This guide will help you get the backend server and the Flutter mobile application running from scratch on a new machine.

The system is designed to screen and monitor four mental health conditions:
- **ADHD (Attention-Deficit/Hyperactivity Disorder)**
- **ASD (Autism Spectrum Disorder)**
- **Depression**
- **Social Anxiety**

Follow these 5 minimal steps to get started:

---

## Step 1: Clone the Repository

Clone the project to your local machine:
```bash
git clone https://github.com/A7med580/AI-mental-Health.git
cd AI-mental-Health
```

## Step 2: Set Up the Backend Environment

The backend requires Python 3.8+ and specific ML libraries. It's highly recommended to use a virtual environment.

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate  # On Windows use: .venv\Scripts\activate
pip install -r requirements.txt
```

## Step 3: Configure Environment Variables

1. In the `backend/` directory, locate the `.env.example` file.
2. Duplicate it and rename it to `.env`:
   ```bash
   cp .env.example .env
   ```
3. Open the `.env` file and replace the placeholder keys with your actual **Gemini API Key**, **Supabase URL**, and **Supabase Anon Key**.

## Step 4: Start the Backend Server

With your virtual environment active and dependencies installed, start the FastAPI server:

```bash
# Still inside the backend/ directory
python main.py
```
*The server will typically run on `http://localhost:8000` or `http://0.0.0.0:8000`.*

> **Tip:** Ensure your ML models are downloaded and placed in the correct `Models/` subdirectories as expected by the backend before running.

## Step 5: Start the Flutter App

Open a new terminal window to keep the backend running.

1. Find your computer's local network IP address (e.g., `192.168.1.5`).
   - *Mac/Linux:* `ifconfig`
   - *Windows:* `ipconfig`
2. Update the API base URL in the frontend configuration file:
   Open `frontend/lib/core/config/api_config.dart` and set `baseUrl` to your computer's IP address (e.g., `http://192.168.1.5:8000`).
3. Run the Flutter app:
   ```bash
   cd frontend
   flutter pub get
   flutter run
   ```

🎉 **You're all set!** 
You should now be able to use the Mindful app on your emulator or physical device, communicating directly with your local AI backend.
