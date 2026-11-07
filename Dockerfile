FROM node:24-bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV CI=true

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    g++ \
    make \
    pkg-config \
    python3 \
    git \
    git-lfs \
    quilt \
    jq \
    curl \
    rsync \
    unzip \
    libx11-dev \
    libxkbfile-dev \
    libsecret-1-dev \
    libkrb5-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

# Initialize VS Code submodule
RUN git submodule sync --recursive && \
    git -c protocol.file.allow=always \
    submodule update --init --recursive

# Apply VS Code patches
RUN cd lib/vscode && quilt push -a

# Install dependencies
RUN npm install

# Build code-server
RUN npm run build

# Build VS Code Web
RUN VERSION=0.0.0 npm run build:vscode

# Create production release
RUN KEEP_MODULES=1 npm run release

EXPOSE 8080

CMD ["sh", "-c", "set -eu; : \"${PASSWORD:?PASSWORD is required}\"; mkdir -p /tmp/code-server-data /tmp/code-server-extensions /tmp/workspace; printf 'bind-addr: 0.0.0.0:%s\\nauth: password\\npassword: \"%s\"\\ncert: false\\n' \"${PORT:-8080}\" \"$PASSWORD\" > /tmp/code-server.yaml; exec ./release/bin/code-server --config /tmp/code-server.yaml --user-data-dir /tmp/code-server-data --extensions-dir /tmp/code-server-extensions /tmp/workspace"]
