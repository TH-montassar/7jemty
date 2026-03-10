import { Router } from 'express';
import { register, login, getMe, updateProfile, checkPhone, requestOtp, verifyOtp } from './auth.controller.js';
import { protect } from '../../middlewares/auth.middleware.js';
const router = Router();
router.post('/register', register);
router.post('/login', login);
router.post('/check-phone', checkPhone);
router.post('/request-otp', requestOtp);
router.post('/verify-otp', verifyOtp);
router.get('/me', protect, getMe);
router.patch('/me', protect, updateProfile);
export default router;
//# sourceMappingURL=auth.routes.js.map