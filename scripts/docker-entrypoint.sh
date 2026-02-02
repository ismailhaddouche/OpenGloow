#!/bin/bash
set -e

# Mount GCS bucket if OPENCLAW_DATA_BUCKET is set
if [ -n "$OPENCLAW_DATA_BUCKET" ]; then
  echo "Mounting GCS bucket: $OPENCLAW_DATA_BUCKET to /data"
  gcsfuse --implicit-dirs "$OPENCLAW_DATA_BUCKET" /data || echo "Warning: GCS FUSE mount failed, using ephemeral storage"
fi

# Execute the main command
exec "$@"
