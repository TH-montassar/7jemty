import type { Request, Response } from 'express';
import { updateAppointmentStatus, getBarberAvailability, createClientAppointment } from './appointment.service.js';
import { updateAppointmentStatusSchema, checkAvailabilitySchema, createAppointmentSchema } from './appointment.schema.js';

interface AuthRequest extends Request {
    user?: {
        userId: number;
        role: string;
    };
}

export const updateStatus = async (req: AuthRequest, res: Response) => {
    try {
        const appointmentId = parseInt(req.params.id as string);
        if (isNaN(appointmentId)) {
            return res.status(400).json({ success: false, message: "ID l'rendez-vous ghalet" });
        }

        const parsedSchema = updateAppointmentStatusSchema.safeParse(req.body);
        if (!parsedSchema.success) {
            return res.status(400).json({ success: false, message: parsedSchema.error?.issues[0]?.message || 'Invalid data' });
        }

        const userId = req.user?.userId;
        const role = req.user?.role;

        if (!userId || !role) {
            return res.status(401).json({ success: false, message: "Non autorisé" });
        }

        const updatedAppointment = await updateAppointmentStatus(appointmentId, parsedSchema.data.status as any, userId, role);

        res.status(200).json({
            success: true,
            message: "Status tbadel b nja7!",
            data: updatedAppointment
        });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message || 'Famma mochkla fel rdv updates' });
    }
};
