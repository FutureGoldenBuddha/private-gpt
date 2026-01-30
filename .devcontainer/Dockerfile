# Use NVIDIA CUDA base image
FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

# Set Python version
ENV PYTHON_VERSION=3.11
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python${PYTHON_VERSION}-venv \
    python3-pip \
    git \
    curl \
    wget \
    vim \
    nano \
    htop \
    build-essential \
    cmake \
    pkg-config \
    libssl-dev \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    libjpeg-dev \
    libpng-dev \
    libopenblas-dev \
    liblapack-dev \
    gfortran \
    libgomp1 \
    ocl-icd-opencl-dev \
    poppler-utils \
    ffmpeg \
    # NVIDIA/CUDA dependencies
    cuda-toolkit-12-1 \
    cuda-cudart-dev-12-1 \
    cuda-cupti-dev-12-1 \
    cuda-nvtx-12-1 \
    # Clean up
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1

# Install uv (modern Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    ln -s /root/.cargo/bin/uv /usr/local/bin/uv

# Create non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# Install Node.js for UI
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest pnpm

# Create directories with proper permissions
RUN mkdir -p /workspace /workspace-data /workspace-models /workspace-db \
    && chown -R ${USERNAME}:${USERNAME} /workspace /workspace-data /workspace-models /workspace-db

# Switch to non-root user
USER ${USERNAME}
WORKDIR /workspace

# Set up Python environment
RUN uv venv /workspace/.venv
ENV PATH="/workspace/.venv/bin:$PATH"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"

# Copy requirements and install Python packages with CUDA support
COPY --chown=${USERNAME}:${USERNAME} requirements-cuda.txt /tmp/requirements.txt
RUN uv pip install --system -r /tmp/requirements.txt

# Verify CUDA installation
RUN python -c "import torch; print(f'PyTorch CUDA available: {torch.cuda.is_available()}'); print(f'CUDA version: {torch.version.cuda}')" && \
    python -c "import tensorflow as tf; print(f'TensorFlow GPU devices: {tf.config.list_physical_devices(\"GPU\")}')" || echo "TensorFlow not installed"

# Default command
CMD ["sleep", "infinity"]
