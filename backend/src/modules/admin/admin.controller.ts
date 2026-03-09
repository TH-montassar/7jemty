import type { Response } from 'express';
import type { AuthRequest } from '../../middlewares/auth.middleware.js';
import { getAllUsers, deleteUser, getAllSalonsAdmin, updateSalonStatus, deleteSalon, updateUser, updateSalonAdmin, getSalonStatsAdmin } from './admin.service.js';

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

export const getSalonStatsHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const id = parseInt(req.params.id as string);
        const stats = await getSalonStatsAdmin(id);
        res.status(200).json({ success: true, data: stats });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const getSalonAppointmentsAdminHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const id = parseInt(req.params.id as string);
        if (isNaN(id)) {
            res.status(400).json({ success: false, message: "ID de salon invalide" });
            return;
        }

        const { getAppointmentsBySalonId } = await import('../appointment/appointment.service.js');
        const appointments = await getAppointmentsBySalonId(id);

        res.status(200).json({
            success: true,
            data: appointments
        });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message || "Erreur lors de la récupération des rendez-vous par l'admin" });
    }
};

export const createSalonServiceHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const salonId = parseInt(req.params.id as string);
        if (isNaN(salonId)) {
            res.status(400).json({ success: false, message: "ID de salon invalide" });
            return;
        }

        const { createServiceAdmin } = await import('../salon/salon.service.js');
        const newService = await createServiceAdmin(salonId, req.body);

        res.status(201).json({ success: true, data: newService });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};

export const updateSalonServiceHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const salonId = parseInt(req.params.id as string);
        const serviceId = parseInt(req.params.serviceId as string);

        if (isNaN(salonId) || isNaN(serviceId)) {
            res.status(400).json({ success: false, message: "ID invalide" });
            return;
        }

        const { updateServiceAdmin } = await import('../salon/salon.service.js');
        const updatedService = await updateServiceAdmin(salonId, serviceId, req.body);

        res.status(200).json({ success: true, data: updatedService });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};

export const deleteSalonServiceHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const salonId = parseInt(req.params.id as string);
        const serviceId = parseInt(req.params.serviceId as string);

        if (isNaN(salonId) || isNaN(serviceId)) {
            res.status(400).json({ success: false, message: "ID invalide" });
            return;
        }

        const { deleteServiceAdmin } = await import('../salon/salon.service.js');
        const result = await deleteServiceAdmin(salonId, serviceId);

        res.status(200).json({ success: true, data: result });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};

export const createSalonEmployeeHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const salonId = parseInt(req.params.id as string);
        if (isNaN(salonId)) {
            res.status(400).json({ success: false, message: "ID de salon invalide" });
            return;
        }

        const { createEmployeeAccountAdmin } = await import('../salon/salon.service.js');
        const newEmployee = await createEmployeeAccountAdmin(salonId, req.body);

        res.status(201).json({ success: true, data: newEmployee });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};

export const updateSalonEmployeeHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const salonId = parseInt(req.params.id as string);
        const employeeId = parseInt(req.params.employeeId as string);

        if (isNaN(salonId) || isNaN(employeeId)) {
            res.status(400).json({ success: false, message: "ID invalide" });
            return;
        }

        const { updateEmployeeAccountAdmin } = await import('../salon/salon.service.js');
        const updatedEmployee = await updateEmployeeAccountAdmin(salonId, employeeId, req.body);

        res.status(200).json({ success: true, data: updatedEmployee });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};

export const deleteSalonEmployeeHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const salonId = parseInt(req.params.id as string);
        const employeeId = parseInt(req.params.employeeId as string);

        if (isNaN(salonId) || isNaN(employeeId)) {
            res.status(400).json({ success: false, message: "ID invalide" });
            return;
        }

        const { removeEmployeeFromSalonAdmin } = await import('../salon/salon.service.js');
        const result = await removeEmployeeFromSalonAdmin(salonId, employeeId);

        res.status(200).json({ success: true, data: result });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};
