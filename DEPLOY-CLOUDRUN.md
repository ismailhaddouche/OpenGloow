# Deployment Guide: Google Cloud Run & Firestore

This guide outlines how to deploy **ClawGcp** (formerly OpenClaw) to Google Cloud Run, operating as a Sovereign AI Agent with persistent state in Firestore.

## Architecture

- **Compute**: Google Cloud Run (Serverless, scales to zero).
- **Database**: Google Cloud Firestore (Session storage, persistent state).
- **AI Model**: Google Gemini 1.5 Pro (via Vertex AI or Gemini API).
- **Authentication**: Application Default Credentials (ADC) for infrastructure; OAuth/API Keys for specific agent tools.

## Prerequisites

1. Google Cloud Project with Billing enabled.
2. `gcloud` CLI installed and authenticated.
3. Firestore database created in Native mode.
4. (Optional) Firebase project linked for specific Firebase features.

## Configuration

Set the following environment variables in your Cloud Run service:

- `OPENCLAW_STORAGE=firestore` (Enables the Firestore session adapter)
- `GOOGLE_CLOUD_PROJECT=<your-project-id>`
- `NODE_ENV=production`

### Secrets management
For API keys (e.g., Twilio, Telegram, Slack), use **Google Secret Manager**:

1. Create a secret in GCP console (e.g., `CLAW_TELEGRAM_TOKEN`).
2. Grant the Cloud Run service account access to the secret.
3. Expose the secret as an environment variable in Cloud Run.

## Build and Deploy

### 1. Build the Container
Using Cloud Build (recommended):
```bash
gcloud builds submit --tag gcr.io/PROJECT_ID/clawgcp
```

Or Docker locally:
```bash
docker build -t gcr.io/PROJECT_ID/clawgcp .
docker push gcr.io/PROJECT_ID/clawgcp
```

### 2. Deploy to Cloud Run
```bash
gcloud run deploy clawgcp \
  --image gcr.io/PROJECT_ID/clawgcp \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars OPENCLAW_STORAGE=firestore
```

*Note: `--allow-unauthenticated` allows public HTTP access (e.g., for Webhooks). If intended for private use only, use `--no-allow-unauthenticated`.*

## Migrating from Legacy OpenClaw

### Session Storage
The application now supports `OPENCLAW_STORAGE=firestore`. This replaces the file-based `sessions.json`. 
- **New Sessions**: Automatically created in Firestore `sessions` collection.
- **Legacy Sessions**: To migrate existing JSON sessions, a migration script (to be implemented) would read `sessions.json` and write to Firestore using `persistSession`.

### Google Workspace Integrations
Supported Google Workspace integrations (Docs, Drive, etc.) rely on the configured AI Model (Gemini) having access to these tools via Extensions or separate Auth tokens. Ensure your Service Account or User OAuth token has the necessary scopes (`https://www.googleapis.com/auth/drive`, etc.).

## Troubleshooting

- **Logs**: View logs in Google Cloud Console > Cloud Run > Logs.
- **Permissions**: Ensure the "Compute Engine default service account" (or your custom SA) has "Cloud Datastore User" role.
