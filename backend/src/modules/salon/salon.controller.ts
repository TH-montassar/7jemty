import type { Response } from 'express';
import type { AuthRequest } from '../../middlewares/auth.middleware.js';
import { createSalonSchema, updateSalonSchema } from './salon.schema.js';
import * as salonService from './salon.service.js';

export const createSalonHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        // 1. L'userId yjina mel Middleware (protect)
        const patronId = req.user!.userId;

        // 2. Nthabtou e-data b Zod
        const validatedData = createSalonSchema.parse(req.body);

        // 3. Nasn3ou e-salon
        const salon = await salonService.createSalon(patronId, validatedData);

        res.status(201).json({ success: true, data: salon });
    } catch (error: any) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};

export const updateSalonHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const patronId = req.user!.userId;
        const validatedData = updateSalonSchema.parse(req.body);

        const updatedSalon = await salonService.updateSalon(patronId, validatedData);

        res.status(200).json({ success: true, data: updatedSalon });
    } catch (error: any) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};

export const getMySalonHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const patronId = req.user!.userId;

        // Njibou l'salon tebe3 e-patron hedha
        const salon = await salonService.getSalonByPatronId(patronId);

        res.status(200).json({ success: true, data: salon });
    } catch (error: any) {
        res.status(404).json({ success: false, message: error.message });
    }
};