import type { Request, Response } from 'express';
import * as authService from './auth.service.js';
import { registerSchema, loginSchema, requestOtpSchema, verifyOtpSchema } from './auth.schema.js';

export const register = async (req: Request, res: Response): Promise<void> => {
    console.log(`[AUTH] Incoming REGISTER request for:`, req.body?.phoneNumber);
    try {
        const validatedData = registerSchema.parse(req.body);

        const result = await authService.registerUser(validatedData);

        res.status(201).json({ success: true, data: result });
    } catch (error: any) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};

export const login = async (req: Request, res: Response): Promise<void> => {
    try {
        const validatedData = loginSchema.parse(req.body);

        const result = await authService.loginUser(validatedData);

        res.status(200).json({ success: true, data: result });
    } catch (error: any) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};

export const getMe = async (req: Request, res: Response): Promise<void> => {
    try {
        const userId = (req as any).user.userId;
        const user = await authService.getMe(userId);
        res.status(200).json({ success: true, data: user });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};

export const updateProfile = async (req: Request, res: Response): Promise<void> => {
    try {
        const userId = (req as any).user.userId;
        const result = await authService.updateProfile(userId, req.body);
        res.status(200).json({ success: true, data: result });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};

export const checkPhone = async (req: Request, res: Response): Promise<void> => {
    try {
        const { phoneNumber } = req.body;
        if (!phoneNumber) {
            res.status(400).json({ success: false, message: 'Le numéro de téléphone est requis' });
            return;
        }
        const result = await authService.checkPhoneExists(phoneNumber);
        res.status(200).json({ success: true, ...result });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};

export const requestOtp = async (req: Request, res: Response): Promise<void> => {
    console.log(`[AUTH] Incoming REQUEST-OTP request for:`, req.body?.phoneNumber);
    try {
        const validatedData = requestOtpSchema.parse(req.body);
        const result = await authService.requestOtp(validatedData.phoneNumber);
        res.status(200).json({ success: true, ...result });
    } catch (error: any) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};

export const verifyOtp = async (req: Request, res: Response): Promise<void> => {
    try {
        const validatedData = verifyOtpSchema.parse(req.body);
        const result = await authService.verifyOtp(validatedData.phoneNumber, validatedData.code);
        res.status(200).json({ success: true, ...result });
    } catch (error: any) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};
