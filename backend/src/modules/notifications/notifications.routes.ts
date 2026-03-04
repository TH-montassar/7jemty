import { Router } from 'express';
import { protect } from '../../middlewares/auth.middleware.js';
import { getMyNotifications, markNotificationAsRead, getUnreadCount } from './notifications.controller.js';

const router = Router();

router.get('/', protect, getMyNotifications);
router.get('/unread-count', protect, getUnreadCount);
router.patch('/:id/read', protect, markNotificationAsRead);

export default router;
