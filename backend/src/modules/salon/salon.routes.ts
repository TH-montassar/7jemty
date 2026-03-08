import { Router } from 'express';
import { createSalonHandler, updateSalonHandler, getMySalonHandler, createEmployeeAccountHandler, getAllSalonsHandler, getTopRatedSalonsHandler, getSalonByIdHandler, createServiceHandler, getServicesHandler, searchSalonHandler, toggleFavoriteSalonHandler, getFavoriteSalonsHandler, checkFavoriteStatusHandler } from './salon.controller.js';
import { protect, isPatron } from '../../middlewares/auth.middleware.js';

const router = Router();

router.get('/top-rated', getTopRatedSalonsHandler);
router.get('/all', getAllSalonsHandler);
router.post('/create', protect, isPatron, createSalonHandler);
router.put('/update', protect, isPatron, updateSalonHandler);
router.get('/my-salon', protect, isPatron, getMySalonHandler);
router.post('/employee/create-account', protect, isPatron, createEmployeeAccountHandler);
router.post('/service/create', protect, isPatron, createServiceHandler);
router.get('/services', protect, isPatron, getServicesHandler);
router.get('/search', searchSalonHandler);
router.get('/favorites/all', protect, getFavoriteSalonsHandler);
router.get('/:id', getSalonByIdHandler);
router.post('/:id/favorite', protect, toggleFavoriteSalonHandler);
router.get('/:id/favorite-status', protect, checkFavoriteStatusHandler);

export default router;