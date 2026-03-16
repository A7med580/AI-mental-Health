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

# 3. Path to api_config.dart relative from backend/
API_CONFIG_PATH="../frontend/lib/core/config/api_config.dart"

# 4. Use sed to replace the IP in api_config.dart
# On macOS, sed -i requires an empty string argument for the extension
sed -i '' "s|static const String PHYSICAL_DEVICE_IP = 'http://.*:8000';|static const String PHYSICAL_DEVICE_IP = 'http://$IP:8000';|" "$API_CONFIG_PATH"

echo "Updated $API_CONFIG_PATH with http://$IP:8000"

# 5. Run ffmpeg -version
ffmpeg -version

# 6. Start the server
echo "Starting Uvicorn server..."
uvicorn main:app --host 0.0.0.0 --port 8000
