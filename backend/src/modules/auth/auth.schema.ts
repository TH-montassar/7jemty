import { Role } from '../../../generated/prisma/index.js';
import { z } from 'zod';

export const registerSchema = z.object({
    fullName: z.string().min(3, "3 min"),
    phoneNumber: z.string().min(8, "num mrigel"),
    password: z.string().min(6, "6 min"),
    role: z.nativeEnum(Role).optional().default(Role.CLIENT),
    address: z.string().optional(),
    latitude: z.number().optional(),
    longitude: z.number().optional(),
    phoneVerificationToken: z.string().optional(),
});

export const loginSchema = z.object({
    phoneNumber: z.string().min(8, "Numéro de téléphone invalide"),
    password: z.string().min(6, "Mot de passe invalide"),
});

export const requestOtpSchema = z.object({
    phoneNumber: z.string().min(8, "Numéro de téléphone invalide"),
});

export const verifyOtpSchema = z.object({
    phoneNumber: z.string().min(8, "Numéro de téléphone invalide"),
    code: z.string().length(6, "Le code doit contenir 6 chiffres"),
});