import { Router } from 'express';
import { createSalonHandler, updateSalonHandler, getMySalonHandler, createEmployeeAccountHandler, getAllSalonsHandler, createServiceHandler, getServicesHandler } from './salon.controller.js';
import { protect, isPatron } from '../../middlewares/auth.middleware.js';

const router = Router();

router.get('/all', getAllSalonsHandler);
router.post('/create', protect, isPatron, createSalonHandler);
router.put('/update', protect, isPatron, updateSalonHandler);
router.get('/my-salon', protect, isPatron, getMySalonHandler);
router.post('/employee/create-account', protect, isPatron, createEmployeeAccountHandler);
router.post('/service/create', protect, isPatron, createServiceHandler);
router.get('/service/list', protect, isPatron, getServicesHandler);

export default router;