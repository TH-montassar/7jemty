import { z } from 'zod';
export declare const createSalonSchema: z.ZodObject<{
    name: z.ZodString;
    address: z.ZodString;
    latitude: z.ZodOptional<z.ZodNumber>;
    longitude: z.ZodOptional<z.ZodNumber>;
    googleMapsUrl: z.ZodOptional<z.ZodString>;
    speciality: z.ZodOptional<z.ZodString>;
    workingHours: z.ZodOptional<z.ZodArray<z.ZodObject<{
        dayOfWeek: z.ZodNumber;
        openTime: z.ZodOptional<z.ZodNullable<z.ZodString>>;
        closeTime: z.ZodOptional<z.ZodNullable<z.ZodString>>;
        isDayOff: z.ZodDefault<z.ZodBoolean>;
    }, z.core.$strip>>>;
}, z.core.$strip>;
export declare const updateSalonSchema: z.ZodObject<{
    name: z.ZodOptional<z.ZodString>;
    description: z.ZodOptional<z.ZodString>;
    contactPhone: z.ZodOptional<z.ZodString>;
    address: z.ZodOptional<z.ZodString>;
    latitude: z.ZodOptional<z.ZodNumber>;
    longitude: z.ZodOptional<z.ZodNumber>;
    googleMapsUrl: z.ZodOptional<z.ZodString>;
    websiteUrl: z.ZodOptional<z.ZodString>;
    coverImageUrl: z.ZodOptional<z.ZodString>;
    speciality: z.ZodOptional<z.ZodString>;
    socialLinks: z.ZodOptional<z.ZodArray<z.ZodObject<{
        platform: z.ZodString;
        url: z.ZodString;
    }, z.core.$strip>>>;
    workingHours: z.ZodOptional<z.ZodArray<z.ZodObject<{
        dayOfWeek: z.ZodNumber;
        openTime: z.ZodOptional<z.ZodNullable<z.ZodString>>;
        closeTime: z.ZodOptional<z.ZodNullable<z.ZodString>>;
        isDayOff: z.ZodDefault<z.ZodBoolean>;
    }, z.core.$strip>>>;
}, z.core.$strip>;
export declare const createEmployeeAccountSchema: z.ZodObject<{
    salonId: z.ZodOptional<z.ZodNumber>;
    phoneNumber: z.ZodString;
    password: z.ZodString;
    name: z.ZodString;
    role: z.ZodOptional<z.ZodString>;
    bio: z.ZodOptional<z.ZodString>;
    description: z.ZodOptional<z.ZodString>;
    imageUrl: z.ZodOptional<z.ZodString>;
}, z.core.$strip>;
export declare const updateEmployeeAccountSchema: z.ZodObject<{
    name: z.ZodOptional<z.ZodString>;
    phoneNumber: z.ZodOptional<z.ZodString>;
    password: z.ZodOptional<z.ZodNullable<z.ZodString>>;
    role: z.ZodOptional<z.ZodNullable<z.ZodString>>;
    bio: z.ZodOptional<z.ZodNullable<z.ZodString>>;
    description: z.ZodOptional<z.ZodNullable<z.ZodString>>;
    imageUrl: z.ZodOptional<z.ZodNullable<z.ZodString>>;
}, z.core.$strip>;
export declare const createServiceSchema: z.ZodObject<{
    salonId: z.ZodOptional<z.ZodNumber>;
    name: z.ZodString;
    price: z.ZodNumber;
    durationMinutes: z.ZodNumber;
    description: z.ZodOptional<z.ZodString>;
    imageUrl: z.ZodOptional<z.ZodString>;
}, z.core.$strip>;
export declare const updateServiceSchema: z.ZodObject<{
    name: z.ZodOptional<z.ZodString>;
    price: z.ZodOptional<z.ZodNumber>;
    durationMinutes: z.ZodOptional<z.ZodNumber>;
    description: z.ZodOptional<z.ZodNullable<z.ZodString>>;
    imageUrl: z.ZodOptional<z.ZodNullable<z.ZodString>>;
}, z.core.$strip>;
//# sourceMappingURL=salon.schema.d.ts.map