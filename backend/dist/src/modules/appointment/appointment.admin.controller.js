import { getAppointmentsBySalonId } from './appointment.service.js';
export const getSalonAppointmentsAdminHandler = async (req, res) => {
    try {
        const salonId = Number.parseInt(req.params.id, 10);
        if (Number.isNaN(salonId)) {
            res.status(400).json({ success: false, message: 'ID de salon invalide' });
            return;
        }
        const appointments = await getAppointmentsBySalonId(salonId);
        res.status(200).json({ success: true, data: appointments });
    }
    catch (error) {
        res.status(500).json({ success: false, message: error.message || 'Erreur lors de la recuperation des rendez-vous admin' });
    }
};
//# sourceMappingURL=appointment.admin.controller.js.map