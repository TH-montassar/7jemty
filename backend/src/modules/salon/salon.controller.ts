import type { Response, Request } from 'express';
import type { AuthRequest } from '../../middlewares/auth.middleware.js';
import {
    createSalonSchema,
    updateSalonSchema,
    createEmployeeAccountSchema,
    updateEmployeeAccountSchema,
    createServiceSchema,
    updateServiceSchema
} from './salon.schema.js';
import {
    createSalon, updateSalon, getSalonByPatronId,
    createEmployeeAccount, updateEmployeeAccount, removeEmployeeFromSalon, getAllSalons, createService,
    updateService, deleteService,
    getServices, getTopRatedSalons, getSalonById, searchSalons,
    toggleFavoriteSalon, getFavoriteSalons, checkFavoriteStatus
} from './salon.service.js';

export const createSalonHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        // 1. L'userId yjina mel Middleware (protect)
        const patronId = req.user!.userId;

        // 2. Nthabtou e-data b Zod
        const validatedData = createSalonSchema.parse(req.body);

        // 3. Nasn3ou e-salon
        const salon = await createSalon(patronId, validatedData);

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

        const updatedSalon = await updateSalon(patronId, validatedData);

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
        const salon = await getSalonByPatronId(patronId);

        res.status(200).json({ success: true, data: salon });
    } catch (error: any) {
        res.status(404).json({ success: false, message: error.message });
    }
};

export const createEmployeeAccountHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const patronId = req.user!.userId;
        const validatedData = createEmployeeAccountSchema.parse(req.body);

        const newEmployee = await createEmployeeAccount(patronId, validatedData);

        res.status(201).json({ success: true, data: newEmployee });
    } catch (error: any) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};

export const updateEmployeeAccountHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const patronId = req.user!.userId;
        const employeeId = parseInt(req.params.employeeId as string);

        if (isNaN(employeeId)) {
            res.status(400).json({ success: false, message: 'ID employe invalide' });
            return;
        }

        const validatedData = updateEmployeeAccountSchema.parse(req.body);
        const updatedEmployee = await updateEmployeeAccount(patronId, employeeId, validatedData);

        res.status(200).json({ success: true, data: updatedEmployee });
    } catch (error: any) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};

export const deleteEmployeeAccountHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const patronId = req.user!.userId;
        const employeeId = parseInt(req.params.employeeId as string);

        if (isNaN(employeeId)) {
            res.status(400).json({ success: false, message: 'ID employe invalide' });
            return;
        }

        const result = await removeEmployeeFromSalon(patronId, employeeId);
        res.status(200).json({ success: true, data: result });
    } catch (error: any) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};

export const getAllSalonsHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const lat = req.query.lat ? parseFloat(req.query.lat as string) : undefined;
        const lng = req.query.lng ? parseFloat(req.query.lng as string) : undefined;

        const salons = await getAllSalons(lat, lng);

        res.status(200).json({ success: true, data: salons });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const createServiceHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const patronId = req.user!.userId;
        const validatedData = createServiceSchema.parse(req.body);

        const newService = await createService(patronId, validatedData);

        res.status(201).json({ success: true, data: newService });
    } catch (error: any) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};

export const getServicesHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const patronId = req.user!.userId;

        const services = await getServices(patronId);

        res.status(200).json({ success: true, data: services });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const updateServiceHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const patronId = req.user!.userId;
        const serviceId = parseInt(req.params.serviceId as string);

        if (isNaN(serviceId)) {
            res.status(400).json({ success: false, message: 'ID service invalide' });
            return;
        }

        const validatedData = updateServiceSchema.parse(req.body);
        const updatedService = await updateService(patronId, serviceId, validatedData);

        res.status(200).json({ success: true, data: updatedService });
    } catch (error: any) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};

export const deleteServiceHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const patronId = req.user!.userId;
        const serviceId = parseInt(req.params.serviceId as string);

        if (isNaN(serviceId)) {
            res.status(400).json({ success: false, message: 'ID service invalide' });
            return;
        }

        const result = await deleteService(patronId, serviceId);
        res.status(200).json({ success: true, data: result });
    } catch (error: any) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};

export const getTopRatedSalonsHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const salons = await getTopRatedSalons();
        res.status(200).json({ success: true, data: salons });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const getSalonByIdHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const id = parseInt(req.params.id as string);
        if (isNaN(id)) {
            res.status(400).json({ success: false, message: 'ID invalide' });
            return;
        }

        const salon = await getSalonById(id);
        res.status(200).json({ success: true, data: salon });
    } catch (error: any) {
        res.status(404).json({ success: false, message: error.message });
    }
};

export const searchSalonHandler = async (req: Request, res: Response): Promise<void> => {
    try {
        const query = req.query.q as string;
        if (!query || query.trim() === '') {
            res.json({ success: true, data: [] });
            return;
        }
        const salons = await searchSalons(query.trim());
        res.json({ success: true, data: salons });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const toggleFavoriteSalonHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const clientId = req.user!.userId;
        const salonId = parseInt(req.params.id as string);

        if (isNaN(salonId)) {
            res.status(400).json({ success: false, message: 'ID invalide' });
            return;
        }

        const result = await toggleFavoriteSalon(clientId, salonId);
        res.status(200).json({ success: true, data: result });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const checkFavoriteStatusHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const clientId = req.user!.userId;
        const salonId = parseInt(req.params.id as string);

        if (isNaN(salonId)) {
            res.status(400).json({ success: false, message: 'ID invalide' });
            return;
        }

        const result = await checkFavoriteStatus(clientId, salonId);
        res.status(200).json({ success: true, data: result });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const getFavoriteSalonsHandler = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const clientId = req.user!.userId;
        const favorites = await getFavoriteSalons(clientId);

        res.status(200).json({ success: true, data: favorites });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
};
