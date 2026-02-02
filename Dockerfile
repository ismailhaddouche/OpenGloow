FROM node:22-bookworm

# Install Bun (required for build scripts)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

ARG OPENCLAW_DOCKER_APT_PACKAGES=""
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  curl \
  git \
  unzip \
  gnupg \
  ca-certificates \
  fuse \
  lsb-release \
  $OPENCLAW_DOCKER_APT_PACKAGES && \
  # Install GitHub CLI (gh)
  mkdir -p -m 755 /etc/apt/keyrings && \
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
  chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
  # Install GCS FUSE for persistent storage (with proper GPG key)
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/gcsfuse.gpg && \
  echo "deb [signed-by=/etc/apt/keyrings/gcsfuse.gpg] https://packages.cloud.google.com/apt gcsfuse-bookworm main" | tee /etc/apt/sources.list.d/gcsfuse.list > /dev/null && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gh gcsfuse && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY package.json pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

RUN pnpm install

COPY . .
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
# Force pnpm for UI build (Bun may fail on ARM/Synology architectures)
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

ENV NODE_ENV=production

# Create data directory for persistent storage
RUN mkdir -p /data/.openclaw && chown -R node:node /data

# Copy Cloud Run configuration to the expected location
RUN mkdir -p /home/node/.openclaw && \
  cp configs/cloudrun.yaml /home/node/.openclaw/config.yaml && \
  chown -R node:node /home/node/.openclaw

# Allow non-root user to write temp files during runtime/tests.
RUN chown -R node:node /app

# Security hardening: Run as non-root user
USER node

# Set OpenClaw home to the node user's home (config will be read from here)
ENV HOME=/home/node
ENV OPENCLAW_HOME=/data/.openclaw

# Cloud Run injects PORT environment variable (default 8080)
ENV PORT=8080

# Generate a random token if not provided (will be overridden by env var if set)
# The --allow-unconfigured flag allows startup without full setup
# The --token flag uses the OPENCLAW_GATEWAY_TOKEN env var
CMD node dist/index.js gateway --port $PORT --bind lan --allow-unconfigured --token ${OPENCLAW_GATEWAY_TOKEN:-cloudrun-default-token}
