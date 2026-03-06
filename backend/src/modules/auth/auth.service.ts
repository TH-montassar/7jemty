import { prisma } from '../../lib/db.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env.js';
import { sendNotification } from '../notifications/notifications.service.js';
import { Role } from '../../../generated/prisma/index.js';

export const registerUser = async (data: any) => {

    const existingUser = await prisma.user.findUnique({
        where: { phoneNumber: data.phoneNumber }
    });

    if (existingUser) {
        throw new Error('ra9em deja msta3mel ');
    }


    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(data.password, salt);

    const user = await prisma.user.create({
        data: {
            fullName: data.fullName,
            phoneNumber: data.phoneNumber,
            passwordHash,
            role: data.role,
            profile: {
                create: {
                    address: data.address,
                    latitude: data.latitude,
                    longitude: data.longitude
                }
            }
        },
        include: {
            profile: true
        }
    });

    // Create a welcome notification with the password instructions
    await prisma.notification.create({
        data: {
            userId: user.id,
            title: "Bienvenue sur 7jemty ! 🎉",
            body: `Votre compte a été créé avec succès. Votre mot de passe par défaut est votre numéro de téléphone : ${data.phoneNumber}. Pensez à le modifier dans votre profil pour plus de sécurité.`,
        }
    });

    // Notify all ADMIN users
    const admins = await prisma.user.findMany({
        where: { role: Role.ADMIN },
        include: { profile: true }
    });

    for (const admin of admins) {
        await prisma.notification.create({
            data: {
                userId: admin.id,
                title: "Nouveau membre",
                body: `Un nouvel utilisateur (${user.fullName} - ${user.role}) vient de s'inscrire.`
            }
        });
        if (admin.profile?.fcmToken) {
            await sendNotification(
                admin.profile.fcmToken,
                "Nouveau membre",
                `Un nouvel utilisateur (${user.fullName}) vient de s'inscrire.`,
                { type: 'NEW_USER' }
            );
        }
    }


    const token = jwt.sign({ userId: user.id, role: user.role }, env.JWT_SECRET, {
        expiresIn: '30d',
    });


    const { passwordHash: _, ...userWithoutPassword } = user;
    return { user: userWithoutPassword, token };
};

export const loginUser = async (data: any) => {
    // 1. Nlawjou 3al l'user b numro l'telifoun w nchoufou chnouwa 3andou salons (ken role PATRON)
    const user = await prisma.user.findFirst({
        where: { phoneNumber: data.phoneNumber },
        include: {
            _count: {
                select: { salonsOwned: true }
            }
        }
    });

    // 2. Ken ma l9inehoch wala l'mot de passe ghalet
    if (!user) {
        throw new Error('Numéro de téléphone ou mot de passe incorrect');
    }

    // 3. N9arnou l'mot de passe elli ktebou bel mot de passe l'mcheffer fel base
    const isPasswordValid = await bcrypt.compare(data.password, user.passwordHash);
    if (!isPasswordValid) {
        throw new Error('Numéro de téléphone ou mot de passe incorrect');
    }

    // 4. Ken kol chay s7i7, nasn3ou l'Token jdid
    const token = jwt.sign({ userId: user.id, role: user.role }, env.JWT_SECRET, {
        expiresIn: '30d',
    });

    const { passwordHash: _, _count, ...userWithoutPassword } = user;

    // Nraj3ou hasSalon (boolean) bech l'Frontend ya3ref yوجهou l'CreateSalon wala l'Dashboard
    const hasSalon = _count.salonsOwned > 0;

    return { user: { ...userWithoutPassword, hasSalon }, token };
};

export const getMe = async (userId: number) => {
    const user = await prisma.user.findUnique({
        where: { id: userId },
        include: {
            profile: true
        }
    });

    if (!user) {
        throw new Error('User not found');
    }

    const { passwordHash: _, ...userWithoutPassword } = user;
    return userWithoutPassword;
};

export const updateProfile = async (userId: number, data: { fullName?: string; phoneNumber?: string; email?: string; avatarUrl?: string; bio?: string; fcmToken?: string }) => {
    return await prisma.$transaction(async (tx) => {
        if (data.fullName !== undefined || data.phoneNumber !== undefined) {
            await tx.user.update({
                where: { id: userId },
                data: {
                    ...(data.fullName !== undefined && { fullName: data.fullName }),
                    ...(data.phoneNumber !== undefined && { phoneNumber: data.phoneNumber })
                }
            });
        }

        const updatedProfile = await tx.profile.update({
            where: { userId },
            data: {
                ...(data.avatarUrl !== undefined && { avatarUrl: data.avatarUrl }),
                ...(data.bio !== undefined && { bio: data.bio }),
                ...(data.email !== undefined && { email: data.email }),
                ...(data.fcmToken !== undefined && { fcmToken: data.fcmToken })
            }
        });

        return updatedProfile;
    });
};

export const checkPhoneExists = async (phoneNumber: string) => {
    const user = await prisma.user.findUnique({
        where: { phoneNumber }
    });
    return !!user;
};