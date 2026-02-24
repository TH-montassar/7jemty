import { Router } from 'express';
import { createSalonHandler, updateSalonHandler, getMySalonHandler, createEmployeeAccountHandler } from './salon.controller.js';
import { protect, isPatron } from '../../middlewares/auth.middleware.js';

const router = Router();


router.post('/create', protect, isPatron, createSalonHandler);
router.put('/update', protect, isPatron, updateSalonHandler);
router.get('/my-salon', protect, isPatron, getMySalonHandler);
router.post('/employee/create-account', protect, isPatron, createEmployeeAccountHandler);

export default router;