import type { Response } from 'express';
import type { AuthRequest } from '../../middlewares/auth.middleware.js';
import { deleteUserAdmin, getAllUsersAdmin, updateUserAdmin } from './auth.service.js';

const parseId = (rawId: string): number => {
    const id = Number.parseInt(rawId, 10);
    if (Number.isNaN(id)) {
        throw new Error('ID utilisateur invalide');
    }
    return id;
};

export const getAllUsersAdminHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const users = await getAllUsersAdmin();
        res.status(200).json({ success: true, data: users });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const updateUserAdminHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const id = parseId(req.params.id as string);
        const { fullName, phoneNumber, role, isVerified, isBlacklistedBySystem, profile } = req.body;
        const updatedUser = await updateUserAdmin(id, { fullName, phoneNumber, role, isVerified, isBlacklistedBySystem, profile });
        res.status(200).json({ success: true, data: updatedUser });
    } catch (error: any) {
        const status = error.message?.includes('invalide') ? 400 : 500;
        res.status(status).json({ success: false, message: error.message });
    }
};

export const deleteUserAdminHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const id = parseId(req.params.id as string);
        await deleteUserAdmin(id);
        res.status(200).json({ success: true, message: 'User deleted' });
    } catch (error: any) {
        const status = error.message?.includes('invalide') ? 400 : 500;
        res.status(status).json({ success: false, message: error.message });
    }
};
