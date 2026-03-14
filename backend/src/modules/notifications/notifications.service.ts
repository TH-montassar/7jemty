import admin from 'firebase-admin';
import { prisma } from '../../lib/db.js';

const ANDROID_NOTIFICATION_CHANNEL_ID = 'hjamty_main_channel';

const isInvalidRegistrationTokenError = (error: unknown): boolean => {
    const code = (error as { code?: string })?.code;
    return code === 'messaging/registration-token-not-registered'
        || code === 'messaging/invalid-registration-token';
};

export const sendNotification = async (token: string, title?: string, body?: string, data?: any) => {
    try {
        if (!token) return;

        const normalizedData: Record<string, string> = {};
        if (data && typeof data === 'object') {
            Object.entries(data).forEach(([key, value]) => {
                if (value === undefined || value === null) return;
                normalizedData[key] = String(value);
            });
        }

        if (title?.trim()) {
            normalizedData.title = title.trim();
        }

        if (body?.trim()) {
            normalizedData.body = body.trim();
        }

        const message: any = {
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
            message.android.notification = {
                channelId: ANDROID_NOTIFICATION_CHANNEL_ID,
                sound: 'default'
            };
            message.apns.payload = { aps: { sound: 'default' } };
        }

        const response = await admin.messaging().send(message);
        console.log(`[FCM] Sent message successfully: ${response}`);
        return response;
    } catch (error) {
        console.error(`[FCM] Error sending message:`, error);

        if (isInvalidRegistrationTokenError(error)) {
            await prisma.profile.updateMany({
                where: { fcmToken: token },
                data: { fcmToken: null }
            });
            console.warn('[FCM] Invalid registration token detected and cleared from profile(s).');
        }
    }
};
