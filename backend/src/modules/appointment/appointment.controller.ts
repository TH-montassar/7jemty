import type { Request, Response } from 'express';
import { updateAppointmentStatus, getBarberAvailability, createClientAppointment } from './appointment.service.js';
import { updateAppointmentStatusSchema, checkAvailabilitySchema, createAppointmentSchema } from './appointment.schema.js';

interface AuthRequest extends Request {
    user?: {
        userId: number;
        role: string;
    };
}

import jwt from 'jsonwebtoken';
import { env } from '../../config/env.js';

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

        let userId: number | undefined;
        const authHeader = req.headers.authorization;
        if (authHeader && authHeader.startsWith('Bearer ')) {
            const token = authHeader.split(' ')[1];
            if (token) {
                try {
                    const decoded = jwt.verify(token, env.JWT_SECRET) as { userId: number; role: string };
                    userId = decoded.userId;
                } catch {
                    // Ignore invalid tokens for availability checks
                }
            }
        }

        const parsedSalonId = parseInt(salonId as string);
        const parsedBarberId = barberId ? parseInt(barberId as string) : undefined;
        const parsedServiceIds = typeof serviceIds === 'string' && serviceIds.length > 0
            ? serviceIds.split(',').map((id) => parseInt(id, 10)).filter((id) => !isNaN(id))
            : [];

        const availableSlots = await getBarberAvailability(parsedSalonId, date as string, parsedBarberId, parsedServiceIds, userId);

        res.status(200).json({
            success: true,
            data: availableSlots
        });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message || "Famma mochkla fel availability" });
    }
};

export const getAvailableDatesController = async (req: AuthRequest, res: Response) => {
    try {
        const { salonId, barberId, serviceIds, startDate, endDate } = req.query;

        if (!salonId || !startDate || !endDate) {
            return res.status(400).json({ success: false, message: "salonId, startDate w endDate homa nécessaires" });
        }

        let userId: number | undefined;
        const authHeader = req.headers.authorization;
        if (authHeader && authHeader.startsWith('Bearer ')) {
            const token = authHeader.split(' ')[1];
            if (token) {
                try {
                    const decoded = jwt.verify(token, env.JWT_SECRET) as { userId: number; role: string };
                    userId = decoded.userId;
                } catch {
                    // Ignore invalid tokens for availability checks
                }
            }
        }

        const parsedSalonId = parseInt(salonId as string);
        const parsedBarberId = barberId ? parseInt(barberId as string) : undefined;
        const parsedServiceIds = typeof serviceIds === 'string' && serviceIds.length > 0
            ? serviceIds.split(',').map((id) => parseInt(id, 10)).filter((id) => !isNaN(id))
            : [];

        const { getAvailableDatesForRange } = await import('./appointment.service.js');
        const availableDates = await getAvailableDatesForRange(
            parsedSalonId,
            startDate as string,
            endDate as string,
            parsedBarberId,
            parsedServiceIds,
            userId
        );

        res.status(200).json({
            success: true,
            data: availableDates
        });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message || "Famma mochkla fel available-dates" });
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

export const extendAppointmentController = async (req: AuthRequest, res: Response) => {
    try {
        const appointmentId = parseInt(req.params.id as string);
        if (isNaN(appointmentId)) {
            return res.status(400).json({ success: false, message: "ID l'rendez-vous ghalet" });
        }

        const { extendAppointmentSchema } = await import('./appointment.schema.js');
        const parsedSchema = extendAppointmentSchema.safeParse(req.body);
        if (!parsedSchema.success) {
            return res.status(400).json({ success: false, message: parsedSchema.error?.issues[0]?.message || 'Invalid data' });
        }

        const userId = req.user?.userId;
        const role = req.user?.role;

        if (!userId || !role || (role !== 'EMPLOYEE' && role !== 'PATRON')) {
            return res.status(401).json({ success: false, message: "Non autorisé" });
        }

        const { extendAppointment } = await import('./appointment.service.js');
        const updatedAppointment = await extendAppointment(appointmentId, parsedSchema.data.minutes, userId, role as 'PATRON' | 'EMPLOYEE');

        res.status(200).json({
            success: true,
            message: "Wa9t tzad b nja7!",
            data: updatedAppointment
        });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message || "Famma mochkla fel tzidyin lwa9t" });
    }
};

export const postponeNoShowController = async (req: AuthRequest, res: Response) => {
    try {
        const appointmentId = parseInt(req.params.id as string);
        if (isNaN(appointmentId)) {
            return res.status(400).json({ success: false, message: "ID l'rendez-vous ghalet" });
        }

        const { postponeNoShowSchema } = await import('./appointment.schema.js');
        const parsedSchema = postponeNoShowSchema.safeParse(req.body ?? {});
        if (!parsedSchema.success) {
            return res.status(400).json({ success: false, message: parsedSchema.error?.issues[0]?.message || 'Invalid data' });
        }

        const userId = req.user?.userId;
        const role = req.user?.role;

        if (!userId || !role || (role !== 'EMPLOYEE' && role !== 'PATRON')) {
            return res.status(401).json({ success: false, message: "Non autorise" });
        }

        const { postponeNoShowWithCascade } = await import('./appointment.service.js');
        const result = await postponeNoShowWithCascade(
            appointmentId,
            parsedSchema.data.minutes,
            userId,
            role as 'PATRON' | 'EMPLOYEE'
        );

        res.status(200).json({
            success: true,
            message: "Rendez-vous decale b nja7!",
            data: result
        });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message || "Famma mochkla fel report de rendez-vous" });
    }
};

export const getUnreviewedAppointmentsController = async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user?.userId;
        const role = req.user?.role;

        if (!userId || role !== 'CLIENT') {
            return res.status(401).json({ success: false, message: "Non autorisé, client kahaw" });
        }

        const { getUnreviewedAppointments } = await import('./appointment.service.js');
        const appointments = await getUnreviewedAppointments(userId);

        res.status(200).json({
            success: true,
            data: appointments
        });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message || "Erreur récupération des rdv sans avis" });
    }
};

export const submitReviewController = async (req: AuthRequest, res: Response) => {
    try {
        const appointmentId = parseInt(req.params.id as string);
        if (isNaN(appointmentId)) {
            return res.status(400).json({ success: false, message: "ID l'rendez-vous ghalet" });
        }

        const { submitReviewSchema } = await import('./appointment.schema.js');
        const parsedSchema = submitReviewSchema.safeParse(req.body);
        if (!parsedSchema.success) {
            return res.status(400).json({ success: false, message: parsedSchema.error?.issues[0]?.message || 'Invalid data' });
        }

        const userId = req.user?.userId;
        const role = req.user?.role;

        if (!userId || role !== 'CLIENT') {
            return res.status(401).json({ success: false, message: "Non autorisé, client kahaw tnajjem t9ayem" });
        }

        const { submitReview } = await import('./appointment.service.js');
        const review = await submitReview(
            appointmentId,
            userId,
            parsedSchema.data.salonId,
            parsedSchema.data.rating,
            parsedSchema.data.comment
        );

        res.status(201).json({
            success: true,
            message: "Avis mte3ek tbaath, y3aychek!",
            data: review
        });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message || "Famma mochkla fel envoyer avis" });
    }
};
