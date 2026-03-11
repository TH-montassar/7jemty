type UserRole = 'CLIENT' | 'EMPLOYEE' | 'PATRON' | 'ADMIN';
type AppointmentStatusInput = 'PENDING' | 'CONFIRMED' | 'IN_PROGRESS' | 'ARRIVED' | 'COMPLETED' | 'CANCELLED' | 'DECLINED';
type AppointmentTargetInput = 'EMPLOYEE' | 'PATRON';
export declare const updateAppointmentStatus: (appointmentId: number, status: AppointmentStatusInput, userId: number, userRole: UserRole) => Promise<any>;
export declare const getBarberAvailability: (salonId: number, dateString: string, requestedBarberId?: number, serviceIds?: number[], clientId_for_overlap_check?: number) => Promise<{
    time: string;
    available: boolean;
}[]>;
export declare const getAvailableDatesForRange: (salonId: number, startDateStr: string, endDateStr: string, requestedBarberId?: number, serviceIds?: number[], clientId_for_overlap_check?: number) => Promise<string[]>;
export declare const createClientAppointment: (clientId: number, salonId: number, barberId: number | undefined, dateString: string, timeString: string, serviceIds: number[], targetType?: AppointmentTargetInput) => Promise<{
    barber: {
        fullName: string;
        profile: {
            avatarUrl: string | null;
        } | null;
    } | null;
    client: {
        fullName: string;
        phoneNumber: string;
    };
    salon: {
        name: string;
        address: string | null;
        coverImageUrl: string | null;
    };
    services: ({
        service: {
            id: number;
            name: string;
            description: string | null;
            salonId: number;
            imageUrl: string | null;
            price: number;
            durationMinutes: number;
        };
    } & {
        id: number;
        appointmentId: number;
        serviceId: number;
    })[];
} & {
    id: number;
    createdAt: Date;
    status: import("../../../generated/prisma/index.js").$Enums.AppointmentStatus;
    clientId: number;
    salonId: number;
    barberId: number | null;
    appointmentDate: Date;
    estimatedEndTime: Date;
    totalPrice: number;
    totalDurationMinutes: number;
    targetType: import("../../../generated/prisma/index.js").$Enums.AppointmentTarget;
    confirmedAt: Date | null;
    cancelledAt: Date | null;
    startedAt: Date | null;
    completedAt: Date | null;
    actualEndTime: Date | null;
    nextCompletionCheckAt: Date | null;
    completionPromptCount: number;
    reviewRequestedAt: Date | null;
    is1hReminderSent: boolean;
    is10mReminderSent: boolean;
    lastCompletionAskTime: Date | null;
}>;
export declare const processInProgressReminders: () => Promise<void>;
export declare const processCompletionAlerts: () => Promise<void>;
export declare const getSalonAppointments: (patronId: number) => Promise<({
    barber: {
        fullName: string;
        profile: {
            avatarUrl: string | null;
        } | null;
    } | null;
    client: {
        fullName: string;
        phoneNumber: string;
        profile: {
            avatarUrl: string | null;
        } | null;
    };
    salon: {
        name: string;
        address: string | null;
        coverImageUrl: string | null;
    };
    services: ({
        service: {
            id: number;
            name: string;
            description: string | null;
            salonId: number;
            imageUrl: string | null;
            price: number;
            durationMinutes: number;
        };
    } & {
        id: number;
        appointmentId: number;
        serviceId: number;
    })[];
} & {
    id: number;
    createdAt: Date;
    status: import("../../../generated/prisma/index.js").$Enums.AppointmentStatus;
    clientId: number;
    salonId: number;
    barberId: number | null;
    appointmentDate: Date;
    estimatedEndTime: Date;
    totalPrice: number;
    totalDurationMinutes: number;
    targetType: import("../../../generated/prisma/index.js").$Enums.AppointmentTarget;
    confirmedAt: Date | null;
    cancelledAt: Date | null;
    startedAt: Date | null;
    completedAt: Date | null;
    actualEndTime: Date | null;
    nextCompletionCheckAt: Date | null;
    completionPromptCount: number;
    reviewRequestedAt: Date | null;
    is1hReminderSent: boolean;
    is10mReminderSent: boolean;
    lastCompletionAskTime: Date | null;
})[]>;
export declare const getAppointmentsBySalonId: (salonId: number) => Promise<({
    barber: {
        fullName: string;
        profile: {
            avatarUrl: string | null;
        } | null;
    } | null;
    client: {
        fullName: string;
        phoneNumber: string;
        profile: {
            avatarUrl: string | null;
        } | null;
    };
    salon: {
        name: string;
        address: string | null;
        coverImageUrl: string | null;
    };
    services: ({
        service: {
            id: number;
            name: string;
            description: string | null;
            salonId: number;
            imageUrl: string | null;
            price: number;
            durationMinutes: number;
        };
    } & {
        id: number;
        appointmentId: number;
        serviceId: number;
    })[];
} & {
    id: number;
    createdAt: Date;
    status: import("../../../generated/prisma/index.js").$Enums.AppointmentStatus;
    clientId: number;
    salonId: number;
    barberId: number | null;
    appointmentDate: Date;
    estimatedEndTime: Date;
    totalPrice: number;
    totalDurationMinutes: number;
    targetType: import("../../../generated/prisma/index.js").$Enums.AppointmentTarget;
    confirmedAt: Date | null;
    cancelledAt: Date | null;
    startedAt: Date | null;
    completedAt: Date | null;
    actualEndTime: Date | null;
    nextCompletionCheckAt: Date | null;
    completionPromptCount: number;
    reviewRequestedAt: Date | null;
    is1hReminderSent: boolean;
    is10mReminderSent: boolean;
    lastCompletionAskTime: Date | null;
})[]>;
export declare const getClientAppointments: (clientId: number) => Promise<({
    barber: {
        fullName: string;
        profile: {
            avatarUrl: string | null;
        } | null;
    } | null;
    client: {
        fullName: string;
        phoneNumber: string;
    };
    salon: {
        id: number;
        name: string;
        address: string | null;
        latitude: number | null;
        longitude: number | null;
        googleMapsUrl: string | null;
        coverImageUrl: string | null;
    };
    services: ({
        service: {
            id: number;
            name: string;
            description: string | null;
            salonId: number;
            imageUrl: string | null;
            price: number;
            durationMinutes: number;
        };
    } & {
        id: number;
        appointmentId: number;
        serviceId: number;
    })[];
    review: {
        createdAt: Date;
        rating: number;
        comment: string | null;
    } | null;
} & {
    id: number;
    createdAt: Date;
    status: import("../../../generated/prisma/index.js").$Enums.AppointmentStatus;
    clientId: number;
    salonId: number;
    barberId: number | null;
    appointmentDate: Date;
    estimatedEndTime: Date;
    totalPrice: number;
    totalDurationMinutes: number;
    targetType: import("../../../generated/prisma/index.js").$Enums.AppointmentTarget;
    confirmedAt: Date | null;
    cancelledAt: Date | null;
    startedAt: Date | null;
    completedAt: Date | null;
    actualEndTime: Date | null;
    nextCompletionCheckAt: Date | null;
    completionPromptCount: number;
    reviewRequestedAt: Date | null;
    is1hReminderSent: boolean;
    is10mReminderSent: boolean;
    lastCompletionAskTime: Date | null;
})[]>;
export declare const getEmployeeAppointments: (employeeId: number) => Promise<({
    barber: {
        fullName: string;
        profile: {
            avatarUrl: string | null;
        } | null;
    } | null;
    client: {
        id: number;
        fullName: string;
        phoneNumber: string;
    };
    salon: {
        id: number;
        name: string;
        address: string | null;
    };
    services: ({
        service: {
            id: number;
            name: string;
            description: string | null;
            salonId: number;
            imageUrl: string | null;
            price: number;
            durationMinutes: number;
        };
    } & {
        id: number;
        appointmentId: number;
        serviceId: number;
    })[];
} & {
    id: number;
    createdAt: Date;
    status: import("../../../generated/prisma/index.js").$Enums.AppointmentStatus;
    clientId: number;
    salonId: number;
    barberId: number | null;
    appointmentDate: Date;
    estimatedEndTime: Date;
    totalPrice: number;
    totalDurationMinutes: number;
    targetType: import("../../../generated/prisma/index.js").$Enums.AppointmentTarget;
    confirmedAt: Date | null;
    cancelledAt: Date | null;
    startedAt: Date | null;
    completedAt: Date | null;
    actualEndTime: Date | null;
    nextCompletionCheckAt: Date | null;
    completionPromptCount: number;
    reviewRequestedAt: Date | null;
    is1hReminderSent: boolean;
    is10mReminderSent: boolean;
    lastCompletionAskTime: Date | null;
})[]>;
export declare const extendAppointment: (appointmentId: number, minutes: number, userId: number, role: "PATRON" | "EMPLOYEE") => Promise<{
    client: {
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
    status: import("../../../generated/prisma/index.js").$Enums.AppointmentStatus;
    clientId: number;
    salonId: number;
    barberId: number | null;
    appointmentDate: Date;
    estimatedEndTime: Date;
    totalPrice: number;
    totalDurationMinutes: number;
    targetType: import("../../../generated/prisma/index.js").$Enums.AppointmentTarget;
    confirmedAt: Date | null;
    cancelledAt: Date | null;
    startedAt: Date | null;
    completedAt: Date | null;
    actualEndTime: Date | null;
    nextCompletionCheckAt: Date | null;
    completionPromptCount: number;
    reviewRequestedAt: Date | null;
    is1hReminderSent: boolean;
    is10mReminderSent: boolean;
    lastCompletionAskTime: Date | null;
}>;
export declare const postponeNoShowWithCascade: (appointmentId: number, minutes: number, userId: number, role: "PATRON" | "EMPLOYEE") => Promise<{
    appointmentId: number;
    minutes: number;
    shiftedCount: number;
    shiftedAppointmentIds: any[];
}>;
export declare const getUnreviewedAppointments: (clientId: number) => Promise<({
    barber: {
        id: number;
        fullName: string;
    } | null;
    salon: {
        id: number;
        name: string;
        coverImageUrl: string | null;
    };
    services: ({
        service: {
            id: number;
            name: string;
            description: string | null;
            salonId: number;
            imageUrl: string | null;
            price: number;
            durationMinutes: number;
        };
    } & {
        id: number;
        appointmentId: number;
        serviceId: number;
    })[];
} & {
    id: number;
    createdAt: Date;
    status: import("../../../generated/prisma/index.js").$Enums.AppointmentStatus;
    clientId: number;
    salonId: number;
    barberId: number | null;
    appointmentDate: Date;
    estimatedEndTime: Date;
    totalPrice: number;
    totalDurationMinutes: number;
    targetType: import("../../../generated/prisma/index.js").$Enums.AppointmentTarget;
    confirmedAt: Date | null;
    cancelledAt: Date | null;
    startedAt: Date | null;
    completedAt: Date | null;
    actualEndTime: Date | null;
    nextCompletionCheckAt: Date | null;
    completionPromptCount: number;
    reviewRequestedAt: Date | null;
    is1hReminderSent: boolean;
    is10mReminderSent: boolean;
    lastCompletionAskTime: Date | null;
})[]>;
export declare const submitReview: (appointmentId: number, clientId: number, salonId: number, rating: number, comment?: string) => Promise<{
    id: number;
    appointmentId: number;
    createdAt: Date;
    clientId: number;
    salonId: number;
    rating: number;
    comment: string | null;
}>;
export {};
//# sourceMappingURL=appointment.service.d.ts.map