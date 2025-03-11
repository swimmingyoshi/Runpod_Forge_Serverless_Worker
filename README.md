# Runpod_Forge_Serverless_Worker
# Stable Diffusion WebUI Forge - RunPod Serverless Worker

This repository contains the necessary files to build and deploy a serverless worker on RunPod that runs the [Stable Diffusion WebUI Forge](https://github.com/lllyasviel/stable-diffusion-webui-forge) fork.

## Setup Instructions

### 1. Prerequisites

- A RunPod account with API key
- Docker installed on your local machine (for building the container)
- Git installed on your local machine

### 2. Building the Docker Container

1. Clone this repository to your local machine:
   ```bash
   git clone https://github.com/yourusername/runpod-sdwebui-forge.git
   cd runpod-sdwebui-forge
   ```

2. Build the Docker container:
   ```bash
   docker build -t yourusername/runpod-sdwebui-forge:latest .
   ```

3. Push the container to Docker Hub:
   ```bash
   docker login
   docker push yourusername/runpod-sdwebui-forge:latest
   ```

### 3. Creating a RunPod Serverless Template

1. Go to the RunPod dashboard: https://www.runpod.io/console/serverless
2. Click on "Templates" in the left sidebar
3. Click "New Template"
4. Fill in the template details:
   - Name: SD WebUI Forge
   - Container Image: yourusername/runpod-sdwebui-forge:latest
   - Container Disk: 20 GB (or more if you plan to download many models)
   - Container Environment Variables: None required, but you can add custom ones if needed
   - Use any additional settings as needed (e.g., enabling GPU, setting GPU requirements)

5. Click "Save Template"

### 4. Deploying the Serverless Endpoint

1. Go to "Endpoints" in the left sidebar
2. Click "New Endpoint"
3. Select your template: SD WebUI Forge
4. Configure the settings:
   - Name: sd-webui-forge
   - Min Idle Workers: Set based on your needs (0 for cost efficiency, 1+ for instant responses)
   - Max Workers: Set based on your expected load
   - GPU Type: Select an appropriate GPU (A100, A5000, etc.)
   - Flash Boot: Enable if available

5. Click "Deploy"

## Using the Serverless Endpoint

### Example Requests

You can interact with your endpoint using the RunPod API. Here are some example requests:

#### 1. Download and use a specific model:

```json
{
  "input": {
    "model_url": "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors",
    "model_name": "v1-5-pruned-emaonly.safetensors",
    "endpoint": "txt2img",
    "payload": {
      "prompt": "A beautiful mountain landscape",
      "negative_prompt": "ugly, blurry",
      "steps": 30,
      "width": 512,
      "height": 512,
      "cfg_scale": 7
    }
  }
}
```

#### 2. Use a pre-existing model:

```json
{
  "input": {
    "model_name": "v1-5-pruned-emaonly.safetensors",
    "endpoint": "txt2img",
    "payload": {
      "prompt": "A futuristic cityscape",
      "negative_prompt": "ugly, blurry",
      "steps": 30,
      "width": 512,
      "height": 512,
      "cfg_scale": 7
    }
  }
}
```

### Available Endpoints

The handler supports all the standard Stable Diffusion WebUI API endpoints. Some common ones include:

- `txt2img`: Generate images from text prompts
- `img2img`: Generate images based on input images and text prompts
- `extra-single-image`: Perform upscaling or face restoration
- `interrogate`: Extract captions from images

## Troubleshooting

### Common Issues

1. **API Not Responding**: The WebUI might take time to start up. The handler will wait for up to 5 minutes, but if you have a very large model, it might take longer. Consider increasing the timeout in the handler.py file.

2. **Model Loading Issues**: Check that the model URL is accessible and the file format is supported.

3. **Out of Memory Errors**: If you're encountering OOM errors, try a GPU with more VRAM or reduce the image dimensions and batch size in your requests.

### Logs

You can view the logs for your serverless endpoint in the RunPod dashboard under Endpoints > (your endpoint) > Logs. This can be helpful for diagnosing issues.

## Advanced Configuration

### Custom Extensions

To add custom extensions to the WebUI Forge, modify the Dockerfile to clone the extension repositories into the extensions folder:

```dockerfile
# Example of adding ControlNet extension
RUN git clone https://github.com/Mikubill/sd-webui-controlnet.git /workspace/stable-diffusion-webui-forge/extensions/sd-webui-controlnet
```

### Persistent Storage

For persistent storage of models and outputs, you can attach a RunPod Network Volume to your endpoint and modify the handler to use this volume.

## Further Resources

- [Stable Diffusion WebUI Forge GitHub Repository](https://github.com/lllyasviel/stable-diffusion-webui-forge)
- [RunPod Serverless Documentation](https://docs.runpod.io/serverless)
- [Stable Diffusion WebUI API Documentation](https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/API)