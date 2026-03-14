import { ReportStatus, Role } from '../../../generated/prisma/index.js';
import { prisma } from '../../lib/db.js';
import { sendNotification } from '../notifications/notifications.service.js';

export const reportReview = async (
    reviewId: number,
    reporterId: number,
    reporterRole: string,
    reason: string,
    message?: string,
) => {
    if (reporterRole === Role.CLIENT || reporterRole === Role.EMPLOYEE) {
        throw new Error("Vous n'avez pas le droit de signaler une review");
    }

    const review = await prisma.review.findUnique({
        where: { id: reviewId },
        include: { salon: true }
    });

    if (!review) {
        throw new Error('Review introuvable');
    }

    if (reporterRole === Role.PATRON && review.salon.patronId !== reporterId) {
        throw new Error('Vous ne pouvez signaler que les reviews de votre salon');
    }

    const existingReport = await prisma.reportedReview.findFirst({
        where: { reviewId, reporterId }
    });

    if (existingReport) {
        throw new Error('T3amlitha déjà le report');
    }

    const createdReport = await prisma.reportedReview.create({
        data: {
            reviewId,
            reporterId,
            reason,
            message: message?.trim() || null,
        }
    });

    const admins = await prisma.user.findMany({
        where: { role: Role.ADMIN },
        include: { profile: true }
    });

    for (const admin of admins) {
        await prisma.notification.create({
            data: {
                userId: admin.id,
                title: '🚨 Review signalée',
                body: `Salon ${review.salon.name}: raison "${reason}"`,
                eventType: 'REVIEW_REPORTED',
                deeplink: `/admin/reports/${createdReport.id}`
            }
        });

        if (admin.profile?.fcmToken) {
            await sendNotification(
                admin.profile.fcmToken,
                '🚨 Review signalée',
                `Salon ${review.salon.name}: raison "${reason}"`,
                {
                    type: 'REVIEW_REPORTED',
                    reportId: createdReport.id.toString(),
                    reviewId: review.id.toString(),
                }
            );
        }
    }

    return createdReport;
};

export const getReports = async () => {
    return prisma.reportedReview.findMany({
        where: { status: ReportStatus.PENDING },
        include: {
            review: {
                include: {
                    client: { select: { id: true, fullName: true, phoneNumber: true, warningCount: true } },
                    salon: { select: { id: true, name: true } }
                }
            },
            reporter: { select: { id: true, fullName: true, role: true } }
        },
        orderBy: { createdAt: 'desc' }
    });
};

export const getResolvedReports = async () => {
    return prisma.reportedReview.findMany({
        where: {
            status: { in: [ReportStatus.DISMISSED, ReportStatus.ACTION_TAKEN] }
        },
        include: {
            review: {
                include: {
                    client: { select: { id: true, fullName: true, phoneNumber: true, warningCount: true } },
                    salon: { select: { id: true, name: true } }
                }
            },
            reporter: { select: { id: true, fullName: true, role: true } }
        },
        orderBy: { resolvedAt: 'desc' }
    });
};

export const dismissReport = async (reportId: number) => {
    const report = await prisma.reportedReview.findUnique({ where: { id: reportId } });
    if (!report) {
        throw new Error('Report introuvable');
    }

    return prisma.reportedReview.update({
        where: { id: reportId },
        data: {
            status: ReportStatus.DISMISSED,
            resolvedAt: new Date(),
        }
    });
};

export const takeAction = async (reportId: number, adminId: number) => {
    const report = await prisma.reportedReview.findUnique({
        where: { id: reportId },
        include: {
            review: {
                include: {
                    client: { include: { profile: true } },
                    salon: { select: { name: true } }
                }
            }
        }
    });

    if (!report) {
        throw new Error('Report introuvable');
    }

    if (report.status !== ReportStatus.PENDING) {
        throw new Error('Report déjà traité');
    }

    const now = new Date();
    const clientId = report.review.clientId;
    const warningReason = `Review supprimée après signalement (${report.reason})`;

    await prisma.$transaction(async (tx) => {
        await tx.review.delete({ where: { id: report.reviewId } });

        await tx.userWarning.create({
            data: {
                userId: clientId,
                reason: warningReason,
            }
        });

        await tx.user.update({
            where: { id: clientId },
            data: {
                warningCount: { increment: 1 }
            }
        });

        await tx.reportedReview.update({
            where: { id: reportId },
            data: {
                status: ReportStatus.ACTION_TAKEN,
                resolvedAt: now,
                resolvedBy: adminId,
            }
        });

        await tx.notification.create({
            data: {
                userId: clientId,
                title: '⚠️ Avertissement',
                body: `Votre review sur ${report.review.salon.name} a été supprimée suite à un signalement.`,
                eventType: 'USER_WARNING',
                deeplink: '/profile'
            }
        });
    });

    const client = await prisma.user.findUnique({
        where: { id: clientId },
        include: { profile: true }
    });

    if (client?.profile?.fcmToken) {
        await sendNotification(
            client.profile.fcmToken,
            '⚠️ Avertissement',
            `Votre review sur ${report.review.salon.name} a été supprimée suite à un signalement.`,
            { type: 'USER_WARNING' }
        );
    }

    return { success: true, message: 'Review supprimée et client averti' };
};
