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

# Install PyTorch with CUDA support
WORKDIR /workspace/stable-diffusion-webui-forge
RUN pip3 install --no-cache-dir torch==2.0.1+cu118 torchvision==0.15.2+cu118 \
    --extra-index-url https://download.pytorch.org/whl/cu118

# Install WebUI dependencies
RUN pip3 install --no-cache-dir -r requirements_versions.txt
RUN pip3 install --no-cache-dir xformers==0.0.21

# Pre-download a model
RUN mkdir -p /workspace/stable-diffusion-webui-forge/models/Stable-diffusion
RUN wget -q -O /workspace/stable-diffusion-webui-forge/models/Stable-diffusion/MAI_Pony-v1R.safetensors \
    https://huggingface.co/Meowmeow42/NewStart/resolve/main/MAI_Pony-v1R.safetensors

# Copy the handler
WORKDIR /workspace
COPY handler.py /workspace/handler.py
COPY start.sh /workspace/start.sh
RUN chmod +x /workspace/start.sh

# Set environment variables for the WebUI
ENV COMMANDLINE_ARGS="--api --xformers --listen --port 3000 --skip-torch-cuda-test"

# Use the startup script as the entrypoint
ENTRYPOINT ["/workspace/start.sh"]
