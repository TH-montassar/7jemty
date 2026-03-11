import { z } from 'zod';
export declare const registerSchema: z.ZodObject<{
    fullName: z.ZodString;
    phoneNumber: z.ZodString;
    password: z.ZodString;
    role: z.ZodDefault<z.ZodOptional<z.ZodEnum<{
        CLIENT: "CLIENT";
        PATRON: "PATRON";
        EMPLOYEE: "EMPLOYEE";
        ADMIN: "ADMIN";
    }>>>;
    address: z.ZodOptional<z.ZodString>;
    latitude: z.ZodOptional<z.ZodNumber>;
    longitude: z.ZodOptional<z.ZodNumber>;
}, z.core.$strip>;
export declare const loginSchema: z.ZodObject<{
    phoneNumber: z.ZodString;
    password: z.ZodString;
}, z.core.$strip>;
export declare const requestOtpSchema: z.ZodObject<{
    phoneNumber: z.ZodString;
}, z.core.$strip>;
export declare const verifyOtpSchema: z.ZodObject<{
    phoneNumber: z.ZodString;
    code: z.ZodString;
}, z.core.$strip>;
//# sourceMappingURL=auth.schema.d.ts.map