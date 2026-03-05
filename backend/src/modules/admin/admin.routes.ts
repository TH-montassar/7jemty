import { Router } from 'express';
import { getAllUsersHandler, deleteUserHandler, getAllSalonsAdminHandler, updateSalonStatusHandler, deleteSalonHandler, updateUserHandler, updateSalonAdminHandler } from './admin.controller.js';
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

export default router;
