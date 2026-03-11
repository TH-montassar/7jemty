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
        profile: {
            avatarUrl: string | null;
        } | null;
        fullName: string;
    } | null;
    client: {
        phoneNumber: string;
        fullName: string;
    };
    salon: {
        name: string;
        address: string | null;
        coverImageUrl: string | null;
    };
    services: ({
        service: {
            id: number;
            salonId: number;
            name: string;
            description: string | null;
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
    clientId: number;
    salonId: number;
    barberId: number | null;
    appointmentDate: Date;
    estimatedEndTime: Date;
    totalPrice: number;
    totalDurationMinutes: number;
    status: import("../../../generated/prisma/index.js").$Enums.AppointmentStatus;
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
    createdAt: Date;
}>;
export declare const processInProgressReminders: () => Promise<void>;
export declare const processCompletionAlerts: () => Promise<void>;
export declare const getSalonAppointments: (patronId: number) => Promise<({
    barber: {
        profile: {
            avatarUrl: string | null;
        } | null;
        fullName: string;
    } | null;
    client: {
        profile: {
            avatarUrl: string | null;
        } | null;
        phoneNumber: string;
        fullName: string;
    };
    salon: {
        name: string;
        address: string | null;
        coverImageUrl: string | null;
    };
    services: ({
        service: {
            id: number;
            salonId: number;
            name: string;
            description: string | null;
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
    clientId: number;
    salonId: number;
    barberId: number | null;
    appointmentDate: Date;
    estimatedEndTime: Date;
    totalPrice: number;
    totalDurationMinutes: number;
    status: import("../../../generated/prisma/index.js").$Enums.AppointmentStatus;
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
    createdAt: Date;
})[]>;
export declare const getAppointmentsBySalonId: (salonId: number) => Promise<({
    barber: {
        profile: {
            avatarUrl: string | null;
        } | null;
        fullName: string;
    } | null;
    client: {
        profile: {
            avatarUrl: string | null;
        } | null;
        phoneNumber: string;
        fullName: string;
    };
    salon: {
        name: string;
        address: string | null;
        coverImageUrl: string | null;
    };
    services: ({
        service: {
            id: number;
            salonId: number;
            name: string;
            description: string | null;
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
    clientId: number;
    salonId: number;
    barberId: number | null;
    appointmentDate: Date;
    estimatedEndTime: Date;
    totalPrice: number;
    totalDurationMinutes: number;
    status: import("../../../generated/prisma/index.js").$Enums.AppointmentStatus;
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
    createdAt: Date;
})[]>;
export declare const getClientAppointments: (clientId: number) => Promise<({
    barber: {
        profile: {
            avatarUrl: string | null;
        } | null;
        fullName: string;
    } | null;
    client: {
        phoneNumber: string;
        fullName: string;
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
            salonId: number;
            name: string;
            description: string | null;
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
    clientId: number;
    salonId: number;
    barberId: number | null;
    appointmentDate: Date;
    estimatedEndTime: Date;
    totalPrice: number;
    totalDurationMinutes: number;
    status: import("../../../generated/prisma/index.js").$Enums.AppointmentStatus;
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
    createdAt: Date;
})[]>;
export declare const getEmployeeAppointments: (employeeId: number) => Promise<({
    barber: {
        profile: {
            avatarUrl: string | null;
        } | null;
        fullName: string;
    } | null;
    client: {
        id: number;
        phoneNumber: string;
        fullName: string;
    };
    salon: {
        id: number;
        name: string;
        address: string | null;
    };
    services: ({
        service: {
            id: number;
            salonId: number;
            name: string;
            description: string | null;
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
    clientId: number;
    salonId: number;
    barberId: number | null;
    appointmentDate: Date;
    estimatedEndTime: Date;
    totalPrice: number;
    totalDurationMinutes: number;
    status: import("../../../generated/prisma/index.js").$Enums.AppointmentStatus;
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
    createdAt: Date;
})[]>;
export declare const extendAppointment: (appointmentId: number, minutes: number, userId: number, role: "PATRON" | "EMPLOYEE") => Promise<{
    client: {
        id: number;
        createdAt: Date;
        phoneNumber: string;
        fullName: string;
        passwordHash: string;
        role: import("../../../generated/prisma/index.js").$Enums.Role;
        isVerified: boolean;
        workplaceSalonId: number | null;
        ignoredAppointmentsCount: number;
        blacklistedAt: Date | null;
        isBlacklistedBySystem: boolean;
    };
} & {
    id: number;
    clientId: number;
    salonId: number;
    barberId: number | null;
    appointmentDate: Date;
    estimatedEndTime: Date;
    totalPrice: number;
    totalDurationMinutes: number;
    status: import("../../../generated/prisma/index.js").$Enums.AppointmentStatus;
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
    createdAt: Date;
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
            salonId: number;
            name: string;
            description: string | null;
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
    clientId: number;
    salonId: number;
    barberId: number | null;
    appointmentDate: Date;
    estimatedEndTime: Date;
    totalPrice: number;
    totalDurationMinutes: number;
    status: import("../../../generated/prisma/index.js").$Enums.AppointmentStatus;
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
    createdAt: Date;
})[]>;
export declare const submitReview: (appointmentId: number, clientId: number, salonId: number, rating: number, comment?: string) => Promise<{
    id: number;
    clientId: number;
    salonId: number;
    createdAt: Date;
    rating: number;
    appointmentId: number;
    comment: string | null;
}>;
export {};
//# sourceMappingURL=appointment.service.d.ts.map