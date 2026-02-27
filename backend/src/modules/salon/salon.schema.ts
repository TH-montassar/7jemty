import { z } from 'zod';

export const createSalonSchema = z.object({
    name: z.string().min(3, "Esem e-salon lezem fih 3 7rouf 3al a9al"),
    address: z.string().min(5, "L'adresse lezem tkon s7i7a w kemla"),
    latitude: z.number().optional(),
    longitude: z.number().optional(),
});

export const updateSalonSchema = z.object({
    description: z.string().optional(),
    contactPhone: z.string().optional(),
    address: z.string().min(5, "L'adresse lezem tkon s7i7a w kemla").optional(),
    latitude: z.number().optional(),
    longitude: z.number().optional(),
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

export const createServiceSchema = z.object({
    name: z.string().min(2, "Esem e-service lezem fih 2 7rouf 3al a9al"),
    price: z.number().positive("Prix lezem yakoun positif"),
    durationMinutes: z.number().int().positive("La durée lezem takoun positive"),
    description: z.string().optional(),
    imageUrl: z.string().url("URL mech s7i7a").optional().or(z.literal('')),
});