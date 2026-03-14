import admin from 'firebase-admin';
import { env } from './env.js';
const normalizePrivateKey = (value) => value
    .trim()
    .replace(/\r\n/g, '\n')
    .replace(/\\\n/g, '\n')
    .replace(/\\$/gm, '')
    .replace(/\\n/g, '\n');
const buildFirebaseCredential = () => {
    if (env.FIREBASE_SERVICE_ACCOUNT_JSON) {
        const parsed = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_JSON);
        if (parsed.private_key) {
            parsed.private_key = normalizePrivateKey(String(parsed.private_key));
        }
        return admin.credential.cert(parsed);
    }
    if (env.FIREBASE_PROJECT_ID && env.FIREBASE_CLIENT_EMAIL && env.FIREBASE_PRIVATE_KEY) {
        return admin.credential.cert({
            projectId: env.FIREBASE_PROJECT_ID,
            clientEmail: env.FIREBASE_CLIENT_EMAIL,
            privateKey: normalizePrivateKey(env.FIREBASE_PRIVATE_KEY)
        });
    }
    if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
        return admin.credential.applicationDefault();
    }
    return null;
};
export const initializeFirebase = () => {
    try {
        if (!admin.apps || admin.apps.length === 0) {
            const credential = buildFirebaseCredential();
            if (!credential) {
                console.warn('[FCM] Firebase Admin credentials are missing. Push notifications are disabled until you configure FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_PROJECT_ID/FIREBASE_CLIENT_EMAIL/FIREBASE_PRIVATE_KEY or GOOGLE_APPLICATION_CREDENTIALS.');
                return;
            }
            admin.initializeApp({ credential });
            console.log('[FCM] Firebase Admin initialized successfully');
        }
    }
    catch (error) {
        console.error('[FCM] Failed to initialize Firebase Admin:', error);
    }
};
//# sourceMappingURL=firebase.js.map