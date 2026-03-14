import { Role } from '../../../generated/prisma/index.js';
export declare const registerUser: (data: any) => Promise<{
    user: {
        profile: {
            fcmToken: string | null;
            email: string | null;
            avatarUrl: string | null;
            bio: string | null;
            description: string | null;
            specialityTitle: string | null;
            pushNotificationsEnabled: boolean;
            darkModeEnabled: boolean;
            address: string | null;
            latitude: number | null;
            longitude: number | null;
            createdAt: Date;
            id: number;
            userId: number;
        } | null;
        createdAt: Date;
        id: number;
        role: import("../../../generated/prisma/index.js").$Enums.Role;
        fullName: string;
        phoneNumber: string;
        isVerified: boolean;
        workplaceSalonId: number | null;
        ignoredAppointmentsCount: number;
        blacklistedAt: Date | null;
        isBlacklistedBySystem: boolean;
        warningCount: number;
    };
    token: string;
}>;
export declare const loginUser: (data: any) => Promise<{
    user: {
        hasSalon: boolean;
        createdAt: Date;
        id: number;
        role: import("../../../generated/prisma/index.js").$Enums.Role;
        fullName: string;
        phoneNumber: string;
        isVerified: boolean;
        workplaceSalonId: number | null;
        ignoredAppointmentsCount: number;
        blacklistedAt: Date | null;
        isBlacklistedBySystem: boolean;
        warningCount: number;
    };
    token: string;
}>;
export declare const getMe: (userId: number) => Promise<{
    profile: {
        fcmToken: string | null;
        email: string | null;
        avatarUrl: string | null;
        bio: string | null;
        description: string | null;
        specialityTitle: string | null;
        pushNotificationsEnabled: boolean;
        darkModeEnabled: boolean;
        address: string | null;
        latitude: number | null;
        longitude: number | null;
        createdAt: Date;
        id: number;
        userId: number;
    } | null;
    createdAt: Date;
    id: number;
    role: import("../../../generated/prisma/index.js").$Enums.Role;
    fullName: string;
    phoneNumber: string;
    isVerified: boolean;
    workplaceSalonId: number | null;
    ignoredAppointmentsCount: number;
    blacklistedAt: Date | null;
    isBlacklistedBySystem: boolean;
    warningCount: number;
}>;
export declare const updateProfile: (userId: number, data: {
    fullName?: string;
    phoneNumber?: string;
    email?: string;
    avatarUrl?: string;
    bio?: string;
    fcmToken?: string | null;
    address?: string;
}) => Promise<{
    fcmToken: string | null;
    email: string | null;
    avatarUrl: string | null;
    bio: string | null;
    description: string | null;
    specialityTitle: string | null;
    pushNotificationsEnabled: boolean;
    darkModeEnabled: boolean;
    address: string | null;
    latitude: number | null;
    longitude: number | null;
    createdAt: Date;
    id: number;
    userId: number;
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
        fcmToken: string | null;
        email: string | null;
        avatarUrl: string | null;
        bio: string | null;
        description: string | null;
        specialityTitle: string | null;
        pushNotificationsEnabled: boolean;
        darkModeEnabled: boolean;
        address: string | null;
        latitude: number | null;
        longitude: number | null;
        createdAt: Date;
        id: number;
        userId: number;
    } | null;
    _count: {
        appointmentsBarber: number;
        appointmentsClient: number;
        salonsOwned: number;
    };
    createdAt: Date;
    id: number;
    role: import("../../../generated/prisma/index.js").$Enums.Role;
    fullName: string;
    phoneNumber: string;
    isVerified: boolean;
    workplaceSalonId: number | null;
    ignoredAppointmentsCount: number;
    blacklistedAt: Date | null;
    isBlacklistedBySystem: boolean;
    warningCount: number;
}[]>;
export declare const updateUserAdmin: (userId: number, data: AdminUserUpdateInput) => Promise<{
    profile: {
        fcmToken: string | null;
        email: string | null;
        avatarUrl: string | null;
        bio: string | null;
        description: string | null;
        specialityTitle: string | null;
        pushNotificationsEnabled: boolean;
        darkModeEnabled: boolean;
        address: string | null;
        latitude: number | null;
        longitude: number | null;
        createdAt: Date;
        id: number;
        userId: number;
    } | null;
} & {
    createdAt: Date;
    id: number;
    role: import("../../../generated/prisma/index.js").$Enums.Role;
    fullName: string;
    phoneNumber: string;
    passwordHash: string;
    isVerified: boolean;
    workplaceSalonId: number | null;
    ignoredAppointmentsCount: number;
    blacklistedAt: Date | null;
    isBlacklistedBySystem: boolean;
    warningCount: number;
}>;
export declare const deleteUserAdmin: (userId: number) => Promise<{
    createdAt: Date;
    id: number;
    role: import("../../../generated/prisma/index.js").$Enums.Role;
    fullName: string;
    phoneNumber: string;
    passwordHash: string;
    isVerified: boolean;
    workplaceSalonId: number | null;
    ignoredAppointmentsCount: number;
    blacklistedAt: Date | null;
    isBlacklistedBySystem: boolean;
    warningCount: number;
}>;
export {};
//# sourceMappingURL=auth.service.d.ts.map