import { z } from 'zod';

export const updateAppointmentStatusSchema = z.object({
    status: z.enum(['CONFIRMED', 'DECLINED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'])
});

export const checkAvailabilitySchema = z.object({
    salonId: z.number(),
    barberId: z.number().optional(),
    date: z.string().min(10),
    serviceIds: z.array(z.number()).min(1)
});

export const createAppointmentSchema = z.object({
    salonId: z.number(),
    barberId: z.number().optional(),
    targetType: z.enum(['EMPLOYEE', 'PATRON']).default('EMPLOYEE'),
    date: z.string().min(10),
    time: z.string().min(5),
    serviceIds: z.array(z.number()).min(1)
});
