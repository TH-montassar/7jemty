import { z } from 'zod';

export const createSalonSchema = z.object({
    name: z.string().min(3, "Esem e-salon lezem fih 3 7rouf 3al a9al"),
    address: z.string().min(5, "L'adresse lezem tkon s7i7a w kemla"),
    latitude: z.number().optional(),
    longitude: z.number().optional(),
    googleMapsUrl: z.string().optional(),
    speciality: z.string().optional(),
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
});

export const createServiceSchema = z.object({
    name: z.string().min(2, "Nom du service est requis"),
    description: z.string().optional(),
    price: z.number().min(0, "Le prix doit être positif"),
    durationMinutes: z.number().min(1, "La durée doit être d'au moins 1 minute"),
    imageUrl: z.string().optional(),
});

export const createEmployeeAccountSchema = z.object({
    phoneNumber: z.string().min(8, "Numéro de téléphone invalide"),
    password: z.string().min(6, "Mot de passe yelzmou 6 caractéres au moins"),
    name: z.string().min(2, "Nom invalide"),
    role: z.string().optional(),
    bio: z.string().optional(),
    description: z.string().optional(),
    imageUrl: z.string().optional(),
});