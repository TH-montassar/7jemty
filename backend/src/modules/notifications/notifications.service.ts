import admin from 'firebase-admin';

export const sendNotification = async (token: string, title: string, body: string, data?: any) => {
    try {
        if (!token) return;

        const message = {
            notification: {
                title,
                body,
            },
            data: data || {},
            token,
        };

        const response = await admin.messaging().send(message);
        console.log(`[FCM] Sent message successfully: ${response}`);
        return response;
    } catch (error) {
        console.error(`[FCM] Error sending message:`, error);
    }
};
