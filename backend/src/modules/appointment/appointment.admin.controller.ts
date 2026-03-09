import type { Response } from 'express';
import type { AuthRequest } from '../../middlewares/auth.middleware.js';
import { getAppointmentsBySalonId } from './appointment.service.js';

export const getSalonAppointmentsAdminHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const salonId = Number.parseInt(req.params.id as string, 10);
        if (Number.isNaN(salonId)) {
            res.status(400).json({ success: false, message: 'ID de salon invalide' });
            return;
        }

        const appointments = await getAppointmentsBySalonId(salonId);
        res.status(200).json({ success: true, data: appointments });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message || 'Erreur lors de la recuperation des rendez-vous admin' });
    }
};
