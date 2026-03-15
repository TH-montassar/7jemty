import { prisma } from '../../lib/db.js';
import admin from 'firebase-admin';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env.js';
import { sendNotification } from '../notifications/notifications.service.js';
import { broadcastNotificationToUser } from '../notifications/notifications.controller.js';
import { Role } from '../../../generated/prisma/index.js';

const PHONE_VERIFY_PURPOSE = 'REGISTER_PHONE_VERIFICATION';
const PHONE_VERIFY_TOKEN_EXPIRY = '15m';

const createPhoneVerificationToken = (phoneNumber: string): string => {
    return jwt.sign(
        { phoneNumber, purpose: PHONE_VERIFY_PURPOSE },
        env.JWT_SECRET,
        { expiresIn: PHONE_VERIFY_TOKEN_EXPIRY }
    );
};

const assertPhoneVerifiedForRegister = (
    phoneNumber: string,
    phoneVerificationToken?: string | undefined
) => {
    if (!phoneVerificationToken) {
        throw new Error('Verification du numero requise avant inscription.');
    }

    try {
        const decoded = jwt.verify(phoneVerificationToken, env.JWT_SECRET) as jwt.JwtPayload | string;
        if (typeof decoded === 'string') {
            throw new Error('Token invalide');
        }

        if (decoded.purpose !== PHONE_VERIFY_PURPOSE) {
            throw new Error('Token invalide');
        }

        if (decoded.phoneNumber !== phoneNumber) {
            throw new Error('Le numero verifie ne correspond pas.');
        }
    } catch {
        throw new Error('La verification du numero a expire ou est invalide.');
    }
};

export const registerUser = async (data: any) => {
    assertPhoneVerifiedForRegister(data.phoneNumber, data.phoneVerificationToken);

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

    const welcomeNotif = await prisma.notification.create({
        data: {
            userId: user.id,
            title: 'Bienvenue sur 7jemty !',
            body: 'Votre compte a ete cree avec succes.',
        }
    });
    broadcastNotificationToUser(user.id, welcomeNotif);

    const admins = await prisma.user.findMany({
        where: { role: Role.ADMIN },
        include: { profile: true }
    });

    for (const adminUser of admins) {
        const adminNotif = await prisma.notification.create({
            data: {
                userId: adminUser.id,
                title: 'Nouveau membre',
                body: `Un nouvel utilisateur (${user.fullName} - ${user.role}) vient de s'inscrire.`
            }
        });
        broadcastNotificationToUser(adminUser.id, adminNotif);
        if (adminUser.profile?.fcmToken) {
            await sendNotification(
                adminUser.profile.fcmToken,
                'Nouveau membre',
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
    const user = await prisma.user.findFirst({
        where: { phoneNumber: data.phoneNumber },
        include: {
            _count: {
                select: { salonsOwned: true }
            }
        }
    });

    if (!user) {
        throw new Error('Numero de telephone ou mot de passe incorrect');
    }

    const isPasswordValid = await bcrypt.compare(data.password, user.passwordHash);
    if (!isPasswordValid) {
        throw new Error('Numero de telephone ou mot de passe incorrect');
    }

    const token = jwt.sign({ userId: user.id, role: user.role }, env.JWT_SECRET, {
        expiresIn: '30d',
    });

    const { passwordHash: _, _count, ...userWithoutPassword } = user;
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

export const updateProfile = async (
    userId: number,
    data: {
        fullName?: string;
        phoneNumber?: string;
        email?: string;
        avatarUrl?: string;
        bio?: string;
        fcmToken?: string | null;
        address?: string;
    }
) => {
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
                ...(data.fcmToken !== undefined && { fcmToken: data.fcmToken }),
                ...(data.address !== undefined && { address: data.address })
            }
        });

        return updatedProfile;
    });
};

export const checkPhoneExists = async (phoneNumber: string) => {
    const user = await prisma.user.findUnique({
        where: { phoneNumber }
    });

    if (user) {
        return { exists: true, role: user.role };
    }

    return { exists: false, role: null };
};

export const requestOtp = async (phoneNumber: string) => {
    const oneMinuteAgo = new Date(Date.now() - 60 * 1000);
    const recentOtp = await prisma.otpCode.findFirst({
        where: {
            phoneNumber,
            createdAt: { gte: oneMinuteAgo }
        }
    });

    if (recentOtp) {
        throw new Error('Veuillez patienter 60 secondes avant de demander un nouveau code.');
    }

    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const otpsTodayCount = await prisma.otpCode.count({
        where: {
            phoneNumber,
            createdAt: { gte: twentyFourHoursAgo }
        }
    });

    if (otpsTodayCount >= 3) {
        throw new Error('Vous avez depasse la limite de 3 tentatives. Reessayez dans 24 heures.');
    }

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    await prisma.otpCode.create({
        data: {
            phoneNumber,
            code,
            expiresAt,
        }
    });

    console.log('\n' + '='.repeat(50));
    console.log(`🚀 [SIMULATED SMS] TO: ${phoneNumber}`);
    console.log(`💬 CODE: ${code}`);
    console.log('='.repeat(50) + '\n');

    return {
        message: 'Code OTP envoye avec succes',
        ...(env.NODE_ENV !== 'production' && { debugCode: code })
    };
};

export const verifyOtp = async (phoneNumber: string, submittedCode: string) => {
    const otpRecord = await prisma.otpCode.findFirst({
        where: {
            phoneNumber,
            expiresAt: { gt: new Date() }
        },
        orderBy: {
            createdAt: 'desc'
        }
    });

    if (!otpRecord) {
        throw new Error('Aucun code OTP valide n a ete trouve. Veuillez en demander un nouveau.');
    }

    if (otpRecord.code !== submittedCode) {
        throw new Error('Code OTP incorrect.');
    }

    await prisma.otpCode.delete({
        where: { id: otpRecord.id }
    });

    const phoneVerificationToken = createPhoneVerificationToken(phoneNumber);

    return {
        message: 'Numero verifie avec succes',
        phoneVerificationToken
    };
};

export const verifyFirebaseToken = async (firebaseToken: string) => {
    if (!admin.apps.length) {
        throw new Error('Firebase Admin n est pas configure sur le serveur.');
    }

    let decodedToken: admin.auth.DecodedIdToken;
    try {
        decodedToken = await admin.auth().verifyIdToken(firebaseToken);
    } catch {
        throw new Error('Firebase token invalide ou expire.');
    }

    const phoneNumber = decodedToken.phone_number;
    if (!phoneNumber) {
        throw new Error('Aucun numero de telephone verifie dans le token Firebase.');
    }

    const normalizedPhoneNumber = phoneNumber.replace(/^\+216/, '');
    const phoneVerificationToken = createPhoneVerificationToken(normalizedPhoneNumber);

    return {
        message: 'Numero verifie avec succes via Firebase',
        phoneNumber: normalizedPhoneNumber,
        phoneVerificationToken
    };
};

type AdminUserUpdateInput = {
    fullName?: string;
    phoneNumber?: string;
    role?: Role;
    isVerified?: boolean;
    isBlacklistedBySystem?: boolean;
    profile?: {
        email?: string;
        specialityTitle?: string;
        bio?: string;
        description?: string;
    };
};

export const getAllUsersAdmin = async () => {
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

    return users.map((user) => {
        const { passwordHash: _, ...userWithoutPassword } = user;
        return userWithoutPassword;
    });
};

export const updateUserAdmin = async (userId: number, data: AdminUserUpdateInput) => {
    const { profile, ...userData } = data;

    return prisma.user.update({
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

export const deleteUserAdmin = async (userId: number) => {
    return prisma.user.delete({
        where: { id: userId }
    });
};
