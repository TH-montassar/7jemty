import { prisma } from '../../lib/db.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env.js';

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
                create: {}
            }
        },
        include: {
            profile: true
        }
    });


    const token = jwt.sign({ userId: user.id, role: user.role }, env.JWT_SECRET, {
        expiresIn: '30d',
    });


    const { passwordHash: _, ...userWithoutPassword } = user;
    return { user: userWithoutPassword, token };
};