import admin from 'firebase-admin';
export const sendNotification = async (token, title, body, data) => {
    try {
        if (!token)
            return;
        const message = {
            data: data || {},
            token,
        };
        if (title || body) {
            message.notification = {
                title: title || '',
                body: body || '',
            };
        }
        const response = await admin.messaging().send(message);
        console.log(`[FCM] Sent message successfully: ${response}`);
        return response;
    }
    catch (error) {
        console.error(`[FCM] Error sending message:`, error);
    }
};
//# sourceMappingURL=notifications.service.js.map