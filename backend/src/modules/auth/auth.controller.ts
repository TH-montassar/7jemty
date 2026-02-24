import type { Request, Response } from 'express';
import * as authService from './auth.service.js';
import { registerSchema } from './auth.schema.js';

export const register = async (req: Request, res: Response): Promise<void> => {
    try {
        const validatedData = registerSchema.parse(req.body);

        const result = await authService.registerUser(validatedData);

        res.status(201).json({ success: true, data: result });
    } catch (error: any) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};