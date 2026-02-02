#!/bin/bash
set -e

# Configuration
PROJECT_ID=${GOOGLE_CLOUD_PROJECT:-""}
SERVICE_NAME="clawgcp"
REGION="us-central1"
IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVICE_NAME"

if [ -z "$PROJECT_ID" ]; then
  echo "Error: GOOGLE_CLOUD_PROJECT environment variable is not set."
  echo "Usage: GOOGLE_CLOUD_PROJECT=my-project ./scripts/deploy-gcp.sh"
  exit 1
fi

echo "🚀 Deploying ClawGCP to Google Cloud Run..."
echo "Project: $PROJECT_ID"
echo "Service: $SERVICE_NAME"
echo "Region:  $REGION"

# 1. Build and Submit Image to Container Registry
echo ""
echo "📦 Building container image..."
gcloud builds submit --tag "$IMAGE_NAME" .

# 2. Deploy to Cloud Run
echo ""
echo "🚀 Deploying service..."
gcloud run deploy "$SERVICE_NAME" \
  --image "$IMAGE_NAME" \
  --platform managed \
  --region "$REGION" \
  --allow-unauthenticated \
  --set-env-vars="OPENCLAW_STORAGE=firestore,NODE_ENV=production"

echo ""
echo "✅ Deployment complete!"
echo "Service URL:"
gcloud run services describe "$SERVICE_NAME" --platform managed --region "$REGION" --format 'value(status.url)'
