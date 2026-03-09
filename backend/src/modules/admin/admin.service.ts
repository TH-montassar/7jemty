import { prisma } from '../../lib/db.js';
import { Role, ApprovalStatus, AppointmentStatus } from '../../../generated/prisma/index.js';

export const getAllUsers = async () => {
    const users = await prisma.user.findMany({
        include: {
            profile: true,
            _count: {
                select: {
                    salonsOwned: true,
                    appointmentsClient: true,
                    appointmentsBarber: true,
                }
            }
        }
    });
    return users.map(user => {
        const { passwordHash: _, ...userWithoutPassword } = user;
        return userWithoutPassword;
    });
};

export const deleteUser = async (userId: number) => {
    return await prisma.user.delete({
        where: { id: userId }
    });
};

export const updateUser = async (userId: number, data: { fullName?: string, phoneNumber?: string, role?: Role, isVerified?: boolean, isBlacklistedBySystem?: boolean, profile?: { email?: string, specialityTitle?: string, bio?: string, description?: string } }) => {
    const { profile, ...userData } = data;
    return await prisma.user.update({
        where: { id: userId },
        data: {
            ...userData,
            ...(profile && {
                profile: {
                    update: profile
                }
            })
        },
        include: { profile: true }
    });
};

export const updateSalonAdmin = async (salonId: number, data: any) => {
    const updatedSalon = await prisma.salon.update({
        where: { id: salonId },
        data: {
            ...(data.name !== undefined && { name: data.name }),
            ...(data.description !== undefined && { description: data.description }),
            ...(data.contactPhone !== undefined && { contactPhone: data.contactPhone }),
            ...(data.address !== undefined && { address: data.address }),
            ...(data.latitude !== undefined && { latitude: data.latitude }),
            ...(data.longitude !== undefined && { longitude: data.longitude }),
            ...(data.googleMapsUrl !== undefined && { googleMapsUrl: data.googleMapsUrl }),
            ...(data.websiteUrl !== undefined && { websiteUrl: data.websiteUrl }),
            ...(data.speciality !== undefined && { speciality: data.speciality }),
            ...(data.approvalStatus !== undefined && { approvalStatus: data.approvalStatus }),
            ...(data.coverImageUrl !== undefined && { coverImageUrl: data.coverImageUrl }),
        }
    });

    if (data.socialLinks !== undefined) {
        await prisma.salonSocialLink.deleteMany({ where: { salonId } });
        if (data.socialLinks.length > 0) {
            await prisma.salonSocialLink.createMany({
                data: data.socialLinks.map((link: { platform: string; url: string }) => ({
                    salonId,
                    platform: link.platform,
                    url: link.url,
                })),
            });
        }
    }

    // Handle working hours: delete all then re-insert
    if (data.workingHours !== undefined) {
        await prisma.workingHours.deleteMany({ where: { salonId } });
        if (data.workingHours.length > 0) {
            await prisma.workingHours.createMany({
                data: data.workingHours.map((wh: any) => ({
                    salonId,
                    dayOfWeek: wh.dayOfWeek,
                    openTime: wh.openTime,
                    closeTime: wh.closeTime,
                    isDayOff: wh.isDayOff ?? false,
                })),
            });
        }
    }

    return updatedSalon;
};

export const getAllSalonsAdmin = async () => {
    return await prisma.salon.findMany({
        include: {
            patron: true,
            _count: {
                select: {
                    employees: true,
                    services: true,
                    appointments: true,
                }
            }
        }
    });
};

export const updateSalonStatus = async (salonId: number, status: ApprovalStatus) => {
    return await prisma.salon.update({
        where: { id: salonId },
        data: { approvalStatus: status }
    });
};

export const deleteSalon = async (salonId: number) => {
    return await prisma.salon.delete({
        where: { id: salonId }
    });
};

export const getSalonStatsAdmin = async (salonId: number) => {
    const appointments = await prisma.appointment.findMany({
        where: {
            salonId: salonId,
            status: AppointmentStatus.COMPLETED
        },
        include: {
            barber: true
        }
    });

    let totalAppointments = appointments.length;
    let totalRevenue = 0;
    const specialistStats: Record<number, { name: string, count: number, revenue: number }> = {};

    for (const appt of appointments) {
        totalRevenue += appt.totalPrice;
        const barberId = appt.barberId;
        if (barberId) {
            if (!specialistStats[barberId]) {
                specialistStats[barberId] = {
                    name: appt.barber?.fullName || 'Inconnu',
                    count: 0,
                    revenue: 0
                };
            }
            specialistStats[barberId].count += 1;
            specialistStats[barberId].revenue += appt.totalPrice;
        }
    }

    return {
        totalAppointments,
        totalRevenue,
        specialistStats: Object.values(specialistStats)
    };
};
