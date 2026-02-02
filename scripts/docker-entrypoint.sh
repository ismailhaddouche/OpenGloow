#!/bin/sh
set -e

# Ensure the OpenClaw home directory exists
mkdir -p "$OPENCLAW_HOME"

# Copy default config if it doesn't exist in the persistent storage
if [ ! -f "$OPENCLAW_HOME/config.yaml" ]; then
  echo "Initializing OpenClaw config..."
  cp /app/configs/cloudrun.yaml "$OPENCLAW_HOME/config.yaml"
fi

# Start the gateway server
echo "Starting OpenClaw Gateway on port $PORT..."
exec node dist/index.js gateway \
  --port "$PORT" \
  --bind lan \
  --allow-unconfigured \
  --token "$OPENCLAW_GATEWAY_TOKEN"
