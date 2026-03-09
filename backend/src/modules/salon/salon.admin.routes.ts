import { Router } from 'express';
import {
    addSalonPortfolioImageAdminHandler,
    createSalonEmployeeAdminHandler,
    createSalonServiceAdminHandler,
    deleteSalonAdminHandler,
    deleteSalonEmployeeAdminHandler,
    deleteSalonServiceAdminHandler,
    getAllSalonsAdminHandler,
    getSalonStatsAdminHandler,
    removeSalonPortfolioImageAdminHandler,
    updateSalonAdminHandler,
    updateSalonEmployeeAdminHandler,
    updateSalonServiceAdminHandler,
    updateSalonStatusAdminHandler,
} from './salon.admin.controller.js';

const router = Router();

router.get('/salons', getAllSalonsAdminHandler);
router.patch('/salons/:id', updateSalonAdminHandler);
router.patch('/salons/:id/status', updateSalonStatusAdminHandler);
router.delete('/salons/:id', deleteSalonAdminHandler);
router.get('/salons/:id/stats', getSalonStatsAdminHandler);

router.post('/salons/:id/service', createSalonServiceAdminHandler);
router.patch('/salons/:id/service/:serviceId', updateSalonServiceAdminHandler);
router.delete('/salons/:id/service/:serviceId', deleteSalonServiceAdminHandler);

router.post('/salons/:id/employee', createSalonEmployeeAdminHandler);
router.patch('/salons/:id/employee/:employeeId', updateSalonEmployeeAdminHandler);
router.delete('/salons/:id/employee/:employeeId', deleteSalonEmployeeAdminHandler);

router.post('/salons/:id/portfolio', addSalonPortfolioImageAdminHandler);
router.delete('/salons/:id/portfolio/:imageId', removeSalonPortfolioImageAdminHandler);

export default router;
