import { z } from 'zod';

export const updateAppointmentStatusSchema = z.object({
    status: z.enum(['CONFIRMED', 'DECLINED', 'COMPLETED', 'CANCELLED'], {
        message: "Status invalide"
    })
});
