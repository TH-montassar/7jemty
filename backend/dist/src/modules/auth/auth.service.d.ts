import { Role } from '../../../generated/prisma/index.js';
export declare const registerUser: (data: any) => Promise<{
    user: {
        profile: {
            id: number;
            userId: number;
            createdAt: Date;
            email: string | null;
            avatarUrl: string | null;
            bio: string | null;
            description: string | null;
            specialityTitle: string | null;
            fcmToken: string | null;
            pushNotificationsEnabled: boolean;
            darkModeEnabled: boolean;
            address: string | null;
            latitude: number | null;
            longitude: number | null;
        } | null;
        role: import("../../../generated/prisma/index.js").$Enums.Role;
        id: number;
        createdAt: Date;
        fullName: string;
        phoneNumber: string;
        isVerified: boolean;
        workplaceSalonId: number | null;
        ignoredAppointmentsCount: number;
        blacklistedAt: Date | null;
        isBlacklistedBySystem: boolean;
    };
    token: string;
}>;
export declare const loginUser: (data: any) => Promise<{
    user: {
        hasSalon: boolean;
        role: import("../../../generated/prisma/index.js").$Enums.Role;
        id: number;
        createdAt: Date;
        fullName: string;
        phoneNumber: string;
        isVerified: boolean;
        workplaceSalonId: number | null;
        ignoredAppointmentsCount: number;
        blacklistedAt: Date | null;
        isBlacklistedBySystem: boolean;
    };
    token: string;
}>;
export declare const getMe: (userId: number) => Promise<{
    profile: {
        id: number;
        userId: number;
        createdAt: Date;
        email: string | null;
        avatarUrl: string | null;
        bio: string | null;
        description: string | null;
        specialityTitle: string | null;
        fcmToken: string | null;
        pushNotificationsEnabled: boolean;
        darkModeEnabled: boolean;
        address: string | null;
        latitude: number | null;
        longitude: number | null;
    } | null;
    role: import("../../../generated/prisma/index.js").$Enums.Role;
    id: number;
    createdAt: Date;
    fullName: string;
    phoneNumber: string;
    isVerified: boolean;
    workplaceSalonId: number | null;
    ignoredAppointmentsCount: number;
    blacklistedAt: Date | null;
    isBlacklistedBySystem: boolean;
}>;
export declare const updateProfile: (userId: number, data: {
    fullName?: string;
    phoneNumber?: string;
    email?: string;
    avatarUrl?: string;
    bio?: string;
    fcmToken?: string;
    address?: string;
}) => Promise<{
    id: number;
    userId: number;
    createdAt: Date;
    email: string | null;
    avatarUrl: string | null;
    bio: string | null;
    description: string | null;
    specialityTitle: string | null;
    fcmToken: string | null;
    pushNotificationsEnabled: boolean;
    darkModeEnabled: boolean;
    address: string | null;
    latitude: number | null;
    longitude: number | null;
}>;
export declare const checkPhoneExists: (phoneNumber: string) => Promise<{
    exists: boolean;
    role: import("../../../generated/prisma/index.js").$Enums.Role;
} | {
    exists: boolean;
    role: null;
}>;
export declare const requestOtp: (phoneNumber: string) => Promise<{
    message: string;
}>;
export declare const verifyOtp: (phoneNumber: string, submittedCode: string) => Promise<{
    message: string;
    phoneVerificationToken: string;
}>;
type AdminUserUpdateInput = {
    fullName?: string;
    phoneNumber?: string;
    role?: Role;
    isVerified?: boolean;
    isBlacklistedBySystem?: boolean;
    profile?: {
        email?: string;
        specialityTitle?: string;
        bio?: string;
        description?: string;
    };
};
export declare const getAllUsersAdmin: () => Promise<{
    profile: {
        id: number;
        userId: number;
        createdAt: Date;
        email: string | null;
        avatarUrl: string | null;
        bio: string | null;
        description: string | null;
        specialityTitle: string | null;
        fcmToken: string | null;
        pushNotificationsEnabled: boolean;
        darkModeEnabled: boolean;
        address: string | null;
        latitude: number | null;
        longitude: number | null;
    } | null;
    _count: {
        appointmentsBarber: number;
        appointmentsClient: number;
        salonsOwned: number;
    };
    role: import("../../../generated/prisma/index.js").$Enums.Role;
    id: number;
    createdAt: Date;
    fullName: string;
    phoneNumber: string;
    isVerified: boolean;
    workplaceSalonId: number | null;
    ignoredAppointmentsCount: number;
    blacklistedAt: Date | null;
    isBlacklistedBySystem: boolean;
}[]>;
export declare const updateUserAdmin: (userId: number, data: AdminUserUpdateInput) => Promise<{
    profile: {
        id: number;
        userId: number;
        createdAt: Date;
        email: string | null;
        avatarUrl: string | null;
        bio: string | null;
        description: string | null;
        specialityTitle: string | null;
        fcmToken: string | null;
        pushNotificationsEnabled: boolean;
        darkModeEnabled: boolean;
        address: string | null;
        latitude: number | null;
        longitude: number | null;
    } | null;
} & {
    role: import("../../../generated/prisma/index.js").$Enums.Role;
    id: number;
    createdAt: Date;
    fullName: string;
    phoneNumber: string;
    passwordHash: string;
    isVerified: boolean;
    workplaceSalonId: number | null;
    ignoredAppointmentsCount: number;
    blacklistedAt: Date | null;
    isBlacklistedBySystem: boolean;
}>;
export declare const deleteUserAdmin: (userId: number) => Promise<{
    role: import("../../../generated/prisma/index.js").$Enums.Role;
    id: number;
    createdAt: Date;
    fullName: string;
    phoneNumber: string;
    passwordHash: string;
    isVerified: boolean;
    workplaceSalonId: number | null;
    ignoredAppointmentsCount: number;
    blacklistedAt: Date | null;
    isBlacklistedBySystem: boolean;
}>;
export {};
//# sourceMappingURL=auth.service.d.ts.map