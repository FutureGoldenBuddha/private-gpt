#!/bin/bash

set -e

echo "🚀 Setting up PrivateGPT with NVIDIA GPU Support..."

# Check GPU
echo "🔍 Checking GPU..."
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi
else
    echo "⚠️ nvidia-smi not found. GPU may not be available."
fi

# Clone PrivateGPT if needed
if [ ! -f "/workspace/pyproject.toml" ]; then
    echo "📦 Cloning PrivateGPT repository..."
    git clone https://github.com/imartinez/privateGPT.git /tmp/privateGPT-temp
    cp -r /tmp/privateGPT-temp/. /workspace/
    rm -rf /tmp/privateGPT-temp
fi

# Ensure directories
sudo mkdir -p /workspace-data /workspace-models /workspace-db /workspace-db/chroma
sudo chown -R vscode:vscode /workspace /workspace-data /workspace-models /workspace-db

# Set up Python environment
cd /workspace
if [ ! -d "/workspace/.venv" ]; then
    echo "🐍 Creating Python virtual environment..."
    uv venv .venv
fi

source .venv/bin/activate

# Install with GPU support
echo "📦 Installing Python dependencies with CUDA support..."
uv pip install --system -e ".[local,ui,test]" || echo "⚠️ PrivateGPT installation failed, continuing..."

# Install GPU monitoring tools
echo "📊 Installing GPU monitoring tools..."
uv pip install --system nvidia-ml-py gpustat

# Test GPU
echo "🧪 Testing GPU..."
python -c "
import torch
print(f'PyTorch Version: {torch.__version__}')
print(f'CUDA Available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'CUDA Device Count: {torch.cuda.device_count()}')
    print(f'Current CUDA Device: {torch.cuda.current_device()}')
    print(f'CUDA Device Name: {torch.cuda.get_device_name(0)}')
    print(f'CUDA Memory Allocated: {torch.cuda.memory_allocated(0) / 1e9:.2f} GB')
    print(f'CUDA Memory Cached: {torch.cuda.memory_reserved(0) / 1e9:.2f} GB')
"

# Create environment file
echo "⚙️ Creating environment configuration..."
cat > /workspace/.env << 'EOF'
# GPU Configuration
PGPT_PROFILES=local,dev,gpu
PGPT_DEVICE=cuda:0

# Paths
PGPT_DATA_DIR=/workspace-data
PGPT_MODELS_DIR=/workspace-models
PGPT_DB_DIR=/workspace-db

# GPU Settings
TORCH_CUDA_ARCH_LIST=7.5;8.0;8.6;8.9;9.0
TF_FORCE_GPU_ALLOW_GROWTH=true

# Database
CHROMA_PERSIST_DIRECTORY=/workspace-db/chroma

# Server
API_HOST=0.0.0.0
API_PORT=8000
UI_PORT=8501
EOF

# Helper scripts
echo "📝 Creating helper scripts..."

cat > /usr/local/bin/gpu-info << 'EOF'
#!/bin/bash
python -c "
import torch
print('=== GPU Information ===')
print(f'PyTorch CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    for i in range(torch.cuda.device_count()):
        print(f'GPU {i}: {torch.cuda.get_device_name(i)}')
        print(f'  Memory: {torch.cuda.get_device_properties(i).total_memory / 1e9:.2f} GB')
"
gpustat --color
EOF

chmod +x /usr/local/bin/gpu-info

# Set permissions
sudo chown -R vscode:vscode /workspace /workspace-data /workspace-models /workspace-db

echo "✅ GPU Setup complete!"
echo ""
echo "📋 Commands:"
echo "  gpu-info           - Show GPU information"
echo "  start-api          - Start API server"
echo "  start-ui           - Start Streamlit UI"
echo ""
echo "🎯 GPU Device:"
gpu-info
