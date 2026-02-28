import { z } from 'zod';

export const updateAppointmentStatusSchema = z.object({
    status: z.enum(['CONFIRMED', 'DECLINED', 'COMPLETED', 'CANCELLED'])
});

export const checkAvailabilitySchema = z.object({
    salonId: z.number(),
    barberId: z.number().optional(),
    date: z.string().min(10), // YYYY-MM-DD
    serviceIds: z.array(z.number()).min(1)
});

export const createAppointmentSchema = z.object({
    salonId: z.number(),
    barberId: z.number(),
    date: z.string().min(10), // YYYY-MM-DD
    time: z.string().min(5), // HH:mm
    serviceIds: z.array(z.number()).min(1)
});
