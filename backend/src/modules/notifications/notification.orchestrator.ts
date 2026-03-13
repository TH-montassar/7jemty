import { prisma } from '../../lib/db.js';
import { sendNotification } from './notifications.service.js';
import { broadcastNotificationToUser } from './notifications.controller.js';
import {
    CLIENT_CANCELLATION_LOCK_HOURS,
    CLIENT_CANCELLATION_PRELOCK_REMINDER_MINUTES
} from '../appointment/appointment.constants.js';

type RecipientRole = 'CLIENT' | 'BARBER' | 'PATRON';
type NotificationPriority = 'LOW' | 'NORMAL' | 'HIGH';
type TransportType = 'APPOINTMENT_UPDATED' | 'APPOINTMENT_REMINDER';

export type AppointmentNotificationEvent =
    | 'APPT_CREATED'
    | 'APPT_CONFIRMED'
    | 'APPT_CANCELLED'
    | 'APPT_DECLINED'
    | 'APPT_COMPLETED'
    | 'APPT_SHIFTED'
    | 'APPT_REMINDER_1H10_CLIENT'
    | 'APPT_REMINDER_1H10_BARBER'
    | 'APPT_CLIENT_LOCK_LT_1H'
    | 'APPT_REMINDER_LT_1H_BARBER'
    | 'APPT_REMINDER_30M'
    | 'APPT_BARBER_REMINDER_30M'
    | 'APPT_PATRON_EMPLOYEE_REMINDER_30M'
    | 'APPT_REMINDER_15M'
    | 'APPT_REMINDER_1M'
    | 'APPT_BARBER_ARRIVAL_CHECK'
    | 'APPT_CLIENT_START_NOW'
    | 'APPT_BARBER_COMPLETION_CHECK';

type AppointmentEventTemplate = {
    transportType: TransportType;
    recipientRoles?: RecipientRole[];
    title: (ctx: AppointmentEventContext) => string;
    body: (ctx: AppointmentEventContext) => string;
    priority?: NotificationPriority;
    persistInDb?: boolean;
    sendPush?: boolean;
    dedupeWindowMs?: number;
};

export type AppointmentEventContext = {
    appointmentId: number;
    appointmentDate?: Date | undefined;
    status?: string | undefined;
    clientId?: number | undefined;
    barberId?: number | null | undefined;
    patronId?: number | undefined;
    clientName?: string | undefined;
    actorUserId?: number | undefined;
    actorRole?: 'CLIENT' | 'EMPLOYEE' | 'PATRON' | 'ADMIN' | undefined;
    deeplink?: string | undefined;
    targetUserIds?: number[] | undefined;
    extraData?: Record<string, string | number | boolean | undefined> | undefined;
    dedupeWindowMs?: number | undefined;
};

type RefreshPayload = {
    appointmentId: number;
    status?: string | undefined;
    userIds: number[];
    deeplink?: string | undefined;
};

const DEFAULT_DEDUPE_WINDOW_MS = 90_000;
const dedupeCache = new Map<string, number>();
const cancellationLockHoursLabel = `${CLIENT_CANCELLATION_LOCK_HOURS}h`;
const cancellationLockReminderLabel = `${Math.floor(CLIENT_CANCELLATION_PRELOCK_REMINDER_MINUTES / 60)}h${String(CLIENT_CANCELLATION_PRELOCK_REMINDER_MINUTES % 60).padStart(2, '0')}`;

const formatAppointmentDate = (appointmentDate?: Date | undefined): string => {
    if (!appointmentDate) return '';
    const day = appointmentDate.toLocaleDateString('fr-FR');
    const time = appointmentDate.toLocaleTimeString('fr-FR', {
        hour: '2-digit',
        minute: '2-digit'
    });
    return `${day} a ${time}`;
};

const EVENT_TEMPLATES: Record<AppointmentNotificationEvent, AppointmentEventTemplate> = {
    APPT_CREATED: {
        transportType: 'APPOINTMENT_UPDATED',
        recipientRoles: ['PATRON', 'BARBER'],
        title: () => 'Nouvelle demande de rendez-vous',
        body: (ctx) => {
            const dateLabel = formatAppointmentDate(ctx.appointmentDate);
            return dateLabel ? `Service reserve pour le ${dateLabel}.` : 'Service reserve.';
        },
        priority: 'HIGH'
    },
    APPT_CONFIRMED: {
        transportType: 'APPOINTMENT_UPDATED',
        recipientRoles: ['CLIENT', 'BARBER', 'PATRON'],
        title: () => 'Rendez-vous confirme',
        body: (ctx) => {
            const dateLabel = formatAppointmentDate(ctx.appointmentDate);
            return dateLabel
                ? `Votre rendez-vous est confirme pour le ${dateLabel}.`
                : 'Votre rendez-vous est confirme.';
        },
        priority: 'HIGH'
    },
    APPT_CANCELLED: {
        transportType: 'APPOINTMENT_UPDATED',
        recipientRoles: ['CLIENT', 'BARBER', 'PATRON'],
        title: () => 'Rendez-vous annule',
        body: () => 'Une modification a ete effectuee sur le rendez-vous.',
        priority: 'HIGH'
    },
    APPT_DECLINED: {
        transportType: 'APPOINTMENT_UPDATED',
        recipientRoles: ['CLIENT', 'BARBER', 'PATRON'],
        title: () => 'Rendez-vous refuse',
        body: () => 'Le salon a refuse ce creneau. Merci de choisir un autre horaire.',
        priority: 'HIGH'
    },
    APPT_COMPLETED: {
        transportType: 'APPOINTMENT_UPDATED',
        recipientRoles: ['CLIENT', 'BARBER', 'PATRON'],
        title: () => 'Laissez votre avis',
        body: () => 'Votre prestation est terminee, partagez votre review.',
        priority: 'NORMAL'
    },
    APPT_SHIFTED: {
        transportType: 'APPOINTMENT_UPDATED',
        recipientRoles: ['CLIENT', 'BARBER', 'PATRON'],
        title: () => 'Rendez-vous decale',
        body: (ctx) => {
            const shift = ctx.extraData?.shiftMinutes;
            return shift ? `Rendez-vous decale de ${shift} minutes.` : 'Votre rendez-vous a ete decale.';
        },
        priority: 'HIGH'
    },
    APPT_REMINDER_1H10_CLIENT: {
        transportType: 'APPOINTMENT_REMINDER',
        recipientRoles: ['CLIENT'],
        title: () => 'Rappel de rendez-vous',
        body: () =>
            `Votre rendez-vous est dans ${cancellationLockReminderLabel}. L'annulation sera impossible si le temps restant est inferieur a ${CLIENT_CANCELLATION_LOCK_HOURS} heures.`,
        priority: 'HIGH'
    },
    APPT_REMINDER_1H10_BARBER: {
        transportType: 'APPOINTMENT_REMINDER',
        recipientRoles: ['BARBER'],
        title: () => 'Prochain client',
        body: (ctx) => `Vous avez un rendez-vous dans ${cancellationLockReminderLabel} avec ${ctx.clientName || 'votre client'}.`,
        priority: 'HIGH'
    },
    APPT_CLIENT_LOCK_LT_1H: {
        transportType: 'APPOINTMENT_REMINDER',
        recipientRoles: ['CLIENT'],
        title: () => `Rendez-vous dans moins de ${cancellationLockHoursLabel}`,
        body: () => `L'annulation n'est plus possible maintenant, car le delai de ${cancellationLockHoursLabel} est depasse.`,
        priority: 'HIGH'
    },
    APPT_REMINDER_LT_1H_BARBER: {
        transportType: 'APPOINTMENT_REMINDER',
        recipientRoles: ['BARBER'],
        title: () => 'Prochain client',
        body: (ctx) => `Rappel: rendez-vous dans moins de ${cancellationLockHoursLabel} avec ${ctx.clientName || 'votre client'}.`,
        priority: 'HIGH'
    },
    APPT_REMINDER_30M: {
        transportType: 'APPOINTMENT_REMINDER',
        recipientRoles: ['CLIENT'],
        title: () => 'Rendez-vous imminent',
        body: () => 'Votre rendez-vous est dans 30 minutes !',
        priority: 'HIGH'
    },
    APPT_BARBER_REMINDER_30M: {
        transportType: 'APPOINTMENT_REMINDER',
        recipientRoles: ['BARBER'],
        title: () => 'Client imminent',
        body: (ctx) => `Le rendez-vous avec ${ctx.clientName || 'votre client'} est dans 30 minutes.`,
        priority: 'HIGH'
    },
    APPT_PATRON_EMPLOYEE_REMINDER_30M: {
        transportType: 'APPOINTMENT_REMINDER',
        recipientRoles: ['PATRON'],
        title: () => 'Client imminent (Employe)',
        body: (ctx) => `Le rendez-vous de ${ctx.clientName || 'votre client'} avec votre employe est dans 30 minutes.`,
        priority: 'HIGH'
    },
    APPT_REMINDER_15M: {
        transportType: 'APPOINTMENT_REMINDER',
        recipientRoles: ['CLIENT'],
        title: () => 'Rendez-vous bientot',
        body: () => 'Votre rendez-vous est dans 15 minutes.',
        priority: 'HIGH'
    },
    APPT_REMINDER_1M: {
        transportType: 'APPOINTMENT_REMINDER',
        recipientRoles: ['CLIENT'],
        title: () => 'Rendez-vous imminent',
        body: () => 'Votre rendez-vous commence dans 1 minute.',
        priority: 'HIGH'
    },
    APPT_BARBER_ARRIVAL_CHECK: {
        transportType: 'APPOINTMENT_REMINDER',
        recipientRoles: ['BARBER'],
        title: () => 'Le client est-il la ?',
        body: (ctx) => `Il est l'heure du rendez-vous pour ${ctx.clientName || 'votre client'}. Confirmez son arrivee !`,
        priority: 'HIGH'
    },
    APPT_CLIENT_START_NOW: {
        transportType: 'APPOINTMENT_REMINDER',
        recipientRoles: ['CLIENT'],
        title: () => "C'est l'heure !",
        body: () => 'Votre rendez-vous commence maintenant.',
        priority: 'HIGH'
    },
    APPT_BARBER_COMPLETION_CHECK: {
        transportType: 'APPOINTMENT_REMINDER',
        recipientRoles: ['BARBER'],
        title: () => 'Rendez-vous termine ?',
        body: (ctx) => `Avez-vous fini avec ${ctx.clientName || 'votre client'} ?`,
        priority: 'NORMAL'
    }
};

const normalizeExtraData = (
    extraData?: Record<string, string | number | boolean | undefined>
): Record<string, string> => {
    const normalized: Record<string, string> = {};
    if (!extraData) return normalized;

    for (const [key, value] of Object.entries(extraData)) {
        if (value === undefined) continue;
        normalized[key] = String(value);
    }

    return normalized;
};

const getDefaultDeeplink = (appointmentId: number): string => `/appointments/${appointmentId}`;

const resolveRecipientIds = (event: AppointmentNotificationEvent, ctx: AppointmentEventContext): number[] => {
    if (ctx.targetUserIds && ctx.targetUserIds.length > 0) {
        const uniqueTargetIds = Array.from(new Set(ctx.targetUserIds.filter((id) => Number.isInteger(id) && id > 0)));
        if (ctx.actorUserId && ctx.actorUserId > 0) {
            return uniqueTargetIds.filter((id) => id !== ctx.actorUserId);
        }
        return uniqueTargetIds;
    }

    const template = EVENT_TEMPLATES[event];
    const roleMap: Record<RecipientRole, number | undefined> = {
        CLIENT: ctx.clientId,
        BARBER: ctx.barberId ?? undefined,
        PATRON: ctx.patronId
    };

    const recipientIds = (template.recipientRoles || [])
        .map((role) => roleMap[role])
        .filter((id): id is number => typeof id === 'number' && id > 0);

    const uniqueRecipientIds = Array.from(new Set(recipientIds));
    if (ctx.actorUserId && ctx.actorUserId > 0) {
        return uniqueRecipientIds.filter((id) => id !== ctx.actorUserId);
    }
    return uniqueRecipientIds;
};

const cleanupDedupeCache = () => {
    const now = Date.now();
    for (const [key, expiresAt] of dedupeCache.entries()) {
        if (expiresAt <= now) {
            dedupeCache.delete(key);
        }
    }
};

const shouldSkipByDedupe = (
    event: AppointmentNotificationEvent,
    appointmentId: number,
    userId: number,
    dedupeWindowMs: number
) => {
    cleanupDedupeCache();
    const key = `${event}:${appointmentId}:${userId}`;
    const now = Date.now();
    const expiresAt = dedupeCache.get(key);

    if (expiresAt && expiresAt > now) {
        return true;
    }

    dedupeCache.set(key, now + dedupeWindowMs);
    return false;
};

type TransportData = {
    type: TransportType;
    eventType: AppointmentNotificationEvent;
    appointmentId: string;
    status?: string;
    newStatus?: string;
    scheduledAt?: string;
    deeplink: string;
    priority: NotificationPriority;
    [key: string]: string | undefined;
};

const buildTransportData = (
    event: AppointmentNotificationEvent,
    template: AppointmentEventTemplate,
    ctx: AppointmentEventContext
): TransportData => {
    return {
        type: template.transportType,
        eventType: event,
        appointmentId: String(ctx.appointmentId),
        ...(ctx.status !== undefined && { status: String(ctx.status), newStatus: String(ctx.status) }),
        ...(ctx.appointmentDate && { scheduledAt: ctx.appointmentDate.toISOString() }),
        deeplink: ctx.deeplink || getDefaultDeeplink(ctx.appointmentId),
        priority: template.priority || 'NORMAL',
        ...normalizeExtraData(ctx.extraData)
    };
};

export const emitAppointmentEvent = async (
    event: AppointmentNotificationEvent,
    ctx: AppointmentEventContext
) => {
    const template = EVENT_TEMPLATES[event];
    const recipientIds = resolveRecipientIds(event, ctx);
    if (recipientIds.length === 0) return;

    const title = template.title(ctx);
    const body = template.body(ctx);
    const data = buildTransportData(event, template, ctx);
    const dedupeWindowMs = ctx.dedupeWindowMs ?? template.dedupeWindowMs ?? DEFAULT_DEDUPE_WINDOW_MS;

    const users = await prisma.user.findMany({
        where: { id: { in: recipientIds } },
        include: { profile: true }
    });

    for (const user of users) {
        if (shouldSkipByDedupe(event, ctx.appointmentId, user.id, dedupeWindowMs)) {
            continue;
        }

        const dbNotification = template.persistInDb === false
            ? null
            : await prisma.notification.create({
                data: {
                    userId: user.id,
                    title,
                    body,
                    eventType: event,
                    appointmentId: ctx.appointmentId,
                    deeplink: data.deeplink || null
                }
            });

        broadcastNotificationToUser(user.id, {
            ...(dbNotification || {
                id: 0,
                userId: user.id,
                title,
                body,
                eventType: event,
                appointmentId: ctx.appointmentId,
                deeplink: data.deeplink,
                isRead: false,
                createdAt: new Date()
            }),
            type: template.transportType,
            eventType: event,
            appointmentId: ctx.appointmentId,
            ...(ctx.status !== undefined && { newStatus: ctx.status }),
            scheduledAt: ctx.appointmentDate?.toISOString(),
            deeplink: data.deeplink
        });

        if (template.sendPush === false) {
            continue;
        }

        if (user.profile?.fcmToken) {
            await sendNotification(user.profile.fcmToken, title, body, data);
        }
    }
};

export const broadcastAppointmentRefresh = async (payload: RefreshPayload) => {
    const uniqueUserIds = Array.from(
        new Set(payload.userIds.filter((id) => Number.isInteger(id) && id > 0))
    );

    if (uniqueUserIds.length === 0) return;

    const users = await prisma.user.findMany({
        where: { id: { in: uniqueUserIds } },
        include: { profile: true }
    });

    const transportData = {
        type: 'APPOINTMENT_UPDATED',
        eventType: 'APPT_REFRESH',
        appointmentId: String(payload.appointmentId),
        ...(payload.status !== undefined && { status: payload.status, newStatus: payload.status }),
        deeplink: payload.deeplink || getDefaultDeeplink(payload.appointmentId)
    };

    for (const user of users) {
        broadcastNotificationToUser(user.id, {
            type: transportData.type,
            eventType: transportData.eventType,
            appointmentId: payload.appointmentId,
            ...(payload.status !== undefined && { newStatus: payload.status }),
            deeplink: transportData.deeplink
        });

        if (user.profile?.fcmToken) {
            await sendNotification(user.profile.fcmToken, undefined, undefined, transportData);
        }
    }
};
