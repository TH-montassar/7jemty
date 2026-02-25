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
