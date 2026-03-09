import { Router } from 'express';
import {
    getAllUsersHandler, deleteUserHandler, updateUserHandler,
    getAllSalonsAdminHandler, updateSalonStatusHandler, updateSalonAdminHandler, deleteSalonHandler,
    getSalonStatsHandler, getSalonAppointmentsAdminHandler,
    createSalonServiceHandler, updateSalonServiceHandler, deleteSalonServiceHandler,
    createSalonEmployeeHandler, updateSalonEmployeeHandler, deleteSalonEmployeeHandler,
    addSalonPortfolioImageHandler, removeSalonPortfolioImageHandler
} from './admin.controller.js';
import { protect, isAdmin } from '../../middlewares/auth.middleware.js';

const router = Router();

router.use(protect, isAdmin);

router.get('/users', getAllUsersHandler);
router.patch('/users/:id', updateUserHandler);
router.delete('/users/:id', deleteUserHandler);

router.get('/salons', getAllSalonsAdminHandler);
router.patch('/salons/:id', updateSalonAdminHandler);
router.patch('/salons/:id/status', updateSalonStatusHandler);
router.delete('/salons/:id', deleteSalonHandler);
router.get('/salons/:id/stats', getSalonStatsHandler);
router.get('/salons/:id/appointments', getSalonAppointmentsAdminHandler);

// Admin Routes for managing Services
router.post('/salons/:id/service', createSalonServiceHandler);
router.patch('/salons/:id/service/:serviceId', updateSalonServiceHandler);
router.delete('/salons/:id/service/:serviceId', deleteSalonServiceHandler);

// Admin Routes for managing Employees (Specialists)
router.post('/salons/:id/employee', createSalonEmployeeHandler);
router.patch('/salons/:id/employee/:employeeId', updateSalonEmployeeHandler);
router.delete('/salons/:id/employee/:employeeId', deleteSalonEmployeeHandler);
// Admin Routes for managing Portfolio
router.post('/salons/:id/portfolio', addSalonPortfolioImageHandler);
router.delete('/salons/:id/portfolio/:imageId', removeSalonPortfolioImageHandler);

export default router;
