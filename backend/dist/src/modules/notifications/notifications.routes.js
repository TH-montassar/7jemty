import { Router } from 'express';
import { protect } from '../../middlewares/auth.middleware.js';
import { getMyNotifications, markNotificationAsRead, getUnreadCount, streamNotifications } from './notifications.controller.js';
const router = Router();
router.get('/', protect, getMyNotifications);
router.get('/unread-count', protect, getUnreadCount);
router.get('/stream', protect, streamNotifications);
router.patch('/:id/read', protect, markNotificationAsRead);
export default router;
//# sourceMappingURL=notifications.routes.js.map