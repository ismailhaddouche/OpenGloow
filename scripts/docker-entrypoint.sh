#!/bin/sh
set -e

# Ensure the OpenClaw home directory exists
mkdir -p "$OPENCLAW_HOME"
mkdir -p "$OPENCLAW_HOME/devices"

# Copy default config if it doesn't exist in the persistent storage
if [ ! -f "$OPENCLAW_HOME/config.yaml" ]; then
  echo "Initializing OpenClaw config..."
  cp /app/configs/cloudrun.yaml "$OPENCLAW_HOME/config.yaml"
fi

# Create devices/pending.json with silent:true to auto-approve pairing
# This is required for Cloud Run since we can't run interactive pairing commands
cat > "$OPENCLAW_HOME/devices/pending.json" << 'EOF'
{
  "silent": true
}
EOF

echo "OpenClaw config initialized with auto-approve pairing"

# Start the gateway server
echo "Starting OpenClaw Gateway on port $PORT..."
exec node dist/index.js gateway \
  --port "$PORT" \
  --bind lan \
  --allow-unconfigured \
  --token "$OPENCLAW_GATEWAY_TOKEN"
