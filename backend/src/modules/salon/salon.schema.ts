import { z } from 'zod';

export const createSalonSchema = z.object({
    name: z.string().min(3, "Esem e-salon lezem fih 3 7rouf 3al a9al"),
    address: z.string().min(5, "L'adresse lezem tkon s7i7a w kemla"),
    latitude: z.number().optional(),
    longitude: z.number().optional(),
    googleMapsUrl: z.string().optional(),
    speciality: z.string().optional(),
    workingHours: z.array(z.object({
        dayOfWeek: z.number().int().min(1).max(7),
        openTime: z.string().nullable().optional(),
        closeTime: z.string().nullable().optional(),
        isDayOff: z.boolean().default(false)
    })).optional(),
});

export const updateSalonSchema = z.object({
    name: z.string().min(3).optional(),
    description: z.string().optional(),
    contactPhone: z.string().optional(),
    address: z.string().optional(),
    latitude: z.number().optional(),
    longitude: z.number().optional(),
    googleMapsUrl: z.string().optional(),
    websiteUrl: z.string().optional(),
    coverImageUrl: z.string().optional(),
    speciality: z.string().optional(),
    socialLinks: z.array(z.object({
        platform: z.string(),
        url: z.string(),
    })).optional(),
    workingHours: z.array(z.object({
        dayOfWeek: z.number().int().min(1).max(7),
        openTime: z.string().nullable().optional(),
        closeTime: z.string().nullable().optional(),
        isDayOff: z.boolean().default(false)
    })).optional(),
});

export const createEmployeeAccountSchema = z.object({
    salonId: z.number().optional(),
    phoneNumber: z.string().min(8, "Numéro téléphone lazem 8 ar9am au minimum"),
    password: z.string().min(6, "Mot de passe lazem 6 7rouf au minimum"),
    name: z.string().min(2, "Nom lazem ykoun s7i7"),
    role: z.string().optional(),
    bio: z.string().optional(),
    description: z.string().optional(),
    imageUrl: z.string().optional(),
});

export const updateEmployeeAccountSchema = z.object({
    name: z.string().min(2, "Nom lazem ykoun s7i7").optional(),
    phoneNumber: z.string().min(8, "Numéro téléphone lazem 8 ar9am au minimum").optional(),
    password: z.string().min(6, "Mot de passe lazem 6 7rouf au minimum").nullable().optional(),
    role: z.string().nullable().optional(),
    bio: z.string().nullable().optional(),
    description: z.string().nullable().optional(),
    imageUrl: z.string().nullable().optional(),
});
export const createServiceSchema = z.object({
    salonId: z.number().optional(),
    name: z.string().min(2, "Le nom du service est requis"),
    price: z.number().positive("Le prix doit être positif"),
    durationMinutes: z.number().int().positive("La durée doit être valide (en minutes)"),
    description: z.string().optional(),
    imageUrl: z.string().optional(),
});

export const updateServiceSchema = z.object({
    name: z.string().min(2, "Le nom du service est requis").optional(),
    price: z.number().positive("Le prix doit être positif").optional(),
    durationMinutes: z.number().int().positive("La durée doit être valide (en minutes)").optional(),
    description: z.string().nullable().optional(),
    imageUrl: z.string().nullable().optional(),
});
