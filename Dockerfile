FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a working directory
WORKDIR /workspace

# Clone the Stable Diffusion WebUI Forge repository
RUN git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git

# Set up the RunPod handler
COPY handler.py /workspace/handler.py
RUN pip3 install runpod torch==2.0.1+cu118 torchvision==0.15.2+cu118 -f https://download.pytorch.org/whl/torch_stable.html

# Create directory for models
RUN mkdir -p /workspace/stable-diffusion-webui-forge/models/Stable-diffusion

# Download a model directly to the correct location
RUN wget -q -O /workspace/stable-diffusion-webui-forge/models/Stable-diffusion/MAI_Pony-v1R.safetensors \
    https://huggingface.co/Meowmeow42/NewStart/resolve/main/MAI_Pony-v1R.safetensors

# Install dependencies for WebUI Forge
WORKDIR /workspace/stable-diffusion-webui-forge
RUN pip3 install -r requirements_versions.txt

# Configure to run in API mode when the handler executes it
ENV COMMANDLINE_ARGS="--api --xformers --listen --port 3000 --headless"

# Set up the entrypoint
WORKDIR /workspace
ENTRYPOINT ["python3", "-u", "handler.py"]