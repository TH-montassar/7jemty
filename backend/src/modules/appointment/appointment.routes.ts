import { Router } from 'express';
import { updateStatus } from './appointment.controller.js';
import { protect } from '../../middlewares/auth.middleware.js';

const router = Router();

// Endpoint pour modifier le statut d'une réservation (Accepter, Refuser, Terminer, Annuler)
router.patch('/:id/status', protect, updateStatus);

export default router;
