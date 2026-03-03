import cron from 'node-cron';
import { prisma } from '../lib/db.js';
import { sendNotification } from '../modules/notifications/notifications.service.js';

export const initCronJobs = () => {
    // Run every minute: * * * * *
    cron.schedule('* * * * *', async () => {
        try {
            const now = new Date();
            // Get current time normalized to the minute (drop seconds)
            const currentTime = new Date(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours(), now.getMinutes());

            // Add exactly 60 minutes and 15 minutes to check matches
            const oneHourFromNow = new Date(currentTime.getTime() + 60 * 60000);
            const fifteenMinsFromNow = new Date(currentTime.getTime() + 15 * 60000);

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
                const normalizedApptTime = new Date(apptTime.getFullYear(), apptTime.getMonth(), apptTime.getDate(), apptTime.getHours(), apptTime.getMinutes());

                // Fetch barber or patron token
                let barberToken: string | null = null;
                if (appt.barberId) {
                    const barber = await prisma.user.findUnique({ where: { id: appt.barberId }, include: { profile: true } });
                    barberToken = barber?.profile?.fcmToken || null;
                } else {
                    barberToken = appt.salon.patron.profile?.fcmToken || null;
                }

                const clientToken = appt.client.profile?.fcmToken;

                // 1. T - 1 hour
                if (normalizedApptTime.getTime() === oneHourFromNow.getTime() && !appt.is1hReminderSent) {
                    if (clientToken) await sendNotification(clientToken, "Rappel de rendez-vous", "Votre rendez-vous est dans 1h. L'annulation n'est plus possible.");
                    if (barberToken) await sendNotification(barberToken, "Prochain client", `Vous avez un rendez-vous dans 1h avec ${appt.client.fullName}.`);

                    await prisma.appointment.update({ where: { id: appt.id }, data: { is1hReminderSent: true } });
                }

                // 2. T - 15 minutes
                if (normalizedApptTime.getTime() === fifteenMinsFromNow.getTime() && !appt.is10mReminderSent) {
                    // Re-using the 10m boolean field here since the DB schema dictates it, representing the second reminder
                    if (clientToken) await sendNotification(clientToken, "Rendez-vous imminent", "Votre rendez-vous est dans 15 minutes !");
                    if (barberToken) await sendNotification(barberToken, "Client imminent", `Le rendez-vous avec ${appt.client.fullName} est dans 15 minutes.`);

                    await prisma.appointment.update({ where: { id: appt.id }, data: { is10mReminderSent: true } });
                }

                // 3. T = 0 (Appointment Start time)
                if (normalizedApptTime.getTime() === currentTime.getTime() && appt.status !== 'IN_PROGRESS') {
                    // Send an alert to the barber asking if the client arrived.
                    if (barberToken) {
                        await sendNotification(barberToken, "Le client est-il là ?", `Il est l'heure du rendez-vous pour ${appt.client.fullName}. Confirmez son arrivée !`);
                    }
                    if (clientToken) {
                        await sendNotification(clientToken, "C'est l'heure !", "Votre rendez-vous commence maintenant.");
                    }
                }

                // 4. T = Completion time
                const endTime = new Date(appt.estimatedEndTime);
                const normalizedEndTime = new Date(endTime.getFullYear(), endTime.getMonth(), endTime.getDate(), endTime.getHours(), endTime.getMinutes());

                // If it's been exactly completion time OR it's been 5, 10 minutes past without them hitting "Complete"
                if (currentTime.getTime() >= normalizedEndTime.getTime() && appt.status === 'IN_PROGRESS') {
                    // If we haven't asked them in the last 10 minutes (using completionPromptCount or lastCompletionAskTime to stagger alerts)
                    const lastAsked = appt.lastCompletionAskTime ? appt.lastCompletionAskTime.getTime() : 0;
                    if (currentTime.getTime() - lastAsked >= 5 * 60000) { // Ask every 5 mins after it's over
                        if (barberToken) {
                            await sendNotification(barberToken, "Rendez-vous terminé ?", `Avez-vous fini avec ${appt.client.fullName} ?`);
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
    });

    console.log('✅ Cron Jobs Scheduler automatically started');
};
