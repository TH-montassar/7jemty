import { Router } from 'express';
import { updateStatus, getAvailability, getAvailableDatesController, createAppointment, getSalonAppointmentsController, getClientAppointmentsController, getEmployeeAppointmentsController, extendAppointmentController, postponeNoShowController, getUnreviewedAppointmentsController, submitReviewController } from './appointment.controller.js';
import { protect } from '../../middlewares/auth.middleware.js';
const router = Router();
// Endpoint pour modifier le statut d'une réservation (Accepter, Refuser, Terminer, Annuler)
router.patch('/:id/status', protect, updateStatus);
// Endpoint pour étendre la durée d'un rendez-vous en cours
router.patch('/:id/extend', protect, extendAppointmentController);
// Endpoint no-show: decaler le rendez-vous de X minutes + cascade sur le meme specialist
router.patch('/:id/no-show-postpone', protect, postponeNoShowController);
// Endpoint pour soumettre un avis
router.post('/:id/review', protect, submitReviewController);
// Endpoint pour vérifier les disponibilités
router.get('/availability', getAvailability);
// Endpoint pour vérifier les jours disponibles sur une plage de dates
router.get('/available-dates', getAvailableDatesController);
// Endpoint pour récupérer les rendez-vous non évalués du client
router.get('/unreviewed', protect, getUnreviewedAppointmentsController);
// Endpoint pour créer une réservation côté client
router.post('/', protect, createAppointment);
// Endpoint pour récupérer les rendez-vous du salon (pour le patron)
router.get('/salon', protect, getSalonAppointmentsController);
// Endpoint pour récupérer les rendez-vous du client
router.get('/client', protect, getClientAppointmentsController);
// Endpoint pour récupérer les rendez-vous de l'employé
router.get('/employee', protect, getEmployeeAppointmentsController);
export default router;
//# sourceMappingURL=appointment.routes.js.map