import { Router } from 'express';
import { getSalonAppointmentsAdminHandler } from './appointment.admin.controller.js';

const router = Router();

router.get('/salons/:id/appointments', getSalonAppointmentsAdminHandler);

export default router;
