FROM node:24-trixie

ENV DEBIAN_FRONTEND=noninteractive
ENV CI=true

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
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
    ca-certificates \
    libx11-dev \
    libxkbfile-dev \
    libsecret-1-dev \
    libkrb5-dev \
    && rm -rf /var/lib/apt/lists/*

# Verify compiler version
RUN echo "=== Compiler versions ===" \
    && gcc --version \
    && g++ --version \
    && test "$(g++ -dumpversion | cut -d. -f1)" -ge 13

WORKDIR /app

# Clone code-server with its VS Code submodule
RUN git clone \
    --depth 1 \
    --recurse-submodules \
    --shallow-submodules \
    https://github.com/shibihu/code-server.git .

# Verify VS Code source exists
RUN test -f lib/vscode/package.json

# Apply patches
RUN quilt push -a

# Install code-server dependencies
RUN npm install

# Build code-server
RUN npm run build

# Build VS Code
RUN VERSION=0.0.0 npm run build:vscode

# Create release
RUN KEEP_MODULES=1 npm run release

EXPOSE 8080

# Start code-server
CMD ["sh", "-c", "set -eu; : \"${PASSWORD:?PASSWORD environment variable is required}\"; mkdir -p /tmp/code-server-data /tmp/code-server-extensions /tmp/workspace; node -e 'const fs=require(\"fs\"); const p=process.env.PASSWORD; const port=process.env.PORT||8080; fs.writeFileSync(\"/tmp/code-server.yaml\", \"bind-addr: 0.0.0.0:\"+port+\"\\nauth: password\\npassword: \"+JSON.stringify(p)+\"\\ncert: false\\n\")'; exec ./release/bin/code-server --config /tmp/code-server.yaml --user-data-dir /tmp/code-server-data --extensions-dir /tmp/code-server-extensions /tmp/workspace"]
