export declare const reportReview: (reviewId: number, reporterId: number, reporterRole: string, reason: string, message?: string) => Promise<{
    createdAt: Date;
    id: number;
    status: import("../../../generated/prisma/index.js").$Enums.ReportStatus;
    message: string | null;
    reason: string;
    resolvedAt: Date | null;
    resolvedBy: number | null;
    reviewId: number;
    reporterId: number;
}>;
export declare const getReports: () => Promise<({
    review: {
        client: {
            id: number;
            fullName: string;
            phoneNumber: string;
            warningCount: number;
        };
        salon: {
            id: number;
            name: string;
        };
    } & {
        createdAt: Date;
        id: number;
        appointmentId: number;
        clientId: number;
        salonId: number;
        rating: number;
        comment: string | null;
    };
    reporter: {
        id: number;
        role: import("../../../generated/prisma/index.js").$Enums.Role;
        fullName: string;
    };
} & {
    createdAt: Date;
    id: number;
    status: import("../../../generated/prisma/index.js").$Enums.ReportStatus;
    message: string | null;
    reason: string;
    resolvedAt: Date | null;
    resolvedBy: number | null;
    reviewId: number;
    reporterId: number;
})[]>;
export declare const getResolvedReports: () => Promise<({
    review: {
        client: {
            id: number;
            fullName: string;
            phoneNumber: string;
            warningCount: number;
        };
        salon: {
            id: number;
            name: string;
        };
    } & {
        createdAt: Date;
        id: number;
        appointmentId: number;
        clientId: number;
        salonId: number;
        rating: number;
        comment: string | null;
    };
    reporter: {
        id: number;
        role: import("../../../generated/prisma/index.js").$Enums.Role;
        fullName: string;
    };
} & {
    createdAt: Date;
    id: number;
    status: import("../../../generated/prisma/index.js").$Enums.ReportStatus;
    message: string | null;
    reason: string;
    resolvedAt: Date | null;
    resolvedBy: number | null;
    reviewId: number;
    reporterId: number;
})[]>;
export declare const dismissReport: (reportId: number) => Promise<{
    createdAt: Date;
    id: number;
    status: import("../../../generated/prisma/index.js").$Enums.ReportStatus;
    message: string | null;
    reason: string;
    resolvedAt: Date | null;
    resolvedBy: number | null;
    reviewId: number;
    reporterId: number;
}>;
export declare const takeAction: (reportId: number, adminId: number) => Promise<{
    success: boolean;
    message: string;
}>;
//# sourceMappingURL=review.service.d.ts.map