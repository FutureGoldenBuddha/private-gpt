#!/bin/bash

set -e

echo "🚀 Setting up PrivateGPT Development Environment..."

# Clone PrivateGPT if not already in workspace
if [ ! -f "/workspace/pyproject.toml" ]; then
    echo "📦 Cloning PrivateGPT repository..."
    git clone https://github.com/imartinez/privateGPT.git /tmp/privateGPT-temp
    cp -r /tmp/privateGPT-temp/. /workspace/
    rm -rf /tmp/privateGPT-temp
fi

# Ensure directories exist
sudo mkdir -p /workspace-data /workspace-models /workspace-db /workspace-db/chroma
sudo chown -R vscode:vscode /workspace /workspace-data /workspace-models /workspace-db

# Set up Python environment
cd /workspace
if [ ! -d "/workspace/.venv" ]; then
    echo "🐍 Creating Python virtual environment..."
    uv venv .venv
fi

# Activate virtual environment
source .venv/bin/activate

# Install PrivateGPT and dependencies
echo "📦 Installing Python dependencies..."
uv pip install --system -e ".[local,ui,test]"

# Install additional development tools
echo "🔧 Installing development tools..."
uv pip install --system \
    jupyterlab \
    ipykernel \
    black \
    isort \
    mypy \
    pytest \
    pytest-cov \
    pytest-asyncio \
    pre-commit \
    watchdog \
    rope

# Set up pre-commit hooks
echo "⚙️ Setting up pre-commit..."
pre-commit install

# Install Node.js dependencies for UI if present
if [ -f "/workspace/ui/package.json" ]; then
    echo "📦 Installing Node.js dependencies..."
    cd /workspace/ui
    npm install || yarn install || pnpm install
    cd /workspace
fi

# Create default environment file
echo "⚙️ Creating environment configuration..."
cat > /workspace/.env << 'EOF'
# PrivateGPT Development Environment
PGPT_PROFILES=local,dev
PGPT_DATA_DIR=/workspace-data
PGPT_MODELS_DIR=/workspace-models
PGPT_DB_DIR=/workspace-db

# Database URLs
DATABASE_URL=postgresql://privategpt:privategpt123@postgres:5432/privategpt
REDIS_URL=redis://redis:6379/0
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin123

# LLM Settings (configure in .env.local)
# OPENAI_API_KEY=
# ANTHROPIC_API_KEY=
# GROQ_API_KEY=
# TOGETHER_API_KEY=

# Local Model Paths
LOCAL_LLM_MODEL_PATH=/workspace-models/mistral-7b-instruct-v0.2.Q4_K_M.gguf
LOCAL_EMBEDDING_MODEL_PATH=/workspace-models/all-MiniLM-L6-v2

# ChromaDB Settings
CHROMA_PERSIST_DIRECTORY=/workspace-db/chroma
CHROMA_COLLECTION_NAME=privategpt

# Server Settings
API_HOST=0.0.0.0
API_PORT=8000
UI_PORT=8501
JUPYTER_PORT=8888

# Logging
LOG_LEVEL=INFO
LOG_FILE=/workspace-data/privategpt.log
EOF

# Create local environment file template
cat > /workspace/.env.local.template << 'EOF'
# Copy to .env.local and fill in your API keys
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here
GROQ_API_KEY=your_groq_api_key_here
TOGETHER_API_KEY=your_together_api_key_here
COHERE_API_KEY=your_cohere_api_key_here
EOF

# Download sample model if not present
echo "🤖 Checking for models..."
if [ ! -f "/workspace-models/mistral-7b-instruct-v0.2.Q4_K_M.gguf" ]; then
    echo "📥 Would you like to download a sample model? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "📥 Downloading sample model..."
        cd /workspace-models
        wget -q --show-progress \
            https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf \
            -O mistral-7b-instruct-v0.2.Q4_K_M.gguf || \
        echo "⚠️ Model download failed. You can download manually to /workspace-models/"
    fi
fi

# Download embedding model
if [ ! -d "/workspace-models/all-MiniLM-L6-v2" ]; then
    echo "📥 Downloading embedding model..."
    python -c "
from sentence_transformers import SentenceTransformer
model = SentenceTransformer('all-MiniLM-L6-v2')
model.save('/workspace-models/all-MiniLM-L6-v2')
print('✅ Embedding model downloaded')
" || echo "⚠️ Failed to download embedding model"
fi

# Create helper scripts
echo "📝 Creating helper scripts..."

cat > /usr/local/bin/start-api << 'EOF'
#!/bin/bash
cd /workspace
source .venv/bin/activate
python -m private_gpt
EOF

cat > /usr/local/bin/start-ui << 'EOF'
#!/bin/bash
cd /workspace
source .venv/bin/activate
streamlit run private_gpt/ui/streamlit.py --server.port 8501 --server.address 0.0.0.0
EOF

cat > /usr/local/bin/start-jupyter << 'EOF'
#!/bin/bash
cd /workspace
source .venv/bin/activate
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root
EOF

cat > /usr/local/bin/ingest-docs << 'EOF'
#!/bin/bash
cd /workspace
source .venv/bin/activate
python scripts/ingest.py "$@"
EOF

chmod +x /usr/local/bin/start-api /usr/local/bin/start-ui /usr/local/bin/start-jupyter /usr/local/bin/ingest-docs

# Set permissions
sudo chown -R vscode:vscode /workspace /workspace-data /workspace-models /workspace-db

echo "✅ Setup complete!"
echo ""
echo "📋 Available commands:"
echo "  start-api       - Start PrivateGPT API server"
echo "  start-ui        - Start Streamlit UI"
echo "  start-jupyter   - Start Jupyter Lab"
echo "  ingest-docs     - Ingest documents"
echo ""
echo "🌐 Services:"
echo "  - UI:          http://localhost:8501"
echo "  - API:         http://localhost:8000"
echo "  - Jupyter:     http://localhost:8888"
echo "  - MinIO Console: http://localhost:9001"
echo ""
echo "📁 Data locations:"
echo "  - Code:        /workspace"
echo "  - Documents:   /workspace-data"
echo "  - Models:      /workspace-models"
echo "  - Database:    /workspace-db"
echo ""
echo "🐳 Docker services:"
echo "  - PostgreSQL:  localhost:5432 (user: privategpt, pass: privategpt123)"
echo "  - Redis:       localhost:6379"
echo "  - MinIO:       localhost:9000"
