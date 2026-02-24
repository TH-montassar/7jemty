import { Router } from 'express';
import { createSalonHandler, updateSalonHandler, getMySalonHandler } from './salon.controller.js';
import { protect, isPatron } from '../../middlewares/auth.middleware.js';

const router = Router();


router.post('/create', protect, isPatron, createSalonHandler);
router.put('/update', protect, isPatron, updateSalonHandler);
router.get('/my-salon', protect, isPatron, getMySalonHandler);

export default router;