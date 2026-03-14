import { prisma } from '../../lib/db.js';
import { broadcastToAll } from '../notifications/notifications.controller.js';
import { broadcastAppointmentRefresh, emitAppointmentEvent } from '../notifications/notification.orchestrator.js';
import { CLIENT_CANCELLATION_LOCK_HOURS, CLIENT_CANCELLATION_LOCK_MINUTES } from './appointment.constants.js';

type UserRole = 'CLIENT' | 'EMPLOYEE' | 'PATRON' | 'ADMIN';
type AppointmentStatusInput = 'PENDING' | 'CONFIRMED' | 'IN_PROGRESS' | 'ARRIVED' | 'COMPLETED' | 'CANCELLED' | 'DECLINED';
type AppointmentTargetInput = 'EMPLOYEE' | 'PATRON';

const ACTIVE_APPOINTMENT_STATUSES: AppointmentStatusInput[] = ['PENDING', 'CONFIRMED', 'IN_PROGRESS', 'ARRIVED'];

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

    const commonNotificationContext = {
        appointmentId,
        appointmentDate: appointment.appointmentDate,
        status,
        clientId: appointment.clientId,
        barberId: appointment.barberId,
        patronId: appointment.salon.patronId,
        actorUserId: userId,
        actorRole: userRole
    };

    if (status === 'CONFIRMED') {
        await emitAppointmentEvent('APPT_CONFIRMED', commonNotificationContext);
    }

    if (status === 'CANCELLED') {
        await emitAppointmentEvent('APPT_CANCELLED', commonNotificationContext);
    }

    if (status === 'DECLINED') {
        await emitAppointmentEvent('APPT_DECLINED', commonNotificationContext);
    }

    if (status === 'COMPLETED') {
        await prisma.appointment.update({
            where: { id: appointmentId },
            data: { reviewRequestedAt: new Date() }
        });

        await emitAppointmentEvent('APPT_COMPLETED', commonNotificationContext);
    }

    await broadcastAppointmentRefresh({
        appointmentId,
        status,
        userIds: [appointment.clientId, appointment.barberId, appointment.salon.patronId]
            .filter((id): id is number => Boolean(id))
    });

    return updated;
};

export const getBarberAvailability = async (
    salonId: number,
    dateString: string,
    requestedBarberId?: number,
    serviceIds?: number[],
    clientId_for_overlap_check?: number
) => {
    const date = new Date(dateString);
    let dayOfWeek = date.getDay();
    // JS getDay() returns 0 for Sunday, 1 for Monday...
    // Prisma DayOfWeek expects 1=Lundi, ..., 7=Dimanche.
    if (dayOfWeek === 0) dayOfWeek = 7;

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

    let clientAppointments: any[] = [];
    if (clientId_for_overlap_check) {
        clientAppointments = await prisma.appointment.findMany({
            where: {
                clientId: clientId_for_overlap_check,
                appointmentDate: { gte: dateStart, lt: dateEnd },
                status: { in: ACTIVE_APPOINTMENT_STATUSES }
            }
        });
    }

    return slots.map((slot) => {
        const slotStart = parseTime(slot, date);
        const slotEnd = new Date(slotStart);
        slotEnd.setMinutes(slotEnd.getMinutes() + totalDurationMinutes);

        const isBarberBusy = appointments.some((appt: any) => slotStart < appt.estimatedEndTime && slotEnd > appt.appointmentDate);
        const isClientBusy = clientAppointments.some((appt: any) => slotStart < appt.estimatedEndTime && slotEnd > appt.appointmentDate);

        const isAvailable = !isBarberBusy && !isClientBusy;
        return { time: slot, available: isAvailable };
    });
};

export const getAvailableDatesForRange = async (
    salonId: number,
    startDateStr: string,
    endDateStr: string,
    requestedBarberId?: number,
    serviceIds?: number[],
    clientId_for_overlap_check?: number
) => {
    const start = new Date(startDateStr);
    const end = new Date(endDateStr);

    // Limit to max 31 days to prevent overload
    if ((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24) > 31) {
        throw new Error("La plage de dates ne peut pas depasser 31 jours.");
    }

    const dateStrings: string[] = [];
    let current = new Date(start);

    while (current <= end) {
        dateStrings.push(current.toISOString().split('T')[0] as string);
        current.setDate(current.getDate() + 1);
    }

    // Process all dates in parallel
    const availabilityResults = await Promise.all(
        dateStrings.map(async (dateString) => {
            const slots = await getBarberAvailability(
                salonId,
                dateString,
                requestedBarberId,
                serviceIds,
                clientId_for_overlap_check
            );
            return {
                dateString,
                hasAvailability: slots.some((s: any) => s.available)
            };
        })
    );

    return availabilityResults
        .filter(result => result.hasAvailability)
        .map(result => result.dateString);
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
        throw new Error('Impossible de reserver un creneau dans le passe');
    }

    const estimatedEndTime = new Date(appointmentDate);
    estimatedEndTime.setMinutes(estimatedEndTime.getMinutes() + totalDurationMinutes);

    const [openHour, closeHour] = await getSalonOpenCloseForDate(salonId, appointmentDate);
    if (appointmentDate < openHour || estimatedEndTime > closeHour) {
        throw new Error('Le creneau depasse les horaires du salon');
    }

    const availability = await getBarberAvailability(salonId, dateString, barberId, serviceIds);
    if (!availability.some((s: any) => s.time === timeString && s.available)) {
        throw new Error("Le coiffeur n'est plus disponible pour cet horaire.");
    }

    const overlappingClientAppointment = await prisma.appointment.findFirst({
        where: {
            clientId,
            status: { in: ACTIVE_APPOINTMENT_STATUSES },
            AND: [
                { appointmentDate: { lt: estimatedEndTime } },
                { estimatedEndTime: { gt: appointmentDate } }
            ]
        }
    });

    if (overlappingClientAppointment) {
        throw new Error("Andek deja rendez-vous ekher fel wa9t hetha, ma tnajemch t3adi wehed jdid.");
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
        },
        include: {
            client: { select: { fullName: true, phoneNumber: true } },
            salon: { select: { name: true, address: true, coverImageUrl: true } },
            barber: { select: { fullName: true, profile: { select: { avatarUrl: true } } } },
            services: { include: { service: true } }
        }
    });

    await emitAppointmentEvent('APPT_CREATED', {
        appointmentId: appointment.id,
        appointmentDate,
        status: 'PENDING',
        clientId,
        barberId: targetBarberId,
        patronId: salon.patronId,
        dedupeWindowMs: 30_000
    });

    await broadcastAppointmentRefresh({
        appointmentId: appointment.id,
        status: 'PENDING',
        userIds: [clientId, targetBarberId, salon.patronId]
            .filter((id): id is number => Boolean(id))
    });

    // Broadcast availability change to all clients
    broadcastToAll({
        type: 'AVAILABILITY_CHANGED',
        salonId
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
        await emitAppointmentEvent('APPT_BARBER_ARRIVAL_CHECK', {
            appointmentId: appointment.id,
            appointmentDate: appointment.appointmentDate,
            status: appointment.status,
            clientId: appointment.clientId,
            barberId: appointment.barberId,
            patronId: appointment.salon.patronId,
            targetUserIds: [appointment.barberId ?? appointment.salon.patronId],
            dedupeWindowMs: 60_000
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

        await emitAppointmentEvent('APPT_BARBER_COMPLETION_CHECK', {
            appointmentId: appointment.id,
            appointmentDate: appointment.appointmentDate,
            status: appointment.status,
            clientId: appointment.clientId,
            barberId: appointment.barberId,
            patronId: appointment.salon.patronId,
            targetUserIds: [appointment.barberId ?? appointment.salon.patronId],
            dedupeWindowMs: 5 * 60_000
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
        const cancellationLockDate = new Date(appointmentDate.getTime() - CLIENT_CANCELLATION_LOCK_MINUTES * 60 * 1000);
        if (new Date() >= cancellationLockDate) {
            throw new Error(`Annulation client impossible a moins de ${CLIENT_CANCELLATION_LOCK_HOURS}h du rendez-vous`);
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

    // ADMIN has bypass permission, so we don't throw an error for ADMIN
};

const getEmployeeSalonId = async (userId: number) => {
    const user = await prisma.user.findUnique({ where: { id: userId }, select: { workplaceSalonId: true } });
    return user?.workplaceSalonId;
};

const getSalonOpenCloseForDate = async (salonId: number, date: Date): Promise<[Date, Date]> => {
    let dayOfWeek = date.getDay();
    // JS getDay() returns 0 for Sunday
    if (dayOfWeek === 0) dayOfWeek = 7;

    const workingHours = await prisma.workingHours.findFirst({
        where: { salonId, dayOfWeek }
    });

    let openTime = '08:00';
    let closeTime = '17:00';

    if (workingHours?.isDayOff) {
        throw new Error('Salon ferme ce jour');
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
            salon: { select: { name: true, address: true, coverImageUrl: true } },
            barber: { select: { fullName: true, profile: { select: { avatarUrl: true } } } },
            services: { include: { service: true } }
        },
        orderBy: { appointmentDate: 'asc' }
    });
};

export const getAppointmentsBySalonId = async (salonId: number) => {
    return prisma.appointment.findMany({
        where: { salonId },
        include: {
            client: { select: { fullName: true, phoneNumber: true, profile: { select: { avatarUrl: true } } } },
            salon: { select: { name: true, address: true, coverImageUrl: true } },
            barber: { select: { fullName: true, profile: { select: { avatarUrl: true } } } },
            services: { include: { service: true } }
        },
        orderBy: { appointmentDate: 'asc' }
    });
};

export const getClientAppointments = async (clientId: number) => {
    return prisma.appointment.findMany({
        where: { clientId },
        include: {
            client: { select: { fullName: true, phoneNumber: true } },
            salon: { select: { id: true, name: true, address: true, coverImageUrl: true, googleMapsUrl: true, latitude: true, longitude: true } },
            barber: { select: { fullName: true, profile: { select: { avatarUrl: true } } } },
            services: { include: { service: true } },
            review: { select: { rating: true, comment: true, createdAt: true } }
        },
        orderBy: [{ appointmentDate: 'desc' }]
    });
};

export const getEmployeeAppointments = async (employeeId: number) => {
    return prisma.appointment.findMany({
        where: { barberId: employeeId },
        include: {
            client: { select: { id: true, fullName: true, phoneNumber: true } },
            barber: { select: { fullName: true, profile: { select: { avatarUrl: true } } } },
            salon: { select: { id: true, name: true, address: true } },
            services: { include: { service: true } }
        },
        orderBy: { appointmentDate: 'desc' },
        take: 50
    });
};

export const extendAppointment = async (appointmentId: number, minutes: number, userId: number, role: 'PATRON' | 'EMPLOYEE') => {
    const appointment = await prisma.appointment.findUnique({
        where: { id: appointmentId },
        include: { salon: true }
    });

    if (!appointment) throw new Error("Rendez-vous moch mawjoud");

    if (role === 'EMPLOYEE' && appointment.barberId !== userId) {
        throw new Error("Non autorise bch tzid wa9t");
    }
    if (role === 'PATRON' && appointment.salon.patronId !== userId) {
        throw new Error("Non autorise bch tzid wa9t");
    }

    if (appointment.status !== 'IN_PROGRESS') {
        throw new Error("Tnajemchi tzid wa9t ken lel maw3ed li en cours");
    }

    const newEndTime = new Date(appointment.estimatedEndTime.getTime() + minutes * 60000);

    return prisma.appointment.update({
        where: { id: appointmentId },
        data: { estimatedEndTime: newEndTime },
        include: { client: true }
    });
};

export const postponeNoShowWithCascade = async (
    appointmentId: number,
    minutes: number,
    userId: number,
    role: 'PATRON' | 'EMPLOYEE'
) => {
    const appointment = await prisma.appointment.findUnique({
        where: { id: appointmentId },
        include: { salon: true }
    });

    if (!appointment) {
        throw new Error('Rendez-vous moch mawjoud');
    }

    await assertUpdatePermission(appointment, userId, role);

    if (appointment.status !== 'CONFIRMED') {
        throw new Error('Tnajem t3adel no-show postpone ken lel rendez-vous CONFIRMED');
    }

    if (!appointment.barberId) {
        throw new Error('Mafamech specialist ma3youne lel rendez-vous hetha');
    }

    const shiftMs = minutes * 60000;
    const startOfDay = new Date(appointment.appointmentDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(startOfDay);
    endOfDay.setDate(endOfDay.getDate() + 1);

    const shiftedAppointments = await prisma.$transaction(async (tx: any) => {
        const appointmentsToShift = await tx.appointment.findMany({
            where: {
                salonId: appointment.salonId,
                barberId: appointment.barberId,
                appointmentDate: {
                    gte: appointment.appointmentDate,
                    lt: endOfDay
                },
                status: {
                    in: ['PENDING', 'CONFIRMED', 'ARRIVED']
                }
            },
            include: {
                salon: {
                    select: {
                        patronId: true
                    }
                }
            },
            orderBy: {
                appointmentDate: 'asc'
            }
        });

        const updatedAppointments: any[] = [];

        for (const appt of appointmentsToShift) {
            const newAppointmentDate = new Date(appt.appointmentDate.getTime() + shiftMs);
            const newEstimatedEndTime = new Date(appt.estimatedEndTime.getTime() + shiftMs);

            const updated = await tx.appointment.update({
                where: { id: appt.id },
                data: {
                    appointmentDate: newAppointmentDate,
                    estimatedEndTime: newEstimatedEndTime
                },
                include: {
                    salon: {
                        select: {
                            patronId: true
                        }
                    }
                }
            });

            updatedAppointments.push(updated);
        }

        return updatedAppointments;
    });

    for (const appt of shiftedAppointments) {
        await emitAppointmentEvent('APPT_SHIFTED', {
            appointmentId: appt.id,
            appointmentDate: appt.appointmentDate,
            status: appt.status,
            clientId: appt.clientId,
            barberId: appt.barberId,
            patronId: appt.salon.patronId,
            actorUserId: userId,
            actorRole: role,
            extraData: { shiftMinutes: minutes }
        });
    }
    broadcastToAll({
        type: 'AVAILABILITY_CHANGED',
        salonId: appointment.salonId
    });

    return {
        appointmentId,
        minutes,
        shiftedCount: shiftedAppointments.length,
        shiftedAppointmentIds: shiftedAppointments.map((appt: any) => appt.id)
    };
};

export const getUnreviewedAppointments = async (clientId: number) => {
    return prisma.appointment.findMany({
        where: {
            clientId,
            status: 'COMPLETED',
            review: null
        },
        include: {
            salon: { select: { id: true, name: true, coverImageUrl: true } },
            barber: { select: { id: true, fullName: true } },
            services: { include: { service: true } }
        },
        orderBy: { completedAt: 'desc' }
    });
};

export const submitReview = async (appointmentId: number, clientId: number, salonId: number, rating: number, comment?: string) => {
    const appointment = await prisma.appointment.findFirst({
        where: { id: appointmentId, clientId, salonId }
    });

    if (!appointment || appointment.status !== 'COMPLETED') {
        throw new Error("Rendez-vous ghalet ou mezal makmelch");
    }

    const existingReview = await prisma.review.findUnique({
        where: { appointmentId }
    });

    if (existingReview) {
        throw new Error("Aatit deja rayek f hal rendez-vous");
    }

    return prisma.$transaction(async (tx) => {
        const review = await tx.review.create({
            data: {
                appointmentId,
                clientId,
                salonId,
                rating,
                comment: comment || null
            }
        });

        // Recalculate Salon Rating
        const allReviews = await tx.review.findMany({
            where: { salonId },
            select: { rating: true }
        });

        const avgRating = allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length;

        await tx.salon.update({
            where: { id: salonId },
            data: { rating: avgRating }
        });

        return review;
    });
}
