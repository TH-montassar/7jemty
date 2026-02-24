import { Router } from 'express';
import { createSalonHandler } from './salon.controller.js';
import { protect, isPatron } from '../../middlewares/auth.middleware.js';

const router = Router();


router.post('/create', protect, isPatron, createSalonHandler);

export default router;