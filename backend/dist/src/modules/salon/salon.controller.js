import { createSalonSchema, updateSalonSchema, createEmployeeAccountSchema, updateEmployeeAccountSchema, createServiceSchema, updateServiceSchema } from './salon.schema.js';
import { createSalon, updateSalon, getSalonByPatronId, createEmployeeAccount, updateEmployeeAccount, removeEmployeeFromSalon, getAllSalons, createService, updateService, deleteService, getServices, getTopRatedSalons, getSalonById, searchSalons, toggleFavoriteSalon, getFavoriteSalons, checkFavoriteStatus, createPortfolioImage, deletePortfolioImage } from './salon.service.js';
export const createSalonHandler = async (req, res) => {
    try {
        // 1. L'userId yjina mel Middleware (protect)
        const patronId = req.user.userId;
        // 2. Nthabtou e-data b Zod
        const validatedData = createSalonSchema.parse(req.body);
        // 3. Nasn3ou e-salon
        const salon = await createSalon(patronId, validatedData);
        res.status(201).json({ success: true, data: salon });
    }
    catch (error) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};
export const updateSalonHandler = async (req, res) => {
    try {
        const patronId = req.user.userId;
        const validatedData = updateSalonSchema.parse(req.body);
        const updatedSalon = await updateSalon(patronId, validatedData);
        res.status(200).json({ success: true, data: updatedSalon });
    }
    catch (error) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};
export const getMySalonHandler = async (req, res) => {
    try {
        const patronId = req.user.userId;
        // Njibou l'salon tebe3 e-patron hedha
        const salon = await getSalonByPatronId(patronId);
        res.status(200).json({ success: true, data: salon });
    }
    catch (error) {
        res.status(404).json({ success: false, message: error.message });
    }
};
export const createEmployeeAccountHandler = async (req, res) => {
    try {
        const patronId = req.user.userId;
        const validatedData = createEmployeeAccountSchema.parse(req.body);
        const newEmployee = await createEmployeeAccount(patronId, validatedData);
        res.status(201).json({ success: true, data: newEmployee });
    }
    catch (error) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};
export const updateEmployeeAccountHandler = async (req, res) => {
    try {
        const patronId = req.user.userId;
        const employeeId = parseInt(req.params.employeeId);
        if (isNaN(employeeId)) {
            res.status(400).json({ success: false, message: 'ID employe invalide' });
            return;
        }
        const validatedData = updateEmployeeAccountSchema.parse(req.body);
        const updatedEmployee = await updateEmployeeAccount(patronId, employeeId, validatedData);
        res.status(200).json({ success: true, data: updatedEmployee });
    }
    catch (error) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};
export const deleteEmployeeAccountHandler = async (req, res) => {
    try {
        const patronId = req.user.userId;
        const employeeId = parseInt(req.params.employeeId);
        if (isNaN(employeeId)) {
            res.status(400).json({ success: false, message: 'ID employe invalide' });
            return;
        }
        const result = await removeEmployeeFromSalon(patronId, employeeId);
        res.status(200).json({ success: true, data: result });
    }
    catch (error) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};
export const getAllSalonsHandler = async (req, res) => {
    try {
        const lat = req.query.lat !== undefined ? parseFloat(req.query.lat) : undefined;
        const lng = req.query.lng !== undefined ? parseFloat(req.query.lng) : undefined;
        const salons = await getAllSalons(lat, lng);
        res.status(200).json({ success: true, data: salons });
    }
    catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
export const createServiceHandler = async (req, res) => {
    try {
        const patronId = req.user.userId;
        const validatedData = createServiceSchema.parse(req.body);
        const newService = await createService(patronId, validatedData);
        res.status(201).json({ success: true, data: newService });
    }
    catch (error) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};
export const getServicesHandler = async (req, res) => {
    try {
        const patronId = req.user.userId;
        const services = await getServices(patronId);
        res.status(200).json({ success: true, data: services });
    }
    catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
export const updateServiceHandler = async (req, res) => {
    try {
        const patronId = req.user.userId;
        const serviceId = parseInt(req.params.serviceId);
        if (isNaN(serviceId)) {
            res.status(400).json({ success: false, message: 'ID service invalide' });
            return;
        }
        const validatedData = updateServiceSchema.parse(req.body);
        const updatedService = await updateService(patronId, serviceId, validatedData);
        res.status(200).json({ success: true, data: updatedService });
    }
    catch (error) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};
export const deleteServiceHandler = async (req, res) => {
    try {
        const patronId = req.user.userId;
        const serviceId = parseInt(req.params.serviceId);
        if (isNaN(serviceId)) {
            res.status(400).json({ success: false, message: 'ID service invalide' });
            return;
        }
        const result = await deleteService(patronId, serviceId);
        res.status(200).json({ success: true, data: result });
    }
    catch (error) {
        const message = error.errors ? error.errors[0].message : error.message;
        res.status(400).json({ success: false, message });
    }
};
export const getTopRatedSalonsHandler = async (req, res) => {
    try {
        const salons = await getTopRatedSalons();
        res.status(200).json({ success: true, data: salons });
    }
    catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
export const getSalonByIdHandler = async (req, res) => {
    try {
        const id = parseInt(req.params.id);
        const lat = req.query.lat !== undefined ? parseFloat(req.query.lat) : undefined;
        const lng = req.query.lng !== undefined ? parseFloat(req.query.lng) : undefined;
        if (isNaN(id)) {
            res.status(400).json({ success: false, message: 'ID invalide' });
            return;
        }
        const salon = await getSalonById(id, lat, lng);
        res.status(200).json({ success: true, data: salon });
    }
    catch (error) {
        res.status(404).json({ success: false, message: error.message });
    }
};
export const searchSalonHandler = async (req, res) => {
    try {
        const query = req.query.q;
        const lat = req.query.lat !== undefined ? parseFloat(req.query.lat) : undefined;
        const lng = req.query.lng !== undefined ? parseFloat(req.query.lng) : undefined;
        if (!query || query.trim() === '') {
            res.json({ success: true, data: [] });
            return;
        }
        const salons = await searchSalons(query.trim(), lat, lng);
        res.json({ success: true, data: salons });
    }
    catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
export const toggleFavoriteSalonHandler = async (req, res) => {
    try {
        const clientId = req.user.userId;
        const salonId = parseInt(req.params.id);
        if (isNaN(salonId)) {
            res.status(400).json({ success: false, message: 'ID invalide' });
            return;
        }
        const result = await toggleFavoriteSalon(clientId, salonId);
        res.status(200).json({ success: true, data: result });
    }
    catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
export const checkFavoriteStatusHandler = async (req, res) => {
    try {
        const clientId = req.user.userId;
        const salonIdStr = req.params.id;
        if (!salonIdStr) {
            res.status(400).json({ success: false, message: 'ID salon manquant dans l\'URL' });
            return;
        }
        const salonId = parseInt(salonIdStr);
        if (isNaN(salonId)) {
            res.status(400).json({ success: false, message: 'ID salon invalide' });
            return;
        }
        const isFavorite = await checkFavoriteStatus(clientId, salonId);
        res.status(200).json({ success: true, isFavorite });
    }
    catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
export const addPortfolioImageHandler = async (req, res) => {
    try {
        const patronId = req.user.userId;
        const { imageUrl } = req.body;
        if (!imageUrl) {
            res.status(400).json({ success: false, message: 'L\'URL de l\'image est requise' });
            return;
        }
        const newImage = await createPortfolioImage(patronId, imageUrl);
        res.status(201).json({ success: true, data: newImage });
    }
    catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};
export const removePortfolioImageHandler = async (req, res) => {
    try {
        const patronId = req.user.userId;
        const imageId = parseInt(req.params.imageId);
        if (isNaN(imageId)) {
            res.status(400).json({ success: false, message: 'ID d\'image invalide' });
            return;
        }
        const deletedImage = await deletePortfolioImage(patronId, imageId);
        res.status(200).json({ success: true, data: deletedImage });
    }
    catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};
export const getFavoriteSalonsHandler = async (req, res) => {
    try {
        const clientId = req.user.userId;
        const favorites = await getFavoriteSalons(clientId);
        res.status(200).json({ success: true, data: favorites });
    }
    catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
//# sourceMappingURL=salon.controller.js.map