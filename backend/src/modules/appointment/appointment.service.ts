import { prisma } from '../../lib/db.js';

type UserRole = 'CLIENT' | 'EMPLOYEE' | 'PATRON' | 'ADMIN';
type AppointmentStatusInput = 'PENDING' | 'CONFIRMED' | 'IN_PROGRESS' | 'ARRIVED' | 'COMPLETED' | 'CANCELLED' | 'DECLINED';
type AppointmentTargetInput = 'EMPLOYEE' | 'PATRON';

type NotifyPayload = {
    title: string;
    body: string;
    userIds: number[];
    appointmentId: number;
};

const ACTIVE_APPOINTMENT_STATUSES: AppointmentStatusInput[] = ['PENDING', 'CONFIRMED', 'IN_PROGRESS', 'ARRIVED'];

const notifyUsers = async (_payload: NotifyPayload) => {
    // TODO: brancher avec FCM/OneSignal provider.
    return;
};

export const updateAppointmentStatus = async (
    appointmentId: number,
    status: AppointmentStatusInput,
    userId: number,
    userRole: UserRole
) => {
    const appointment = await prisma.appointment.findUnique({
        where: { id: appointmentId },
        include: {
            salon: true,
            services: { include: { service: true } }
        }
    });

    if (!appointment) {
        throw new Error('Rendez-vous introuvable');
    }

    await assertUpdatePermission(appointment, userId, userRole);
    assertStatusTransition(appointment.status as AppointmentStatusInput, status, userRole, appointment.appointmentDate);

    const now = new Date();

    const updated = await prisma.$transaction(async (tx: any) => {
        const updateData: Record<string, unknown> = { status };

        if (status === 'CONFIRMED') {
            updateData.confirmedAt = now;
        }

        if (status === 'IN_PROGRESS') {
            updateData.startedAt = appointment.startedAt ?? now;
            const base = appointment.startedAt ?? now;
            const nextCheck = new Date(base);
            nextCheck.setMinutes(nextCheck.getMinutes() + appointment.totalDurationMinutes);
            updateData.nextCompletionCheckAt = nextCheck;
            updateData.lastCompletionAskTime = now;
        }

        if (status === 'CANCELLED') {
            updateData.cancelledAt = now;
        }

        if (status === 'COMPLETED') {
            const actualEnd = now;
            updateData.completedAt = now;
            updateData.actualEndTime = actualEnd;
            updateData.nextCompletionCheckAt = null;

            const startDate = appointment.startedAt ?? appointment.appointmentDate;
            const actualDurationMinutes = Math.max(1, Math.ceil((actualEnd.getTime() - startDate.getTime()) / 60000));

            for (const relation of appointment.services) {
                const existing = await tx.barberServiceStat.findUnique({
                    where: {
                        barberId_serviceId: {
                            barberId: appointment.barberId ?? 0,
                            serviceId: relation.serviceId
                        }
                    }
                });

                if (!appointment.barberId) {
                    continue;
                }

                if (!existing) {
                    await tx.barberServiceStat.create({
                        data: {
                            barberId: appointment.barberId,
                            serviceId: relation.serviceId,
                            completedAppointments: 1,
                            totalActualDurationMin: actualDurationMinutes,
                            averageDurationMin: actualDurationMinutes
                        }
                    });
                } else {
                    const completedAppointments = existing.completedAppointments + 1;
                    const totalActualDurationMin = existing.totalActualDurationMin + actualDurationMinutes;
                    await tx.barberServiceStat.update({
                        where: { id: existing.id },
                        data: {
                            completedAppointments,
                            totalActualDurationMin,
                            averageDurationMin: totalActualDurationMin / completedAppointments
                        }
                    });
                }
            }
        }

        return tx.appointment.update({
            where: { id: appointmentId },
            data: updateData
        });
    });

    await emitStatusNotifications(appointmentId, appointment.clientId, appointment.barberId, appointment.salon.patronId, status, appointment.appointmentDate);
    return updated;
};

export const getBarberAvailability = async (
    salonId: number,
    dateString: string,
    requestedBarberId?: number,
    serviceIds?: number[]
) => {
    const date = new Date(dateString);
    const dayOfWeek = date.getDay();
    const now = new Date();

    const workingHours = await prisma.workingHours.findFirst({ where: { salonId, dayOfWeek } });

    let openTime = '08:00';
    let closeTime = '17:00';

    if (workingHours?.isDayOff) {
        return [];
    }

    if (workingHours?.openTime) {
        openTime = workingHours.openTime;
    }

    if (workingHours?.closeTime) {
        closeTime = workingHours.closeTime;
    }

    const requestedServices = serviceIds?.length
        ? await prisma.service.findMany({ where: { id: { in: serviceIds }, salonId } })
        : [];

    const totalDurationMinutes = requestedServices.length
        ? requestedServices.reduce((sum: number, service: any) => sum + (service.durationMinutes || 30), 0)
        : 30;

    const slots: string[] = [];
    let current = parseTime(openTime, date);
    const close = parseTime(closeTime, date);

    while (current < close) {
        const slotLabel = formatTime(current);
        const slotStart = parseTime(slotLabel, date);
        const slotEnd = new Date(slotStart);
        slotEnd.setMinutes(slotEnd.getMinutes() + totalDurationMinutes);

        if (slotStart <= now) {
            current.setMinutes(current.getMinutes() + 30);
            continue;
        }

        if (slotEnd > close) {
            current.setMinutes(current.getMinutes() + 30);
            continue;
        }

        slots.push(slotLabel);
        current.setMinutes(current.getMinutes() + 30);
    }

    const dateStart = new Date(date);
    dateStart.setHours(0, 0, 0, 0);
    const dateEnd = new Date(dateStart);
    dateEnd.setDate(dateEnd.getDate() + 1);

    const appointments = await prisma.appointment.findMany({
        where: {
            salonId,
            ...(requestedBarberId ? { barberId: requestedBarberId } : {}),
            appointmentDate: { gte: dateStart, lt: dateEnd },
            status: { in: ACTIVE_APPOINTMENT_STATUSES }
        }
    });

    return slots.map((slot) => {
        const slotStart = parseTime(slot, date);
        const slotEnd = new Date(slotStart);
        slotEnd.setMinutes(slotEnd.getMinutes() + totalDurationMinutes);

        const isAvailable = !appointments.some((appt: any) => slotStart < appt.estimatedEndTime && slotEnd > appt.appointmentDate);
        return { time: slot, available: isAvailable };
    });
};

export const createClientAppointment = async (
    clientId: number,
    salonId: number,
    barberId: number | undefined,
    dateString: string,
    timeString: string,
    serviceIds: number[],
    targetType: AppointmentTargetInput = 'EMPLOYEE'
) => {
    if (targetType === 'EMPLOYEE' && !barberId) {
        throw new Error('barberId est obligatoire pour une cible EMPLOYEE');
    }

    const salon = await prisma.salon.findUnique({ where: { id: salonId }, select: { patronId: true } });
    if (!salon) {
        throw new Error('Salon introuvable');
    }

    const services = await prisma.service.findMany({ where: { id: { in: serviceIds }, salonId } });

    if (services.length !== serviceIds.length) {
        throw new Error('Un ou plusieurs services sont invalides.');
    }

    const totalPrice = services.reduce((sum: number, service: any) => sum + service.price, 0);
    const totalDurationMinutes = services.reduce((sum: number, service: any) => sum + (service.durationMinutes || 30), 0);

    const appointmentDate = parseTime(timeString, new Date(dateString));
    const now = new Date();
    if (appointmentDate <= now) {
        throw new Error('Impossible de réserver un créneau dans le passé');
    }

    const estimatedEndTime = new Date(appointmentDate);
    estimatedEndTime.setMinutes(estimatedEndTime.getMinutes() + totalDurationMinutes);

    const [openHour, closeHour] = await getSalonOpenCloseForDate(salonId, appointmentDate);
    if (appointmentDate < openHour || estimatedEndTime > closeHour) {
        throw new Error('Le créneau dépasse les horaires du salon');
    }

    const availability = await getBarberAvailability(salonId, dateString, barberId, serviceIds);
    if (!availability.some((s: any) => s.time === timeString && s.available)) {
        throw new Error("Le coiffeur n'est plus disponible pour cet horaire.");
    }

    const targetBarberId = targetType === 'PATRON' ? salon.patronId : barberId;

    const appointment = await prisma.appointment.create({
        data: {
            clientId,
            salonId,
            barberId: targetBarberId ?? null,
            targetType,
            appointmentDate,
            estimatedEndTime,
            totalPrice,
            totalDurationMinutes,
            status: 'PENDING',
            services: {
                create: serviceIds.map((serviceId) => ({ service: { connect: { id: serviceId } } }))
            }
        }
    });

    const recipients = targetType === 'EMPLOYEE'
        ? [targetBarberId, salon.patronId].filter((id, idx, arr): id is number => Boolean(id) && arr.indexOf(id) === idx)
        : [salon.patronId];

    await notifyUsers({
        title: 'Nouvelle demande de rendez-vous',
        body: `Service réservé à ${timeString}`,
        userIds: recipients,
        appointmentId: appointment.id
    });

    return appointment;
};

export const processInProgressReminders = async () => {
    const now = new Date();
    const appointments = await prisma.appointment.findMany({
        where: {
            status: 'CONFIRMED',
            appointmentDate: { lte: now }
        },
        include: { salon: { select: { patronId: true } } }
    });

    for (const appointment of appointments) {
        await notifyUsers({
            title: 'Le client est-il arrivé ?',
            body: 'Confirmez son arrivée pour démarrer la prestation.',
            userIds: [appointment.barberId ?? appointment.salon.patronId],
            appointmentId: appointment.id
        });
    }
};

export const processCompletionAlerts = async () => {
    const now = new Date();

    const toPrompt = await prisma.appointment.findMany({
        where: {
            status: 'IN_PROGRESS',
            nextCompletionCheckAt: { lte: now }
        },
        include: { salon: { select: { patronId: true } } }
    });

    for (const appointment of toPrompt) {
        await prisma.appointment.update({
            where: { id: appointment.id },
            data: {
                completionPromptCount: appointment.completionPromptCount + 1,
                lastCompletionAskTime: now,
                nextCompletionCheckAt: new Date(now.getTime() + 15 * 60 * 1000)
            }
        });

        await notifyUsers({
            title: 'Temps écoulé',
            body: 'As-tu terminé ? (Oui / Snooze +15min)',
            userIds: [appointment.barberId ?? appointment.salon.patronId],
            appointmentId: appointment.id
        });
    }

    const ignoredThreshold = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const ignored = await prisma.appointment.findMany({
        where: {
            status: 'IN_PROGRESS',
            lastCompletionAskTime: { lte: ignoredThreshold }
        }
    });

    for (const appointment of ignored) {
        if (!appointment.barberId) {
            continue;
        }

        await prisma.$transaction(async (tx: any) => {
            await tx.appointmentFault.create({
                data: {
                    appointmentId: appointment.id,
                    barberId: appointment.barberId,
                    reason: 'Completion alert ignored for 24h'
                }
            });

            const updatedBarber = await tx.user.update({
                where: { id: appointment.barberId },
                data: { ignoredAppointmentsCount: { increment: 1 } },
                select: { ignoredAppointmentsCount: true }
            });

            if (updatedBarber.ignoredAppointmentsCount >= 3) {
                await tx.user.update({
                    where: { id: appointment.barberId },
                    data: {
                        isBlacklistedBySystem: true,
                        blacklistedAt: now
                    }
                });
            }
        });
    }
};

const emitStatusNotifications = async (
    appointmentId: number,
    clientId: number,
    barberId: number | null,
    patronId: number,
    status: AppointmentStatusInput,
    appointmentDate: Date
) => {
    if (status === 'CONFIRMED') {
        await notifyUsers({
            title: 'Rendez-vous confirmé',
            body: `Votre rendez-vous a été accepté pour ${appointmentDate.toISOString()}`,
            userIds: [clientId],
            appointmentId
        });
    }

    if (status === 'CANCELLED') {
        const recipients = [clientId, barberId ?? patronId].filter((id, idx, arr): id is number => arr.indexOf(id) === idx);
        await notifyUsers({
            title: 'Rendez-vous annulé',
            body: 'Une modification a été effectuée sur le rendez-vous.',
            userIds: recipients,
            appointmentId
        });
    }

    if (status === 'COMPLETED') {
        await prisma.appointment.update({
            where: { id: appointmentId },
            data: { reviewRequestedAt: new Date() }
        });
        await notifyUsers({
            title: 'Laissez votre avis',
            body: 'Votre prestation est terminée, partagez votre review.',
            userIds: [clientId],
            appointmentId
        });
    }
};

const assertStatusTransition = (
    currentStatus: AppointmentStatusInput,
    nextStatus: AppointmentStatusInput,
    userRole: UserRole,
    appointmentDate: Date
) => {
    if (nextStatus === currentStatus) {
        return;
    }

    const allowedTransitions: Record<AppointmentStatusInput, AppointmentStatusInput[]> = {
        PENDING: ['CONFIRMED', 'DECLINED', 'CANCELLED'],
        CONFIRMED: ['IN_PROGRESS', 'CANCELLED', 'COMPLETED'],
        IN_PROGRESS: ['COMPLETED'],
        ARRIVED: ['IN_PROGRESS', 'COMPLETED'],
        COMPLETED: [],
        CANCELLED: [],
        DECLINED: []
    };

    if (!allowedTransitions[currentStatus].includes(nextStatus)) {
        throw new Error(`Transition invalide: ${currentStatus} -> ${nextStatus}`);
    }

    if (nextStatus === 'CANCELLED' && userRole === 'CLIENT') {
        const oneHourBefore = new Date(appointmentDate.getTime() - 60 * 60 * 1000);
        if (new Date() >= oneHourBefore) {
            throw new Error('Annulation client impossible à moins de 1h du rendez-vous');
        }
    }
};

const assertUpdatePermission = async (
    appointment: { clientId: number; salon: { id: number; patronId: number } },
    userId: number,
    userRole: UserRole
) => {
    if (userRole === 'CLIENT' && appointment.clientId !== userId) {
        throw new Error("Ma 3andekch l'7a9 tbadel rdv mouch mte3ek");
    }

    if (userRole === 'EMPLOYEE' && appointment.salon.id !== (await getEmployeeSalonId(userId))) {
        throw new Error("Hetha rdv fi salon we5er, ma tnajemch tmesou");
    }

    if (userRole === 'PATRON' && appointment.salon.patronId !== userId) {
        throw new Error("Hetha rdv fi salon we5er, ma tnajemch tmesou");
    }
};

const getEmployeeSalonId = async (userId: number) => {
    const user = await prisma.user.findUnique({ where: { id: userId }, select: { workplaceSalonId: true } });
    return user?.workplaceSalonId;
};

const getSalonOpenCloseForDate = async (salonId: number, date: Date): Promise<[Date, Date]> => {
    const workingHours = await prisma.workingHours.findFirst({
        where: { salonId, dayOfWeek: date.getDay() }
    });

    let openTime = '08:00';
    let closeTime = '17:00';

    if (workingHours?.isDayOff) {
        throw new Error('Salon fermé ce jour');
    }

    if (workingHours?.openTime) {
        openTime = workingHours.openTime;
    }

    if (workingHours?.closeTime) {
        closeTime = workingHours.closeTime;
    }

    return [parseTime(openTime, date), parseTime(closeTime, date)];
};

function parseTime(time: string, date: Date): Date {
    const [h = 0, m = 0] = time.split(':').map(Number);
    const d = new Date(date);
    d.setHours(h, m, 0, 0);
    return d;
}

function formatTime(d: Date): string {
    return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
}

export const getSalonAppointments = async (patronId: number) => {
    const salon = await prisma.salon.findFirst({ where: { patronId } });

    if (!salon) {
        throw new Error('Salon introuvable');
    }

    return prisma.appointment.findMany({
        where: { salonId: salon.id },
        include: {
            client: { select: { fullName: true, phoneNumber: true, profile: { select: { avatarUrl: true } } } },
            services: { include: { service: true } }
        },
        orderBy: { appointmentDate: 'asc' }
    });
};

export const getClientAppointments = async (clientId: number) => {
    return prisma.appointment.findMany({
        where: { clientId },
        include: {
            salon: { select: { name: true, address: true, coverImageUrl: true } },
            barber: { select: { fullName: true, profile: { select: { avatarUrl: true } } } },
            services: { include: { service: true } }
        },
        orderBy: [{ appointmentDate: 'desc' }]
    });
};

export const getEmployeeAppointments = async (employeeId: number) => {
    return prisma.appointment.findMany({
        where: { barberId: employeeId },
        include: {
            client: { select: { fullName: true, phoneNumber: true, profile: { select: { avatarUrl: true } } } },
            services: { include: { service: true } }
        },
        orderBy: { appointmentDate: 'desc' }
    });
};
