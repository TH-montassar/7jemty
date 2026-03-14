import cron from 'node-cron';
import { prisma } from '../lib/db.js';
import { emitAppointmentEvent } from '../modules/notifications/notification.orchestrator.js';
import { CLIENT_CANCELLATION_LOCK_MINUTES, CLIENT_CANCELLATION_PRELOCK_REMINDER_MINUTES } from '../modules/appointment/appointment.constants.js';
const getStakeholderUserIds = (barberId, patronId) => Array.from(new Set([barberId, patronId].filter((id) => typeof id === 'number' && id > 0)));
export const runAppointmentReminderTick = async () => {
    try {
        const now = new Date();
        const currentTime = new Date(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours(), now.getMinutes());
        const cancellationLockReminderFromNow = new Date(currentTime.getTime() + CLIENT_CANCELLATION_PRELOCK_REMINDER_MINUTES * 60000);
        const thirtyMinsFromNow = new Date(currentTime.getTime() + 30 * 60000);
        const fifteenMinsFromNow = new Date(currentTime.getTime() + 15 * 60000);
        const oneMinFromNow = new Date(currentTime.getTime() + 1 * 60000);
        const appointments = await prisma.appointment.findMany({
            where: {
                status: { in: ['PENDING', 'CONFIRMED', 'IN_PROGRESS'] },
                appointmentDate: {
                    gte: new Date(currentTime.getTime() - 24 * 60 * 60000)
                }
            },
            include: {
                salon: {
                    select: { patronId: true }
                },
                client: {
                    select: { fullName: true }
                }
            }
        });
        for (const appt of appointments) {
            const apptTime = new Date(appt.appointmentDate);
            const normalizedApptTime = new Date(apptTime.getFullYear(), apptTime.getMonth(), apptTime.getDate(), apptTime.getHours(), apptTime.getMinutes());
            const stakeholderUserIds = getStakeholderUserIds(appt.barberId, appt.salon.patronId);
            const baseContext = {
                appointmentId: appt.id,
                appointmentDate: appt.appointmentDate,
                status: appt.status,
                clientId: appt.clientId,
                barberId: appt.barberId,
                patronId: appt.salon.patronId,
                clientName: appt.client.fullName
            };
            if (normalizedApptTime.getTime() === cancellationLockReminderFromNow.getTime() && !appt.is1hReminderSent) {
                await emitAppointmentEvent('APPT_REMINDER_1H10_CLIENT', {
                    ...baseContext,
                    targetUserIds: [appt.clientId]
                });
                await emitAppointmentEvent('APPT_REMINDER_1H10_BARBER', {
                    ...baseContext,
                    targetUserIds: stakeholderUserIds
                });
            }
            const minutesUntilAppointment = Math.floor((normalizedApptTime.getTime() - currentTime.getTime()) / 60000);
            if (!appt.is1hReminderSent && minutesUntilAppointment <= CLIENT_CANCELLATION_LOCK_MINUTES && minutesUntilAppointment > 0) {
                await prisma.appointment.update({
                    where: { id: appt.id },
                    data: { is1hReminderSent: true }
                });
                await emitAppointmentEvent('APPT_CLIENT_LOCK_LT_1H', {
                    ...baseContext,
                    targetUserIds: [appt.clientId],
                    extraData: { lockCancellation: true }
                });
                await emitAppointmentEvent('APPT_REMINDER_LT_1H_BARBER', {
                    ...baseContext,
                    targetUserIds: stakeholderUserIds
                });
            }
            if (normalizedApptTime.getTime() === thirtyMinsFromNow.getTime() && !appt.is10mReminderSent) {
                await prisma.appointment.update({
                    where: { id: appt.id },
                    data: { is10mReminderSent: true }
                });
                await emitAppointmentEvent('APPT_REMINDER_30M', {
                    ...baseContext,
                    targetUserIds: [appt.clientId]
                });
                await emitAppointmentEvent('APPT_BARBER_REMINDER_30M', {
                    ...baseContext,
                    targetUserIds: stakeholderUserIds
                });
                await emitAppointmentEvent('APPT_PATRON_EMPLOYEE_REMINDER_30M', {
                    ...baseContext,
                    targetUserIds: [appt.salon.patronId]
                });
            }
            if (normalizedApptTime.getTime() === fifteenMinsFromNow.getTime()) {
                await emitAppointmentEvent('APPT_REMINDER_15M', {
                    ...baseContext,
                    targetUserIds: [appt.clientId]
                });
            }
            if (normalizedApptTime.getTime() === oneMinFromNow.getTime()) {
                await emitAppointmentEvent('APPT_REMINDER_1M', {
                    ...baseContext,
                    targetUserIds: [appt.clientId]
                });
            }
            if (normalizedApptTime.getTime() === currentTime.getTime() && appt.status !== 'IN_PROGRESS') {
                await emitAppointmentEvent('APPT_BARBER_ARRIVAL_CHECK', {
                    ...baseContext,
                    targetUserIds: stakeholderUserIds
                });
                await emitAppointmentEvent('APPT_CLIENT_START_NOW', {
                    ...baseContext,
                    targetUserIds: [appt.clientId]
                });
            }
            const endTime = new Date(appt.estimatedEndTime);
            const normalizedEndTime = new Date(endTime.getFullYear(), endTime.getMonth(), endTime.getDate(), endTime.getHours(), endTime.getMinutes());
            if (currentTime.getTime() >= normalizedEndTime.getTime() && appt.status === 'IN_PROGRESS') {
                const lastAsked = appt.lastCompletionAskTime ? appt.lastCompletionAskTime.getTime() : 0;
                if (currentTime.getTime() - lastAsked >= 5 * 60000) {
                    await emitAppointmentEvent('APPT_BARBER_COMPLETION_CHECK', {
                        ...baseContext,
                        targetUserIds: stakeholderUserIds,
                        dedupeWindowMs: 5 * 60_000
                    });
                    await prisma.appointment.update({
                        where: { id: appt.id },
                        data: {
                            lastCompletionAskTime: currentTime,
                            completionPromptCount: appt.completionPromptCount + 1
                        }
                    });
                }
            }
        }
    }
    catch (error) {
        if (error.code === 'EAI_AGAIN') {
            console.error('DNS Resolution failed (EAI_AGAIN). This is likely a transient network issue. Skipping this tick.');
        }
        else {
            console.error('Error in cron job execution:', error);
        }
    }
};
export const initCronJobs = () => {
    // Run every minute: * * * * *
    cron.schedule('* * * * *', () => {
        void runAppointmentReminderTick();
    });
    console.log('Cron Jobs Scheduler automatically started');
};
//# sourceMappingURL=cron.service.js.map