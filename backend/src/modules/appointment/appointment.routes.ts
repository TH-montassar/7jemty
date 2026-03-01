import { Router } from 'express';
import { updateStatus, getAvailability, createAppointment, getSalonAppointmentsController, getClientAppointmentsController, getEmployeeAppointmentsController } from './appointment.controller.js';
import { protect } from '../../middlewares/auth.middleware.js';

const router = Router();

// Endpoint pour modifier le statut d'une réservation (Accepter, Refuser, Terminer, Annuler)
router.patch('/:id/status', protect, updateStatus);

// Endpoint pour vérifier les disponibilités
router.get('/availability', protect, getAvailability);

// Endpoint pour créer une réservation côté client
router.post('/', protect, createAppointment);

// Endpoint pour récupérer les rendez-vous du salon (pour le patron)
router.get('/salon', protect, getSalonAppointmentsController);

// Endpoint pour récupérer les rendez-vous du client
router.get('/client', protect, getClientAppointmentsController);

// Endpoint pour récupérer les rendez-vous de l'employé
router.get('/employee', protect, getEmployeeAppointmentsController);

export default router;
