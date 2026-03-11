import { createEmployeeAccountAdmin, createPortfolioImageAdmin, createServiceAdmin, deletePortfolioImageAdmin, deleteSalonAdmin, deleteServiceAdmin, getAllSalonsAdmin, getSalonStatsAdmin, removeEmployeeFromSalonAdmin, updateEmployeeAccountAdmin, updateSalonAdmin, updateSalonStatusAdmin, updateServiceAdmin, } from './salon.service.js';
const parseId = (rawId, label) => {
    const id = Number.parseInt(rawId, 10);
    if (Number.isNaN(id)) {
        throw new Error(`${label} invalide`);
    }
    return id;
};
export const getAllSalonsAdminHandler = async (req, res) => {
    try {
        const salons = await getAllSalonsAdmin();
        res.status(200).json({ success: true, data: salons });
    }
    catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
export const updateSalonAdminHandler = async (req, res) => {
    try {
        const salonId = parseId(req.params.id, 'ID salon');
        const updatedSalon = await updateSalonAdmin(salonId, req.body);
        res.status(200).json({ success: true, data: updatedSalon });
    }
    catch (error) {
        const status = error.message?.includes('invalide') ? 400 : 500;
        res.status(status).json({ success: false, message: error.message });
    }
};
export const updateSalonStatusAdminHandler = async (req, res) => {
    try {
        const salonId = parseId(req.params.id, 'ID salon');
        const { status } = req.body;
        const updatedSalon = await updateSalonStatusAdmin(salonId, status);
        res.status(200).json({ success: true, data: updatedSalon });
    }
    catch (error) {
        const statusCode = error.message?.includes('invalide') ? 400 : 500;
        res.status(statusCode).json({ success: false, message: error.message });
    }
};
export const deleteSalonAdminHandler = async (req, res) => {
    try {
        const salonId = parseId(req.params.id, 'ID salon');
        await deleteSalonAdmin(salonId);
        res.status(200).json({ success: true, message: 'Salon deleted' });
    }
    catch (error) {
        const status = error.message?.includes('invalide') ? 400 : 500;
        res.status(status).json({ success: false, message: error.message });
    }
};
export const getSalonStatsAdminHandler = async (req, res) => {
    try {
        const salonId = parseId(req.params.id, 'ID salon');
        const stats = await getSalonStatsAdmin(salonId);
        res.status(200).json({ success: true, data: stats });
    }
    catch (error) {
        const status = error.message?.includes('invalide') ? 400 : 500;
        res.status(status).json({ success: false, message: error.message });
    }
};
export const createSalonServiceAdminHandler = async (req, res) => {
    try {
        const salonId = parseId(req.params.id, 'ID salon');
        const service = await createServiceAdmin(salonId, req.body);
        res.status(201).json({ success: true, data: service });
    }
    catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};
export const updateSalonServiceAdminHandler = async (req, res) => {
    try {
        const salonId = parseId(req.params.id, 'ID salon');
        const serviceId = parseId(req.params.serviceId, 'ID service');
        const service = await updateServiceAdmin(salonId, serviceId, req.body);
        res.status(200).json({ success: true, data: service });
    }
    catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};
export const deleteSalonServiceAdminHandler = async (req, res) => {
    try {
        const salonId = parseId(req.params.id, 'ID salon');
        const serviceId = parseId(req.params.serviceId, 'ID service');
        const result = await deleteServiceAdmin(salonId, serviceId);
        res.status(200).json({ success: true, data: result });
    }
    catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};
export const createSalonEmployeeAdminHandler = async (req, res) => {
    try {
        const salonId = parseId(req.params.id, 'ID salon');
        const employee = await createEmployeeAccountAdmin(salonId, req.body);
        res.status(201).json({ success: true, data: employee });
    }
    catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};
export const updateSalonEmployeeAdminHandler = async (req, res) => {
    try {
        const salonId = parseId(req.params.id, 'ID salon');
        const employeeId = parseId(req.params.employeeId, 'ID employe');
        const employee = await updateEmployeeAccountAdmin(salonId, employeeId, req.body);
        res.status(200).json({ success: true, data: employee });
    }
    catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};
export const deleteSalonEmployeeAdminHandler = async (req, res) => {
    try {
        const salonId = parseId(req.params.id, 'ID salon');
        const employeeId = parseId(req.params.employeeId, 'ID employe');
        const result = await removeEmployeeFromSalonAdmin(salonId, employeeId);
        res.status(200).json({ success: true, data: result });
    }
    catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};
export const addSalonPortfolioImageAdminHandler = async (req, res) => {
    try {
        const salonId = parseId(req.params.id, 'ID salon');
        const { imageUrl } = req.body;
        if (!imageUrl) {
            res.status(400).json({ success: false, message: 'L\'URL de l\'image est requise' });
            return;
        }
        const image = await createPortfolioImageAdmin(salonId, imageUrl);
        res.status(201).json({ success: true, data: image });
    }
    catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};
export const removeSalonPortfolioImageAdminHandler = async (req, res) => {
    try {
        const salonId = parseId(req.params.id, 'ID salon');
        const imageId = parseId(req.params.imageId, 'ID image');
        const image = await deletePortfolioImageAdmin(salonId, imageId);
        res.status(200).json({ success: true, data: image });
    }
    catch (error) {
        res.status(400).json({ success: false, message: error.message });
    }
};
//# sourceMappingURL=salon.admin.controller.js.map