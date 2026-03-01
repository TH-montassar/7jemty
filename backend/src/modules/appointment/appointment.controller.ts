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

        const updatedAppointment = await updateAppointmentStatus(appointmentId, parsedSchema.data.status as any, userId, role as any);

        res.status(200).json({
            success: true,
            message: "Status tbadel b nja7!",
            data: updatedAppointment
        });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message || 'Famma mochkla fel rdv updates' });
    }
};

export const getAvailability = async (req: AuthRequest, res: Response) => {
    try {
        const { salonId, barberId, date, serviceIds } = req.query;

        if (!salonId || !date) {
            return res.status(400).json({ success: false, message: "salonId w date homa nécessaires" });
        }

        const parsedSalonId = parseInt(salonId as string);
        const parsedBarberId = barberId ? parseInt(barberId as string) : undefined;
        const parsedServiceIds = typeof serviceIds === 'string' && serviceIds.length > 0
            ? serviceIds.split(',').map((id) => parseInt(id, 10)).filter((id) => !isNaN(id))
            : [];

        const availableSlots = await getBarberAvailability(parsedSalonId, date as string, parsedBarberId, parsedServiceIds);

        res.status(200).json({
            success: true,
            data: availableSlots
        });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message || "Famma mochkla fel availability" });
    }
};

export const createAppointment = async (req: AuthRequest, res: Response) => {
    try {
        const parsedSchema = createAppointmentSchema.safeParse(req.body);
        if (!parsedSchema.success) {
            return res.status(400).json({ success: false, message: parsedSchema.error?.issues[0]?.message || 'Invalid data' });
        }

        const userId = req.user?.userId;
        const role = req.user?.role;

        if (!userId || role !== 'CLIENT') {
            return res.status(401).json({ success: false, message: "Seul les clients tnajem taamel rdv jdida" });
        }

        const { salonId, barberId, targetType, date, time, serviceIds } = parsedSchema.data;

        const newAppointment = await createClientAppointment(
            userId,
            salonId,
            barberId,
            date,
            time,
            serviceIds,
            targetType
        );

        res.status(201).json({
            success: true,
            message: "Rendez-vous tasna3 b nja7!",
            data: newAppointment
        });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message || "Famma mochkla fel creation d'un rdv" });
    }
};

export const getSalonAppointmentsController = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user?.userId;
        const role = req.user?.role;

        if (!userId || role !== 'PATRON') {
            return res.status(401).json({ success: false, message: "Non autorisé" });
        }

        const { getSalonAppointments } = await import('./appointment.service.js');
        const appointments = await getSalonAppointments(userId);

        res.status(200).json({
            success: true,
            data: appointments
        });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message || "Erreur récupération des rdv" });
    }
};

export const getClientAppointmentsController = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user?.userId;
        const role = req.user?.role;

        if (!userId || role !== 'CLIENT') {
            return res.status(401).json({ success: false, message: "Non autorisé" });
        }

        const { getClientAppointments } = await import('./appointment.service.js');
        const appointments = await getClientAppointments(userId);

        res.status(200).json({
            success: true,
            data: appointments
        });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message || "Erreur récupération des rdv client" });
    }
};

export const getEmployeeAppointmentsController = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user?.userId;
        const role = req.user?.role;

        if (!userId || role !== 'EMPLOYEE') {
            return res.status(401).json({ success: false, message: "Non autorisé" });
        }

        const { getEmployeeAppointments } = await import('./appointment.service.js');
        const appointments = await getEmployeeAppointments(userId);

        res.status(200).json({
            success: true,
            data: appointments
        });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message || "Erreur récupération des rdv employé" });
    }
};
