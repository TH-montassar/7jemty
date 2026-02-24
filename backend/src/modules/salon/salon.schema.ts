import { z } from 'zod';

export const createSalonSchema = z.object({
    name: z.string().min(3, "Esem e-salon lezem fih 3 7rouf 3al a9al"),
    address: z.string().min(5, "L'adresse lezem tkon s7i7a w kemla"),
});

export const updateSalonSchema = z.object({
    description: z.string().optional(),
    contactPhone: z.string().optional(),
});