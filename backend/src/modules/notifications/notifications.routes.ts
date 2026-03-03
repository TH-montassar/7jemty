import { Router } from 'express';
import { protect } from '../../middlewares/auth.middleware.js';
import { getMyNotifications, markNotificationAsRead } from './notifications.controller.js';

const router = Router();

router.get('/', protect, getMyNotifications);
router.patch('/:id/read', protect, markNotificationAsRead);

export default router;
