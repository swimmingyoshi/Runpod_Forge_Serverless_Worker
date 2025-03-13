#!/bin/bash

echo "Initializing WebUI..."
cd /workspace/stable-diffusion-webui-forge

# Start WebUI in the background with proper parameters
python3 webui.py --api --xformers --listen --port 3000 --skip-torch-cuda-test &
WEBUI_PID=$!

# Wait for the WebUI to start
MAX_ATTEMPTS=60
ATTEMPT=0
echo "Waiting for WebUI to start..."

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  # Check if process is still running
  if ! ps -p $WEBUI_PID > /dev/null; then
    echo "ERROR: WebUI process died. Check logs for details."
    exit 1
  fi

  # Check if API is responding
  if curl -s http://127.0.0.1:3000/sdapi/v1/sd-models > /dev/null 2>&1; then
    echo "WebUI started successfully"
    break
  fi
  
  echo "Attempt $((ATTEMPT+1))/$MAX_ATTEMPTS: WebUI not ready yet..."
  ATTEMPT=$((ATTEMPT+1))
  sleep 10
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
  echo "ERROR: WebUI failed to start after $MAX_ATTEMPTS attempts"
  # Print the last 100 lines of the webui log to help diagnose the issue
  echo "Last 100 lines of WebUI log:"
  tail -n 100 /workspace/stable-diffusion-webui-forge/log.txt 2>/dev/null
  exit 1
fi

# Start the handler
cd /workspace
python3 -u handler.py