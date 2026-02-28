import type { Response } from 'express';
import type { AuthRequest } from '../../middlewares/auth.middleware.js';
import * as uploadService from './upload.service.js';

export const uploadFileHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        if (!req.file) {
            res.status(400).json({ success: false, message: 'No file uploaded' });
            return;
        }

        const result = await uploadService.uploadToCloudinary(req.file);

        res.json({
            success: true,
            ...result
        });
    } catch (error: any) {
        console.error('Upload handler error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
};
