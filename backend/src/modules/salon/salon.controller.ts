import type { Response } from 'express';
import type { AuthRequest } from '../../middlewares/auth.middleware.js';
import { createSalonSchema } from './salon.schema.js';
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