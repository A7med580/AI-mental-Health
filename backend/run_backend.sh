#!/bin/bash

# 1. Activate the Python virtual environment
# Note: Using .venv as requested by user
if [ -d ".venv" ]; then
    source .venv/bin/activate
elif [ -d "../venv" ]; then
    # Fallback to root venv if .venv doesn't exist in backend
    source ../venv/bin/activate
else
    echo "Warning: Virtual environment not found."
fi

# 2. Auto-detect the Mac's current LAN IP
IP=$(ipconfig getifaddr en0)
if [ -z "$IP" ]; then
    IP=$(ipconfig getifaddr en1)
fi

if [ -z "$IP" ]; then
    echo "Error: Could not detect LAN IP on en0 or en1."
    exit 1
fi

echo "Detected LAN IP: $IP"

# 3. Path to frontend/.env (BACKEND_HOST is read by the Flutter app at runtime)
ENV_PATH="../frontend/.env"

if [ -f "$ENV_PATH" ]; then
    # On macOS, sed -i requires an empty string argument for the extension
    if grep -q "^BACKEND_HOST=" "$ENV_PATH"; then
        sed -i '' "s|^BACKEND_HOST=.*|BACKEND_HOST=$IP|" "$ENV_PATH"
    else
        echo "BACKEND_HOST=$IP" >> "$ENV_PATH"
    fi
    echo "Updated $ENV_PATH with BACKEND_HOST=$IP"
else
    echo "Warning: $ENV_PATH not found; skipping BACKEND_HOST patch."
fi

# 5. Run ffmpeg -version
ffmpeg -version

# 6. Start the server
echo "Starting Uvicorn server..."
uvicorn main:app --host 0.0.0.0 --port 8000
