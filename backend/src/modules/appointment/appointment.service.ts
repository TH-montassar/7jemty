import { prisma } from '../../lib/db.js';
import { AppointmentStatus } from '../../../generated/prisma/index.js';

export const updateAppointmentStatus = async (
    appointmentId: number,
    status: AppointmentStatus,
    userId: number,
    userRole: string
) => {
    const appointment = await prisma.appointment.findUnique({
        where: { id: appointmentId },
        include: { salon: true }
    });

    if (!appointment) {
        throw new Error("Rendez-vous introuvable");
    }

    // Permissions Check
    if (userRole === 'CLIENT' && appointment.clientId !== userId) {
        throw new Error("Ma 3andekch l'7a9 tbadel rdv mouch mte3ek");
    }

    if (userRole === 'EMPLOYEE' && appointment.salon.id !== (await getEmployeeSalonId(userId))) {
        throw new Error("Hetha rdv fi salon we5er, ma tnajemch tmesou");
    }

    if (userRole === 'PATRON' && appointment.salon.patronId !== userId) {
        throw new Error("Hetha rdv fi salon we5er, ma tnajemch tmesou");
    }

    // Logic transitions
    if (status === 'COMPLETED' && appointment.status !== 'CONFIRMED' && appointment.status !== 'ARRIVED') {
        throw new Error("Tnajem t7ot COMPLETED ken l'rdv deja CONFIRMED wala ARRIVED");
    }

    const updated = await prisma.appointment.update({
        where: { id: appointmentId },
        data: { status }
    });

    return updated;
};

// Helper function
const getEmployeeSalonId = async (userId: number) => {
    const user = await prisma.user.findUnique({
        where: { id: userId },
        select: { workplaceSalonId: true }
    });
    return user?.workplaceSalonId;
};

export const getBarberAvailability = async (salonId: number, dateString: string, requestedBarberId?: number) => {
    const date = new Date(dateString);
    const dayOfWeek = date.getDay();

    // 1. Get Salon Working Hours for this day
    const workingHours = await prisma.workingHours.findFirst({
        where: { salonId, dayOfWeek }
    });

    let openTime = "08:00";
    let closeTime = "17:00";
    let isDayOff = false;

    if (workingHours) {
        if (workingHours.isDayOff) isDayOff = true;
        if (workingHours.openTime) openTime = workingHours.openTime;
        if (workingHours.closeTime) closeTime = workingHours.closeTime;
    }

    if (isDayOff) {
        return [];
    }

    // Generate 30 mins slots between openTime and closeTime
    const slots: string[] = [];
    let current = parseTime(openTime, date);
    const end = parseTime(closeTime, date);

    while (current < end) {
        slots.push(formatTime(current));
        current.setMinutes(current.getMinutes() + 30);
    }

    // Find conflicting appointments
    const dateStart = new Date(date);
    dateStart.setHours(0, 0, 0, 0);
    const dateEnd = new Date(dateStart);
    dateEnd.setDate(dateEnd.getDate() + 1);

    const appointmentsMap = await prisma.appointment.findMany({
        where: {
            salonId,
            ...(requestedBarberId ? { barberId: requestedBarberId } : {}),
            appointmentDate: {
                gte: dateStart,
                lt: dateEnd
            },
            status: { in: ['PENDING', 'CONFIRMED', 'ARRIVED'] }
        }
    });

    // Filter slots that overlap with existing appointments
    return slots.filter(slot => {
        const slotStart = parseTime(slot, date);
        const slotEnd = new Date(slotStart);
        slotEnd.setMinutes(slotEnd.getMinutes() + 30); // minimum 30 min duration overlap check

        for (const appt of appointmentsMap) {
            if (slotStart < appt.estimatedEndTime && slotEnd > appt.appointmentDate) {
                return false; // overlap
            }
        }
        return true;
    });
};

export const createClientAppointment = async (
    clientId: number,
    salonId: number,
    barberId: number,
    dateString: string,
    timeString: string,
    serviceIds: number[]
) => {
    const services = await prisma.service.findMany({
        where: { id: { in: serviceIds } }
    });

    if (services.length !== serviceIds.length) {
        throw new Error("Un ou plusieurs services sont invalides.");
    }

    let totalPrice = 0;
    let totalDurationMinutes = 0;

    for (const service of services) {
        totalPrice += service.price;
        // if durationMinutes is empty, assume 30 minutes
        totalDurationMinutes += service.durationMinutes || 30;
    }

    const appointmentDate = parseTime(timeString, new Date(dateString));
    const estimatedEndTime = new Date(appointmentDate);
    estimatedEndTime.setMinutes(estimatedEndTime.getMinutes() + totalDurationMinutes);

    // Verify availability first
    const conflicting = await prisma.appointment.findFirst({
        where: {
            salonId,
            barberId,
            status: { in: ['PENDING', 'CONFIRMED', 'ARRIVED'] },
            OR: [
                {
                    appointmentDate: { lt: estimatedEndTime },
                    estimatedEndTime: { gt: appointmentDate }
                }
            ]
        }
    });

    if (conflicting) {
        throw new Error("Le coiffeur n'est plus disponible pour cet horaire.");
    }

    const appointment = await prisma.appointment.create({
        data: {
            clientId,
            salonId,
            barberId,
            appointmentDate,
            estimatedEndTime,
            totalPrice,
            totalDurationMinutes,
            status: 'PENDING',
            services: {
                create: serviceIds.map(serviceId => ({
                    service: { connect: { id: serviceId } }
                }))
            }
        }
    });

    return appointment;
};

export const getSalonAppointments = async (patronId: number) => {
    const salon = await prisma.salon.findFirst({
        where: { patronId }
    });

    if (!salon) {
        throw new Error("Salon introuvable");
    }

    const appointments = await prisma.appointment.findMany({
        where: { salonId: salon.id },
        include: {
            client: {
                select: { fullName: true, phoneNumber: true, profile: { select: { avatarUrl: true } } }
            },
            services: {
                include: { service: true }
            }
        },
        orderBy: { appointmentDate: 'asc' }
    });

    return appointments;
};

export const getClientAppointments = async (clientId: number) => {
    const appointments = await prisma.appointment.findMany({
        where: { clientId },
        include: {
            salon: {
                select: { name: true, address: true, coverImageUrl: true }
            },
            barber: {
                select: { fullName: true, profile: { select: { avatarUrl: true } } }
            },
            services: {
                include: { service: true }
            }
        },
        orderBy: [
            { appointmentDate: 'desc' },
        ]
    });

    return appointments;
};

// Utils
function parseTime(time: string, date: Date): Date {
    const parts = time.split(':').map(Number);
    const h = parts.length > 0 && parts[0] !== undefined ? parts[0] : 0;
    const m = parts.length > 1 && parts[1] !== undefined ? parts[1] : 0;
    const d = new Date(date);
    d.setHours(h, m, 0, 0);
    return d;
}

function formatTime(d: Date): string {
    return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
}
