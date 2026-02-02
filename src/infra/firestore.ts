import { getApps, initializeApp, cert, type App } from "firebase-admin/app";
import { getFirestore, type Firestore } from "firebase-admin/firestore";

let app: App | undefined;
let db: Firestore | undefined;

export function ensureFirestore(): Firestore {
    if (db) {
        return db;
    }

    // Use application default credentials (ADC) which works automatically on Cloud Run.
    // For local development, set GOOGLE_APPLICATION_CREDENTIALS environment variable.
    if (!getApps().length) {
        app = initializeApp();
    } else {
        app = getApps()[0];
    }

    db = getFirestore(app);

    // Optional: Set settings if needed
    db.settings({ ignoreUndefinedProperties: true });

    return db;
}

export function getFirestoreDb(): Firestore {
    return ensureFirestore();
}
