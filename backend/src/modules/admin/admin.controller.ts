import type { Response } from 'express';
import type { AuthRequest } from '../../middlewares/auth.middleware.js';
import { getAllUsers, deleteUser, getAllSalonsAdmin, updateSalonStatus, deleteSalon, updateUser, updateSalonAdmin } from './admin.service.js';

export const getAllUsersHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const users = await getAllUsers();
        res.status(200).json({ success: true, data: users });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const deleteUserHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const id = parseInt(req.params.id as string);
        await deleteUser(id);
        res.status(200).json({ success: true, message: 'User deleted' });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const updateUserHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const id = parseInt(req.params.id as string);
        const { fullName, phoneNumber, role, isVerified, isBlacklistedBySystem, profile } = req.body;
        const updatedUser = await updateUser(id, { fullName, phoneNumber, role, isVerified, isBlacklistedBySystem, profile });
        res.status(200).json({ success: true, data: updatedUser });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const getAllSalonsAdminHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const salons = await getAllSalonsAdmin();
        res.status(200).json({ success: true, data: salons });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const updateSalonStatusHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const id = parseInt(req.params.id as string);
        const { status } = req.body;
        const updatedSalon = await updateSalonStatus(id, status);
        res.status(200).json({ success: true, data: updatedSalon });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const deleteSalonHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const id = parseInt(req.params.id as string);
        await deleteSalon(id);
        res.status(200).json({ success: true, message: 'Salon deleted' });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const updateSalonAdminHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const id = parseInt(req.params.id as string);
        const updatedSalon = await updateSalonAdmin(id, req.body);
        res.status(200).json({ success: true, data: updatedSalon });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};
