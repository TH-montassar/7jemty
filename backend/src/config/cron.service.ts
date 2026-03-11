import cron from 'node-cron';
import { prisma } from '../lib/db.js';
import { sendNotification } from '../modules/notifications/notifications.service.js';
import { broadcastNotificationToUser } from '../modules/notifications/notifications.controller.js';

const createPersistentReminder = async (
    userId: number,
    title: string,
    body: string,
    type: string = 'APPOINTMENT_REMINDER'
) => {
    const dbNotification = await prisma.notification.create({
        data: {
            userId,
            title,
            body
        }
    });

    broadcastNotificationToUser(userId, {
        ...dbNotification,
        type
    });
};

export const runAppointmentReminderTick = async () => {
    try {
        const now = new Date();
        // Get current time normalized to the minute (drop seconds)
        const currentTime = new Date(
            now.getFullYear(),
            now.getMonth(),
            now.getDate(),
            now.getHours(),
            now.getMinutes()
        );

        // Calculate targets
        const oneHourTenFromNow = new Date(currentTime.getTime() + 70 * 60000); // 1h10
        const thirtyMinsFromNow = new Date(currentTime.getTime() + 30 * 60000); // 30m

        // Fetch pending or confirmed appointments that haven't naturally completed yet
        const appointments = await prisma.appointment.findMany({
            where: {
                status: {
                    in: ['PENDING', 'CONFIRMED'] // Could be scheduled
                },
                // We only want future appointments OR ones happening exactly now
                appointmentDate: {
                    gte: new Date(currentTime.getTime() - 24 * 60 * 60000) // Within last 24h safety net
                }
            },
            include: {
                salon: {
                    include: { patron: { include: { profile: true } } }
                },
                client: { include: { profile: true } }
            }
        });

        for (const appt of appointments) {
            const apptTime = new Date(appt.appointmentDate);
            // Drop seconds from appointment time to compare strictly by minute
            const normalizedApptTime = new Date(
                apptTime.getFullYear(),
                apptTime.getMonth(),
                apptTime.getDate(),
                apptTime.getHours(),
                apptTime.getMinutes()
            );

            // Fetch barber or patron token
            let barberToken: string | null = null;
            if (appt.barberId) {
                const barber = await prisma.user.findUnique({
                    where: { id: appt.barberId },
                    include: { profile: true }
                });
                barberToken = barber?.profile?.fcmToken || null;
            } else {
                barberToken = appt.salon.patron.profile?.fcmToken || null;
            }

            const clientToken = appt.client.profile?.fcmToken;

            // 1. T - 1h10m
            if (normalizedApptTime.getTime() === oneHourTenFromNow.getTime() && !appt.is1hReminderSent) {
                if (clientToken) {
                    await sendNotification(
                        clientToken,
                        'Rappel de rendez-vous',
                        "Votre rendez-vous est dans 1h10. Attention: l'annulation sera impossible si le temps restant est inferieur a 1 heure."
                    );
                }
                if (barberToken) {
                    await sendNotification(
                        barberToken,
                        'Prochain client',
                        `Vous avez un rendez-vous dans 1h10 avec ${appt.client.fullName}.`
                    );
                }
            }

            // 2. T <= 1 hour (single-shot lock reminder for client cancellation)
            const minutesUntilAppointment = Math.floor((normalizedApptTime.getTime() - currentTime.getTime()) / 60000);
            if (!appt.is1hReminderSent && minutesUntilAppointment <= 60 && minutesUntilAppointment > 0) {
                await prisma.appointment.update({
                    where: { id: appt.id },
                    data: { is1hReminderSent: true }
                });

                const lockTitle = "Rendez-vous dans moins d'1h";
                const lockBody = "L'annulation n'est plus possible maintenant, car le delai de 1h est depasse.";

                await createPersistentReminder(
                    appt.clientId,
                    lockTitle,
                    lockBody,
                    'APPOINTMENT_REMINDER'
                );

                if (clientToken) {
                    await sendNotification(
                        clientToken,
                        lockTitle,
                        lockBody,
                        {
                            type: 'APPOINTMENT_REMINDER',
                            appointmentId: appt.id.toString(),
                            lockCancellation: 'true'
                        }
                    );
                }

                if (barberToken) {
                    await sendNotification(
                        barberToken,
                        'Prochain client',
                        `Rappel: rendez-vous dans moins d'1h avec ${appt.client.fullName}.`,
                        {
                            type: 'APPOINTMENT_REMINDER',
                            appointmentId: appt.id.toString()
                        }
                    );
                }
            }

            // 3. T - 30 minutes
            if (normalizedApptTime.getTime() === thirtyMinsFromNow.getTime() && !appt.is10mReminderSent) {
                await prisma.appointment.update({ where: { id: appt.id }, data: { is10mReminderSent: true } });

                if (clientToken) {
                    await sendNotification(clientToken, 'Rendez-vous imminent', 'Votre rendez-vous est dans 30 minutes !');
                }
                if (barberToken) {
                    await sendNotification(
                        barberToken,
                        'Client imminent',
                        `Le rendez-vous avec ${appt.client.fullName} est dans 30 minutes.`
                    );
                }

                // Also notify the patron if the barber is not the patron
                if (appt.barberId && appt.barberId !== appt.salon.patronId) {
                    const patronToken = appt.salon.patron.profile?.fcmToken;
                    if (patronToken) {
                        await sendNotification(
                            patronToken,
                            'Client imminent (Employe)',
                            `Le rendez-vous de ${appt.client.fullName} avec votre employe est dans 30 minutes.`
                        );
                    }
                }
            }

            // 4. T = 0 (Appointment Start time)
            if (normalizedApptTime.getTime() === currentTime.getTime() && appt.status !== 'IN_PROGRESS') {
                // Send an alert to the barber asking if the client arrived.
                if (barberToken) {
                    await sendNotification(
                        barberToken,
                        'Le client est-il la ?',
                        `Il est l'heure du rendez-vous pour ${appt.client.fullName}. Confirmez son arrivee !`
                    );
                }
                if (clientToken) {
                    await sendNotification(clientToken, "C'est l'heure !", 'Votre rendez-vous commence maintenant.');
                }
            }

            // 5. T = Completion time
            const endTime = new Date(appt.estimatedEndTime);
            const normalizedEndTime = new Date(
                endTime.getFullYear(),
                endTime.getMonth(),
                endTime.getDate(),
                endTime.getHours(),
                endTime.getMinutes()
            );

            // If it's been exactly completion time OR it's been 5, 10 minutes past without "Complete"
            if (currentTime.getTime() >= normalizedEndTime.getTime() && appt.status === 'IN_PROGRESS') {
                // Ask every 5 mins after estimated end
                const lastAsked = appt.lastCompletionAskTime ? appt.lastCompletionAskTime.getTime() : 0;
                if (currentTime.getTime() - lastAsked >= 5 * 60000) {
                    if (barberToken) {
                        await sendNotification(
                            barberToken,
                            'Rendez-vous termine ?',
                            `Avez-vous fini avec ${appt.client.fullName} ?`
                        );
                    }
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
    } catch (error) {
        console.error('Error in cron job execution:', error);
    }
};

export const initCronJobs = () => {
    // Run every minute: * * * * *
    cron.schedule('* * * * *', () => {
        void runAppointmentReminderTick();
    });

    console.log('Cron Jobs Scheduler automatically started');
};
