# Guía de Despliegue en Google Cloud Run (Modo Stateful)

Esta guía te permite desplegar **ClawGCP** (OpenClaw) en Google Cloud Run con persistencia de datos y ejecución continua.

## Prerrequisitos

1. Proyecto creado en [Google Cloud Console](https://console.cloud.google.com/)
2. **Firestore** activado en modo "Nativo"
3. **Cloud Run API** habilitada
4. **Cloud Build API** habilitada

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│  Google Cloud Run (gen2, CPU always allocated)              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  ClawGCP Container                                      ││
│  │  - Node.js 22                                           ││
│  │  - Gemini API (LLM)                                     ││
│  │  - GitHub CLI (gh)                                      ││
│  └─────────────────────────────────────────────────────────┘│
│            │                           │                    │
│            ▼                           ▼                    │
│  ┌─────────────────┐         ┌─────────────────────────┐   │
│  │   Firestore     │         │  Cloud Storage (GCS)    │   │
│  │   (Sessions)    │         │  (Config, Skills, Docs) │   │
│  └─────────────────┘         └─────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Configuración del Proyecto

1. **Configurar variables de entorno**:
   ```bash
   export GOOGLE_CLOUD_PROJECT="gloowgcp"  # Tu ID de proyecto
   gcloud config set project $GOOGLE_CLOUD_PROJECT
   ```

2. **Activar APIs necesarias**:
   ```bash
   gcloud services enable \
     run.googleapis.com \
     cloudbuild.googleapis.com \
     firestore.googleapis.com \
     storage.googleapis.com
   ```

## Despliegue Automático

El script de despliegue creará automáticamente:
- Un bucket de Cloud Storage para datos persistentes
- Una imagen Docker en Container Registry
- Un servicio Cloud Run con CPU siempre activa

```bash
npm run deploy:gcp
```

## Variables de Entorno en Cloud Run

El despliegue configura automáticamente:

| Variable | Valor | Descripción |
|----------|-------|-------------|
| `OPENCLAW_STORAGE` | `firestore` | Usa Firestore para sesiones |
| `NODE_ENV` | `production` | Modo producción |
| `GOOGLE_CLOUD_PROJECT` | Tu proyecto | Para autenticación ADC |
| `OPENCLAW_DATA_BUCKET` | `{proyecto}-openclaw-data` | Bucket para datos |

## Configuración del Servicio

El servicio se despliega con:

- **CPU**: 1 vCPU (siempre asignada, sin throttling)
- **RAM**: 2 GB
- **Instancias mínimas**: 1 (siempre encendida)
- **Instancias máximas**: 3 (autoescalado)
- **Entorno**: Gen2 (soporte para FUSE)

## Costes Estimados

⚠️ **Importante**: Este despliegue tiene costes fijos porque mantiene al menos 1 instancia siempre activa.

| Recurso | Coste Aproximado/mes |
|---------|---------------------|
| Cloud Run (1 vCPU, 2GB, 24/7) | ~$30-50 USD |
| Firestore (uso moderado) | ~$1-5 USD |
| Cloud Storage (10GB) | ~$0.20 USD |
| **Total estimado** | **~$35-60 USD/mes** |

## Verificación

Después del despliegue, obtendrás una URL tipo:
```
https://clawgcp-xxxxx-uc.a.run.app
```

Para verificar que funciona:
```bash
# Ver logs en tiempo real
gcloud run services logs read clawgcp --region us-central1 --follow
```

## Conexión con Canales

Una vez desplegado, configura los webhooks de tus canales de mensajería:

- **Telegram**: Configura el webhook en `@BotFather` apuntando a tu URL
- **Slack**: Configura la Event Subscription URL en tu Slack App
- **Discord**: Configura el Interactions Endpoint URL

## Rollback

Si necesitas volver a una versión anterior:
```bash
gcloud run services update-traffic clawgcp --to-revisions=REVISION_NAME=100 --region=us-central1
```

## Eliminar el Servicio

```bash
gcloud run services delete clawgcp --region=us-central1
gsutil rm -r gs://$GOOGLE_CLOUD_PROJECT-openclaw-data
```
