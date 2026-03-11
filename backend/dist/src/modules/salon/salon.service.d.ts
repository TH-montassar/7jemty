import { ApprovalStatus } from '../../../generated/prisma/index.js';
export declare const createSalon: (patronId: number, data: any) => Promise<{
    id: number;
    createdAt: Date;
    name: string;
    description: string | null;
    address: string | null;
    latitude: number | null;
    longitude: number | null;
    patronId: number;
    contactPhone: string | null;
    googleMapsUrl: string | null;
    websiteUrl: string | null;
    coverImageUrl: string | null;
    speciality: string | null;
    rating: number | null;
    approvalStatus: import("../../../generated/prisma/index.js").$Enums.ApprovalStatus;
    isForceClosed: boolean;
}>;
export declare const updateSalon: (patronId: number, data: any) => Promise<{
    id: number;
    createdAt: Date;
    name: string;
    description: string | null;
    address: string | null;
    latitude: number | null;
    longitude: number | null;
    patronId: number;
    contactPhone: string | null;
    googleMapsUrl: string | null;
    websiteUrl: string | null;
    coverImageUrl: string | null;
    speciality: string | null;
    rating: number | null;
    approvalStatus: import("../../../generated/prisma/index.js").$Enums.ApprovalStatus;
    isForceClosed: boolean;
}>;
export declare const getSalonByPatronId: (patronId: number) => Promise<{
    patron: {
        id: number;
        name: string;
        imageUrl: string | null;
    };
    employees: {
        id: number;
        userId: number;
        salonId: number;
        name: string;
        phoneNumber: string;
        role: string;
        bio: string | null;
        description: string | null;
        imageUrl: string | null;
        createdAt: Date;
    }[];
    reviews: {
        id: number;
        clientId: number;
        clientName: string;
        clientImage: string | null;
        rating: number;
        comment: string | null;
        createdAt: Date;
    }[];
    rating: string;
    services: {
        id: number;
        name: string;
        description: string | null;
        salonId: number;
        imageUrl: string | null;
        price: number;
        durationMinutes: number;
    }[];
    portfolio: {
        id: number;
        createdAt: Date;
        salonId: number;
        imageUrl: string;
    }[];
    socialLinks: {
        url: string;
        id: number;
        salonId: number;
        platform: string;
    }[];
    workingHours: {
        id: number;
        salonId: number;
        dayOfWeek: number;
        openTime: string | null;
        closeTime: string | null;
        isDayOff: boolean;
    }[];
    id: number;
    createdAt: Date;
    name: string;
    description: string | null;
    address: string | null;
    latitude: number | null;
    longitude: number | null;
    patronId: number;
    contactPhone: string | null;
    googleMapsUrl: string | null;
    websiteUrl: string | null;
    coverImageUrl: string | null;
    speciality: string | null;
    approvalStatus: import("../../../generated/prisma/index.js").$Enums.ApprovalStatus;
    isForceClosed: boolean;
}>;
export declare const createEmployeeAccount: (patronId: number, data: any) => Promise<{
    id: number;
    userId: number;
    salonId: any;
    name: string;
    phoneNumber: string;
    role: any;
    bio: any;
    description: any;
    imageUrl: any;
    createdAt: Date;
}>;
export declare const createEmployeeAccountAdmin: (salonId: number, data: any) => Promise<{
    id: number;
    userId: number;
    salonId: number;
    name: string;
    phoneNumber: string;
    role: any;
    bio: any;
    description: any;
    imageUrl: any;
    createdAt: Date;
}>;
export declare const updateEmployeeAccount: (patronId: number, employeeId: number, data: any) => Promise<{
    id: number;
    userId: number;
    salonId: number;
    name: string;
    phoneNumber: string;
    role: string;
    bio: string | null;
    description: string | null;
    imageUrl: string | null;
    createdAt: Date;
}>;
export declare const updateEmployeeAccountAdmin: (salonId: number, employeeId: number, data: any) => Promise<{
    id: number;
    userId: number;
    salonId: number;
    name: string;
    phoneNumber: string;
    role: string;
    bio: string | null;
    description: string | null;
    imageUrl: string | null;
    createdAt: Date;
}>;
export declare const removeEmployeeFromSalon: (patronId: number, employeeId: number) => Promise<{
    id: number;
    removed: boolean;
}>;
export declare const removeEmployeeFromSalonAdmin: (salonId: number, employeeId: number) => Promise<{
    id: number;
    removed: boolean;
}>;
export declare const getAllSalons: (lat?: number, lng?: number, includeUnapproved?: boolean) => Promise<{
    distance: string | null;
    image: string;
    rating: string;
    _count: {
        reviews: number;
    };
    id: number;
    createdAt: Date;
    name: string;
    description: string | null;
    address: string | null;
    latitude: number | null;
    longitude: number | null;
    patronId: number;
    contactPhone: string | null;
    googleMapsUrl: string | null;
    websiteUrl: string | null;
    coverImageUrl: string | null;
    speciality: string | null;
    approvalStatus: import("../../../generated/prisma/index.js").$Enums.ApprovalStatus;
    isForceClosed: boolean;
}[]>;
export declare const createService: (patronId: number, data: any) => Promise<{
    id: number;
    name: string;
    description: string | null;
    salonId: number;
    imageUrl: string | null;
    price: number;
    durationMinutes: number;
}>;
export declare const createServiceAdmin: (salonId: number, data: any) => Promise<{
    id: number;
    name: string;
    description: string | null;
    salonId: number;
    imageUrl: string | null;
    price: number;
    durationMinutes: number;
}>;
export declare const getServices: (patronId: number) => Promise<{
    id: number;
    name: string;
    description: string | null;
    salonId: number;
    imageUrl: string | null;
    price: number;
    durationMinutes: number;
}[]>;
export declare const updateService: (patronId: number, serviceId: number, data: any) => Promise<{
    id: number;
    name: string;
    description: string | null;
    salonId: number;
    imageUrl: string | null;
    price: number;
    durationMinutes: number;
}>;
export declare const updateServiceAdmin: (salonId: number, serviceId: number, data: any) => Promise<{
    id: number;
    name: string;
    description: string | null;
    salonId: number;
    imageUrl: string | null;
    price: number;
    durationMinutes: number;
}>;
export declare const deleteService: (patronId: number, serviceId: number) => Promise<{
    id: number;
    deleted: boolean;
}>;
export declare const deleteServiceAdmin: (salonId: number, serviceId: number) => Promise<{
    id: number;
    deleted: boolean;
}>;
export declare const getSalonById: (id: number) => Promise<{
    id: number;
    patronId: number;
    name: string;
    description: string | null;
    contactPhone: string | null;
    address: string | null;
    latitude: number | null;
    longitude: number | null;
    googleMapsUrl: string | null;
    websiteUrl: string | null;
    coverImageUrl: string | null;
    speciality: string | null;
    approvalStatus: import("../../../generated/prisma/index.js").$Enums.ApprovalStatus;
    isForceClosed: boolean;
    createdAt: Date;
    patron: {
        id: number;
        name: string;
        imageUrl: string | null;
    };
    services: {
        id: number;
        name: string;
        description: string | null;
        salonId: number;
        imageUrl: string | null;
        price: number;
        durationMinutes: number;
    }[];
    socialLinks: {
        url: string;
        id: number;
        salonId: number;
        platform: string;
    }[];
    workingHours: {
        id: number;
        salonId: number;
        dayOfWeek: number;
        openTime: string | null;
        closeTime: string | null;
        isDayOff: boolean;
    }[];
    portfolio: {
        id: number;
        createdAt: Date;
        salonId: number;
        imageUrl: string;
    }[];
    employees: {
        id: number;
        userId: number;
        salonId: number;
        name: string;
        phoneNumber: string;
        role: string;
        bio: string | null;
        description: string | null;
        imageUrl: string | null;
        createdAt: Date;
    }[];
    reviews: {
        id: number;
        clientId: number;
        clientName: string;
        clientImage: string | null;
        rating: number;
        comment: string | null;
        createdAt: Date;
    }[];
    image: string;
    rating: string;
}>;
export declare const getTopRatedSalons: (limit?: number, includeUnapproved?: boolean) => Promise<{
    image: string;
    rating: string;
    _count: {
        reviews: number;
    };
    id: number;
    createdAt: Date;
    name: string;
    description: string | null;
    address: string | null;
    latitude: number | null;
    longitude: number | null;
    patronId: number;
    contactPhone: string | null;
    googleMapsUrl: string | null;
    websiteUrl: string | null;
    coverImageUrl: string | null;
    speciality: string | null;
    approvalStatus: import("../../../generated/prisma/index.js").$Enums.ApprovalStatus;
    isForceClosed: boolean;
}[]>;
export declare const searchSalons: (query: string, includeUnapproved?: boolean) => Promise<{
    image: string;
    rating: string;
    _count: {
        reviews: number;
    };
    services: {
        id: number;
        name: string;
        description: string | null;
        salonId: number;
        imageUrl: string | null;
        price: number;
        durationMinutes: number;
    }[];
    workingHours: {
        id: number;
        salonId: number;
        dayOfWeek: number;
        openTime: string | null;
        closeTime: string | null;
        isDayOff: boolean;
    }[];
    id: number;
    createdAt: Date;
    name: string;
    description: string | null;
    address: string | null;
    latitude: number | null;
    longitude: number | null;
    patronId: number;
    contactPhone: string | null;
    googleMapsUrl: string | null;
    websiteUrl: string | null;
    coverImageUrl: string | null;
    speciality: string | null;
    approvalStatus: import("../../../generated/prisma/index.js").$Enums.ApprovalStatus;
    isForceClosed: boolean;
}[]>;
export declare const toggleFavoriteSalon: (clientId: number, salonId: number) => Promise<{
    isFavorite: boolean;
}>;
export declare const checkFavoriteStatus: (clientId: number, salonId: number) => Promise<{
    isFavorite: boolean;
}>;
export declare const getFavoriteSalons: (clientId: number) => Promise<{
    image: string;
    rating: string;
    _count: {
        reviews: number;
    };
    services: {
        id: number;
        name: string;
        description: string | null;
        salonId: number;
        imageUrl: string | null;
        price: number;
        durationMinutes: number;
    }[];
    workingHours: {
        id: number;
        salonId: number;
        dayOfWeek: number;
        openTime: string | null;
        closeTime: string | null;
        isDayOff: boolean;
    }[];
    id: number;
    createdAt: Date;
    name: string;
    description: string | null;
    address: string | null;
    latitude: number | null;
    longitude: number | null;
    patronId: number;
    contactPhone: string | null;
    googleMapsUrl: string | null;
    websiteUrl: string | null;
    coverImageUrl: string | null;
    speciality: string | null;
    approvalStatus: import("../../../generated/prisma/index.js").$Enums.ApprovalStatus;
    isForceClosed: boolean;
}[]>;
export declare const createPortfolioImage: (patronId: number, imageUrl: string) => Promise<{
    id: number;
    createdAt: Date;
    salonId: number;
    imageUrl: string;
}>;
export declare const deletePortfolioImage: (patronId: number, imageId: number) => Promise<{
    id: number;
    createdAt: Date;
    salonId: number;
    imageUrl: string;
}>;
export declare const createPortfolioImageAdmin: (salonId: number, imageUrl: string) => Promise<{
    id: number;
    createdAt: Date;
    salonId: number;
    imageUrl: string;
}>;
export declare const deletePortfolioImageAdmin: (salonId: number, imageId: number) => Promise<{
    id: number;
    createdAt: Date;
    salonId: number;
    imageUrl: string;
}>;
export declare const getAllSalonsAdmin: () => Promise<({
    _count: {
        services: number;
        appointments: number;
        employees: number;
    };
    patron: {
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
    };
} & {
    id: number;
    createdAt: Date;
    name: string;
    description: string | null;
    address: string | null;
    latitude: number | null;
    longitude: number | null;
    patronId: number;
    contactPhone: string | null;
    googleMapsUrl: string | null;
    websiteUrl: string | null;
    coverImageUrl: string | null;
    speciality: string | null;
    rating: number | null;
    approvalStatus: import("../../../generated/prisma/index.js").$Enums.ApprovalStatus;
    isForceClosed: boolean;
})[]>;
export declare const updateSalonStatusAdmin: (salonId: number, status: ApprovalStatus) => Promise<{
    id: number;
    createdAt: Date;
    name: string;
    description: string | null;
    address: string | null;
    latitude: number | null;
    longitude: number | null;
    patronId: number;
    contactPhone: string | null;
    googleMapsUrl: string | null;
    websiteUrl: string | null;
    coverImageUrl: string | null;
    speciality: string | null;
    rating: number | null;
    approvalStatus: import("../../../generated/prisma/index.js").$Enums.ApprovalStatus;
    isForceClosed: boolean;
}>;
export declare const deleteSalonAdmin: (salonId: number) => Promise<{
    id: number;
    createdAt: Date;
    name: string;
    description: string | null;
    address: string | null;
    latitude: number | null;
    longitude: number | null;
    patronId: number;
    contactPhone: string | null;
    googleMapsUrl: string | null;
    websiteUrl: string | null;
    coverImageUrl: string | null;
    speciality: string | null;
    rating: number | null;
    approvalStatus: import("../../../generated/prisma/index.js").$Enums.ApprovalStatus;
    isForceClosed: boolean;
}>;
export declare const updateSalonAdmin: (salonId: number, data: any) => Promise<{
    id: number;
    createdAt: Date;
    name: string;
    description: string | null;
    address: string | null;
    latitude: number | null;
    longitude: number | null;
    patronId: number;
    contactPhone: string | null;
    googleMapsUrl: string | null;
    websiteUrl: string | null;
    coverImageUrl: string | null;
    speciality: string | null;
    rating: number | null;
    approvalStatus: import("../../../generated/prisma/index.js").$Enums.ApprovalStatus;
    isForceClosed: boolean;
}>;
export declare const getSalonStatsAdmin: (salonId: number) => Promise<{
    totalAppointments: number;
    totalRevenue: number;
    specialistStats: {
        name: string;
        count: number;
        revenue: number;
    }[];
}>;
//# sourceMappingURL=salon.service.d.ts.map