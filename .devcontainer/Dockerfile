# Use Python 3.11 as base
FROM python:3.11-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y \
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
    # For ChromaDB
    libgomp1 \
    # For GPU support
    ocl-icd-opencl-dev \
    # For PDF processing
    poppler-utils \
    # For audio/video
    ffmpeg \
    # Clean up
    && rm -rf /var/lib/apt/lists/*

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
    && npm install -g npm@latest

# Install pnpm
RUN npm install -g pnpm

# Create directories with proper permissions
RUN mkdir -p /workspace /workspace-data /workspace-models /workspace-db \
    && chown -R ${USERNAME}:${USERNAME} /workspace /workspace-data /workspace-models /workspace-db

# Switch to non-root user
USER ${USERNAME}
WORKDIR /workspace

# Set up Python environment
RUN uv venv /workspace/.venv
ENV PATH="/workspace/.venv/bin:$PATH"

# Copy requirements and install Python packages
COPY --chown=${USERNAME}:${USERNAME} requirements.txt /tmp/requirements.txt
RUN uv pip install --system -r /tmp/requirements.txt

# Default command
CMD ["sleep", "infinity"]
