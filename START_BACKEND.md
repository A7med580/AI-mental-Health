# How to Start Backend Server

## Step 1: Open a NEW Terminal Window

**Important:** Keep this terminal open - backend must stay running!

## Step 2: Navigate to Backend Directory

```powershell
cd "E:\Graduation project\backend"
```

## Step 3: Activate Virtual Environment

```powershell
.\venv\Scripts\Activate.ps1
```

If activation fails, use the Python directly:
```powershell
.\venv\Scripts\python.exe main.py
```

## Step 4: Start Backend Server

```powershell
python main.py
```

**OR** if activation doesn't work:

```powershell
.\venv\Scripts\python.exe main.py
```

## Expected Output

You should see:
```
INFO:     Started server process [xxxxx]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

## Step 5: Test from PC Browser

While backend is running, open browser on PC:
```
http://localhost:8000/health
```

Should return: `{"status":"healthy"}`

## Step 6: Test from Phone Browser

On phone (same Wi-Fi), open browser:
```
http://192.168.1.2:8000/health
```

Should return: `{"status":"healthy"}`

## Troubleshooting

### If you see "ModuleNotFoundError: No module named 'uvicorn'"

The virtual environment isn't activated. Use:
```powershell
.\venv\Scripts\python.exe main.py
```

### If backend starts but phone can't connect

1. Check Windows Firewall - ensure Python is allowed
2. Verify both devices on same Wi-Fi
3. Try accessing from PC browser first: `http://192.168.1.2:8000/health`

### If port 8000 is already in use

Another process is using port 8000. Find and stop it:
```powershell
netstat -ano | findstr :8000
# Note the PID, then:
taskkill /PID <PID> /F
```



