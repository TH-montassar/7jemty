import { prisma } from '../../lib/db.js';
import { Role, ApprovalStatus } from '../../../generated/prisma/index.js';

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
    return await prisma.salon.update({
        where: { id: salonId },
        data: {
            name: data.name,
            description: data.description,
            contactPhone: data.contactPhone,
            address: data.address,
            latitude: data.latitude,
            longitude: data.longitude,
            googleMapsUrl: data.googleMapsUrl,
            websiteUrl: data.websiteUrl,
            speciality: data.speciality,
            approvalStatus: data.approvalStatus,
        }
    });
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
