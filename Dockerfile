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
  $OPENCLAW_DOCKER_APT_PACKAGES && \
  # Install GitHub CLI (gh)
  mkdir -p -m 755 /etc/apt/keyrings && \
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
  chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
  # Install GCS FUSE for persistent storage
  echo "deb https://packages.cloud.google.com/apt gcsfuse-bookworm main" | tee /etc/apt/sources.list.d/gcsfuse.list && \
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list && \
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

# Allow non-root user to write temp files during runtime/tests.
RUN chown -R node:node /app

# Security hardening: Run as non-root user
# The node:22-bookworm image includes a 'node' user (uid 1000)
# This reduces the attack surface by preventing container escape via root privileges
USER node

# Set OpenClaw home to mounted volume
ENV OPENCLAW_HOME=/data/.openclaw

# Entrypoint script to optionally mount GCS bucket before starting
COPY --chown=node:node scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh || true

CMD ["node", "dist/index.js"]
