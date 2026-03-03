import admin from 'firebase-admin';

export const initializeFirebase = () => {
    try {
        if (!admin.apps || admin.apps.length === 0) {
            admin.initializeApp({
                credential: admin.credential.applicationDefault()
            });
            console.log('✅ Firebase Admin initialized successfully');
        }
    } catch (error) {
        console.error('❌ Failed to initialize Firebase Admin:', error);
    }
};
