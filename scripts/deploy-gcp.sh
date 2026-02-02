#!/bin/bash
set -e

# Configuration
PROJECT_ID=${GOOGLE_CLOUD_PROJECT:-""}
SERVICE_NAME="clawgcp"
REGION="us-central1"
IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVICE_NAME"
# Bucket for persistent storage (config, skills, etc.)
STORAGE_BUCKET="${OPENCLAW_STORAGE_BUCKET:-$PROJECT_ID-openclaw-data}"
VOLUME_NAME="openclaw-data"

# Generate a secure gateway token if not provided
GATEWAY_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)}"

if [ -z "$PROJECT_ID" ]; then
  echo "Error: GOOGLE_CLOUD_PROJECT environment variable is not set."
  echo "Usage: GOOGLE_CLOUD_PROJECT=my-project ./scripts/deploy-gcp.sh"
  exit 1
fi

echo "🚀 Deploying ClawGCP to Google Cloud Run..."
echo "Project: $PROJECT_ID"
echo "Service: $SERVICE_NAME"
echo "Region:  $REGION"
echo "Storage: gs://$STORAGE_BUCKET"
echo ""

# 0. Create storage bucket if it doesn't exist
echo "📦 Ensuring storage bucket exists..."
gsutil ls -b "gs://$STORAGE_BUCKET" 2>/dev/null || gsutil mb -l "$REGION" "gs://$STORAGE_BUCKET"

# 1. Build and Submit Image to Container Registry
echo ""
echo "📦 Building container image..."
gcloud builds submit --tag "$IMAGE_NAME" .

# 2. Deploy to Cloud Run with stateful configuration + GCS FUSE volume
echo ""
echo "🚀 Deploying service (stateful mode with persistent storage)..."

# Note: Cloud Run Gen2 with GCS FUSE volume mounting
# --add-volume: defines a Cloud Storage volume
# --add-volume-mount: mounts it inside the container
gcloud run deploy "$SERVICE_NAME" \
  --image "$IMAGE_NAME" \
  --platform managed \
  --region "$REGION" \
  --allow-unauthenticated \
  --memory=2Gi \
  --cpu=1 \
  --min-instances=1 \
  --max-instances=3 \
  --no-cpu-throttling \
  --execution-environment=gen2 \
  --add-volume=name=$VOLUME_NAME,type=cloud-storage,bucket=$STORAGE_BUCKET \
  --add-volume-mount=volume=$VOLUME_NAME,mount-path=/data \
  --set-env-vars="OPENCLAW_STORAGE=firestore,NODE_ENV=production,GOOGLE_CLOUD_PROJECT=$PROJECT_ID,OPENCLAW_HOME=/data/.openclaw,OPENCLAW_GATEWAY_TOKEN=$GATEWAY_TOKEN"

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Service URL:"
SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --platform managed --region "$REGION" --format 'value(status.url)')
echo "$SERVICE_URL"

echo ""
echo "🔐 Gateway Token (save this!):"
echo "   $GATEWAY_TOKEN"

echo ""
echo "⚠️  IMPORTANT: This deployment uses:"
echo "   - CPU always allocated (no throttling)"
echo "   - Minimum 1 instance always running"
echo "   - 2GB RAM per instance"
echo "   - GCS bucket mounted at /data for persistent storage"
echo "   This incurs continuous costs. Monitor billing at: https://console.cloud.google.com/billing"
