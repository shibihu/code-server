FROM node:24-bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    g++ \
    make \
    pkg-config \
    python3 \
    git \
    quilt \
    jq \
    curl \
    libx11-dev \
    libxkbfile-dev \
    libsecret-1-dev \
    libkrb5-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy code-server source
COPY . .

# Apply VS Code patches
RUN quilt push -a

# Install dependencies
RUN npm install

# Build code-server
RUN npm run build

# Build VS Code Web
RUN VERSION=0.0.0 npm run build:vscode

# Create production release
RUN KEEP_MODULES=1 npm run release

# Render web service port
EXPOSE 8080

# Start code-server
CMD ["sh", "-c", "test -n \"$PASSWORD\" || (echo 'PASSWORD is required' && exit 1); mkdir -p /tmp/code-server-data /tmp/code-server-extensions /tmp/workspace; printf 'bind-addr: 0.0.0.0:%s\\nauth: password\\npassword: \"%s\"\\ncert: false\\n' \"${PORT:-8080}\" \"$PASSWORD\" > /tmp/code-server.yaml; exec ./release/bin/code-server --config /tmp/code-server.yaml --user-data-dir /tmp/code-server-data --extensions-dir /tmp/code-server-extensions /tmp/workspace"]
