#!/usr/bin/env python3
import os
import time
import json
import runpod
import requests
import subprocess
import threading
import shutil
import sys
from urllib.parse import urlparse

# Global variables
WEBUI_PROCESS = None
API_URL = "http://127.0.0.1:3000/sdapi/v1"
MODEL_DIR = "/workspace/stable-diffusion-webui-forge/models/Stable-diffusion"

def download_model(url, local_path):
    """Download a model file from URL if it doesn't exist."""
    if os.path.exists(local_path):
        print(f"Model already exists at {local_path}")
        return True
    
    print(f"Downloading model from {url} to {local_path}")
    try:
        os.makedirs(os.path.dirname(local_path), exist_ok=True)
        response = requests.get(url, stream=True)
        total_size = int(response.headers.get('content-length', 0))
        
        with open(local_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
        
        print(f"Model download complete: {local_path}")
        return True
    except Exception as e:
        print(f"Error downloading model: {e}")
        return False

def get_model_name_from_url(url):
    """Extract model name from URL."""
    parsed_url = urlparse(url)
    return os.path.basename(parsed_url.path)

def start_webui():
    """Start the WebUI process."""
    global WEBUI_PROCESS
    
    if WEBUI_PROCESS is not None and WEBUI_PROCESS.poll() is None:
        print("WebUI is already running")
        return

    print("Starting WebUI process...")
    
    # Print current directory and check if the launch.py file exists
    webui_dir = "/workspace/stable-diffusion-webui-forge"
    print(f"Changing to directory: {webui_dir}")
    if not os.path.exists(webui_dir):
        print(f"ERROR: WebUI directory {webui_dir} does not exist!")
        return
        
    os.chdir(webui_dir)
    
    if not os.path.exists("launch.py"):
        print("ERROR: launch.py does not exist in the WebUI directory!")
        print("Files in current directory:", os.listdir("."))
        return
    
    # Create a log file for the WebUI process output
    log_file = open("/workspace/webui.log", "w")
    
    # Start the process with explicit COMMANDLINE_ARGS and redirect output to the log file
    cmd = ["python3", "webui.py", "--api", "--xformers", "--port", "3000"]
    print(f"Executing command: {' '.join(cmd)}")
    
    try:
        WEBUI_PROCESS = subprocess.Popen(
            cmd,
            stdout=log_file,
            stderr=subprocess.STDOUT,
            env=os.environ,
            cwd=webui_dir
        )
        print(f"WebUI process started with PID: {WEBUI_PROCESS.pid}")
    except Exception as e:
        print(f"Failed to start WebUI process: {e}")
        return
    
    # Wait for API to become available
    max_retries = 60  # Increased from 30 to 60
    for i in range(max_retries):
        try:
            # Check if process is still running
            if WEBUI_PROCESS.poll() is not None:
                exit_code = WEBUI_PROCESS.poll()
                print(f"ERROR: WebUI process exited with code {exit_code}")
                print("Last 50 lines of WebUI log:")
                try:
                    with open("/workspace/webui.log", "r") as f:
                        log_lines = f.readlines()
                        for line in log_lines[-50:]:
                            print(f"LOG: {line.strip()}")
                except Exception as e:
                    print(f"Failed to read log file: {e}")
                return
                
            response = requests.get(f"{API_URL}/sd-models")
            if response.status_code == 200:
                print("WebUI API is ready")
                return
        except requests.exceptions.ConnectionError:
            pass
        except Exception as e:
            print(f"Error checking API: {e}")
        
        print(f"Waiting for WebUI API to become available ({i+1}/{max_retries})...")
        time.sleep(10)
    
    print("Failed to start WebUI API within timeout period")
    print("Last 50 lines of WebUI log:")
    try:
        with open("/workspace/webui.log", "r") as f:
            log_lines = f.readlines()
            for line in log_lines[-50:]:
                print(f"LOG: {line.strip()}")
    except Exception as e:
        print(f"Failed to read log file: {e}")

def load_model(model_name):
    """Load a specific model in the WebUI."""
    try:
        # Get current model
        response = requests.get(f"{API_URL}/sd-models")
        models = response.json()
        
        # Find the requested model
        model_info = None
        for model in models:
            if model_name in model["title"]:
                model_info = model
                break
        
        if not model_info:
            print(f"Model {model_name} not found in available models")
            return False
            
        # Check if model is already loaded
        options_response = requests.get(f"{API_URL}/options")
        current_model = options_response.json().get("sd_model_checkpoint")
        
        if current_model == model_info["title"]:
            print(f"Model {model_name} is already loaded")
            return True
            
        # Load the model
        print(f"Loading model: {model_info['title']}")
        response = requests.post(
            f"{API_URL}/options", 
            json={"sd_model_checkpoint": model_info["title"]}
        )
        
        if response.status_code == 200:
            print(f"Model {model_name} loaded successfully")
            return True
        else:
            print(f"Failed to load model: {response.text}")
            return False
            
    except Exception as e:
        print(f"Error loading model: {e}")
        return False

def handler(job):
    """Main handler function for RunPod serverless."""
    try:
        print(f"Starting handler with job input: {job.get('input', {})}")
        job_input = job["input"]
        
        # Handle model download if URL is provided
        if "model_url" in job_input:
            model_url = job_input["model_url"]
            model_name = job_input.get("model_name", get_model_name_from_url(model_url))
            model_path = os.path.join(MODEL_DIR, model_name)
            
            download_success = download_model(model_url, model_path)
            if not download_success:
                return {"error": "Failed to download model"}
        
        # Start WebUI if not running
        start_webui()
        
        # Check if WebUI process is running
        if WEBUI_PROCESS is None or WEBUI_PROCESS.poll() is not None:
            return {"error": "WebUI failed to start properly. Check logs for details."}
        
        # Load model if specified
        if "model_name" in job_input:
            model_load_success = load_model(job_input["model_name"])
            if not model_load_success:
                return {"error": f"Failed to load model {job_input['model_name']}"}
        
        # Handle the specific endpoint requested
        endpoint = job_input.get("endpoint", "txt2img")
        payload = job_input.get("payload", {})
        
        print(f"Making API request to endpoint: {endpoint}")
        print(f"With payload: {payload}")
        
        # Make the API request
        response = requests.post(f"{API_URL}/{endpoint}", json=payload)
        
        if response.status_code != 200:
            return {"error": f"API request failed with status {response.status_code}: {response.text}"}
        
        # Return the results
        return response.json()
    
    except Exception as e:
        import traceback
        error_traceback = traceback.format_exc()
        print(f"Handler error: {e}")
        print(f"Traceback: {error_traceback}")
        return {"error": str(e), "traceback": error_traceback}

# Print system information
print(f"Python version: {sys.version}")
print(f"Current directory: {os.getcwd()}")
print(f"Environment variables: {dict(os.environ)}")

# Start the WebUI in a separate thread
webui_thread = threading.Thread(target=start_webui, daemon=True)
webui_thread.start()
print("WebUI thread started")

# Wait for WebUI to initialize before accepting jobs
time.sleep(10)
print("Starting RunPod handler")

# Start the RunPod handler
runpod.serverless.start({"handler": handler})
