import { Role } from '@prisma/client';
import { z } from 'zod';

export const registerSchema = z.object({
    fullName: z.string().min(3, "3 min"),
    phoneNumber: z.string().min(8, "num mrigel"),
    password: z.string().min(6, "6 min"),
    role: z.nativeEnum(Role).optional().default(Role.CLIENT),
});