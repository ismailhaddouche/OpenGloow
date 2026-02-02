# Guía de Despliegue desde Google Cloud Console (UI)

Sigue estos pasos para desplegar **ClawGcp** usando la interfaz web de Google Cloud, aprovechando que ya tienes el código en GitHub.

## Prerrequisitos
1. Tener el proyecto creado en [Google Cloud Console](https://console.cloud.google.com/).
2. Tener **Firestore** activado en modo "Nativo" en la sección de Bases de Datos. (No Datastore mode).

## Paso 1: Crear Servicio en Cloud Run

1. Ve a **Cloud Run** en el menú de navegación.
2. Haz clic en **"CREAR SERVICIO"** (Create Service).

## Paso 2: Configurar la Fuente (GitHub)

1. En la opción de despliegue, selecciona:
   **"Implementar continuamente revisiones nuevas de un repositorio de origen"**.
2. Haz clic en **"CONFIGURAR CLOUD BUILD"**.
3. **Repositorio**:
   - Selecciona **GitHub**.
   - Si no has conectado tu cuenta, haz clic en "Administrar repositorios conectados" y dales acceso.
   - Selecciona el repositorio: `ismailhaddouche/OpenGloow`.
4. Haz clic en **Siguiente**.
5. **Configuración de compilación**:
   - Rama: `^main$` (o la rama que quieras desplegar).
   - Tipo de compilación: **Dockerfile**.
   - Ubicación del Dockerfile: `/Dockerfile` (déjalo por defecto).
6. Haz clic en **GUARDAR**.

## Paso 3: Configuración del Servicio

1. **Nombre del servicio**: `clawgcp` (o el que prefieras).
2. **Región**: `us-central1` (o tu preferida, ej: `europe-west1`).
3. **Autenticación**:
   - Selecciona **"Permitir invocaciones sin autenticar"** si quieres que sea accesible públicamente (necesario si vas a usar webhooks de Telegram/WhatsApp directos).
   - O "Requerir autenticación" si lo protegerás detrás de otro gateway.

## Paso 4: Variables y Secretos (IMPORTANTE)

Despliega la sección **"Contenedor, volúmenes, redes, seguridad"**:

1. Ve a la pestaña **VARIABLES Y SECRETOS**.
2. Añade las siguientes **Variables de entorno**:
   - `OPENCLAW_STORAGE` = `firestore`
   - `NODE_ENV` = `production`
   - `GOOGLE_CLOUD_PROJECT` = *(ID de tu proyecto de Google)*
3. Excluye cualquier variable local que no sea de producción.

## Paso 5: Desplegar

1. Haz clic en **CREAR**.
2. Google Cloud iniciará el "Build" automáticamente. Puedes ver el progreso en la pestaña de logs.
3. Una vez termine (tardará unos minutos en construir la imagen), te dará una **URL** (ej: `https://clawgcp-xyz-uc.a.run.app`).

## Verificación

Abre la URL en tu navegador. Deberías ver la respuesta del servidor o, si no hay interfaz web configurada en `/`, consulta los **Registros (Logs)** en la consola para confirmar que el sistema arrancó correctamente conectado a Firestore y Gemini.
