import admin from 'firebase-admin';
export const sendNotification = async (token, title, body, data) => {
    try {
        if (!token)
            return;
        const normalizedData = {};
        if (data && typeof data === 'object') {
            Object.entries(data).forEach(([key, value]) => {
                if (value === undefined || value === null)
                    return;
                normalizedData[key] = String(value);
            });
        }
        const message = {
            token,
            data: normalizedData,
            android: {
                priority: 'high',
            },
            apns: {
                headers: {
                    'apns-priority': '10',
                },
            },
        };
        if (title || body) {
            message.notification = {
                title: title || '',
                body: body || '',
            };
            message.android.notification = { sound: 'default' };
            message.apns.payload = { aps: { sound: 'default' } };
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