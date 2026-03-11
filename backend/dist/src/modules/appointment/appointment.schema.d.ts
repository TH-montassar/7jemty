import { z } from 'zod';
export declare const updateAppointmentStatusSchema: z.ZodObject<{
    status: z.ZodEnum<{
        CONFIRMED: "CONFIRMED";
        IN_PROGRESS: "IN_PROGRESS";
        COMPLETED: "COMPLETED";
        CANCELLED: "CANCELLED";
        DECLINED: "DECLINED";
    }>;
}, z.core.$strip>;
export declare const checkAvailabilitySchema: z.ZodObject<{
    salonId: z.ZodNumber;
    barberId: z.ZodOptional<z.ZodNumber>;
    date: z.ZodString;
    serviceIds: z.ZodArray<z.ZodNumber>;
}, z.core.$strip>;
export declare const createAppointmentSchema: z.ZodObject<{
    salonId: z.ZodNumber;
    barberId: z.ZodOptional<z.ZodNumber>;
    targetType: z.ZodDefault<z.ZodEnum<{
        EMPLOYEE: "EMPLOYEE";
        PATRON: "PATRON";
    }>>;
    date: z.ZodString;
    time: z.ZodString;
    serviceIds: z.ZodArray<z.ZodNumber>;
}, z.core.$strip>;
export declare const extendAppointmentSchema: z.ZodObject<{
    minutes: z.ZodNumber;
}, z.core.$strip>;
export declare const postponeNoShowSchema: z.ZodObject<{
    minutes: z.ZodDefault<z.ZodNumber>;
}, z.core.$strip>;
export declare const submitReviewSchema: z.ZodObject<{
    salonId: z.ZodNumber;
    rating: z.ZodNumber;
    comment: z.ZodOptional<z.ZodString>;
}, z.core.$strip>;
//# sourceMappingURL=appointment.schema.d.ts.map