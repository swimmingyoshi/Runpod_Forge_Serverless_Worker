FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    wget \
    curl \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    libgomp1 \
    ffmpeg \
    libopencv-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a working directory
WORKDIR /workspace

# Install Python dependencies first
RUN pip3 install --no-cache-dir runpod requests

# Clone the Stable Diffusion WebUI Forge repository
RUN git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git

<<<<<<< HEAD
# Install Python dependencies first
RUN pip3 install --no-cache-dir runpod requests torch==2.0.1+cu118 torchvision==0.15.2+cu118 \
    -f https://download.pytorch.org/whl/torch_stable.html

# Install WebUI dependencies
WORKDIR /workspace/stable-diffusion-webui-forge
RUN pip3 install --no-cache-dir -r requirements_versions.txt xformers
=======
# Install PyTorch with CUDA support
WORKDIR /workspace/stable-diffusion-webui-forge
RUN pip3 install --no-cache-dir torch==2.0.1+cu118 torchvision==0.15.2+cu118 \
    --extra-index-url https://download.pytorch.org/whl/cu118

# Install WebUI dependencies
RUN pip3 install --no-cache-dir -r requirements_versions.txt
RUN pip3 install --no-cache-dir xformers==0.0.21
>>>>>>> 28e28c1 (.)

# Pre-download a model
RUN mkdir -p /workspace/stable-diffusion-webui-forge/models/Stable-diffusion
RUN wget -q -O /workspace/stable-diffusion-webui-forge/models/Stable-diffusion/MAI_Pony-v1R.safetensors \
    https://huggingface.co/Meowmeow42/NewStart/resolve/main/MAI_Pony-v1R.safetensors

# Copy the handler
WORKDIR /workspace
COPY handler.py /workspace/handler.py
<<<<<<< HEAD

# Add this script to check and initialize the webui before running the handler
RUN echo '#!/bin/bash\n\
echo "Initializing WebUI..."\n\
cd /workspace/stable-diffusion-webui-forge\n\
python3 webui.py --api --xformers --port 3000 --skip-torch-cuda-test &\n\
WEBUI_PID=$!\n\
\n\
# Wait for the WebUI to start\n\
MAX_ATTEMPTS=30\n\
ATTEMPT=0\n\
echo "Waiting for WebUI to start..."\n\
\n\
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do\n\
  if curl -s http://127.0.0.1:3000/sdapi/v1/sd-models > /dev/null; then\n\
    echo "WebUI started successfully"\n\
    break\n\
  fi\n\
  echo "Attempt $((ATTEMPT+1))/$MAX_ATTEMPTS: WebUI not ready yet..."\n\
  ATTEMPT=$((ATTEMPT+1))\n\
  sleep 1000\n\
done\n\
\n\
if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then\n\
  echo "ERROR: WebUI failed to start after $MAX_ATTEMPTS attempts"\n\
  exit 1\n\
fi\n\
\n\
# Start the handler\n\
cd /workspace\n\
exec python3 -u handler.py\n\
' > /workspace/start.sh && chmod +x /workspace/start.sh

# Set environment variables for the WebUI
ENV COMMANDLINE_ARGS="--api --xformers --listen --port 3000"

# Use the startup script as the entrypoint
ENTRYPOINT ["/workspace/start.sh"]
=======
COPY start.sh /workspace/start.sh
RUN chmod +x /workspace/start.sh

# Set environment variables for the WebUI
ENV COMMANDLINE_ARGS="--api --xformers --listen --port 3000 --skip-torch-cuda-test"

# Use the startup script as the entrypoint
ENTRYPOINT ["/workspace/start.sh"]
>>>>>>> 28e28c1 (.)
