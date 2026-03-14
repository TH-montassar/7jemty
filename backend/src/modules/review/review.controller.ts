import type { Request, Response } from 'express';
import { dismissReport, getReports, getResolvedReports, reportReview, takeAction } from './review.service.js';

export const reportReviewController = async (req: Request, res: Response) => {
    try {
        const reviewId = Number(req.params['id']);
        const user = (req as Request & { user?: { userId: number; role: string; id?: number } }).user;

        if (!user?.userId) {
            res.status(400).json({ success: false, message: 'Utilisateur non authentifié' });
            return;
        }

        const reason = (req.body?.reason ?? '').toString().trim();
        const message = (req.body?.message ?? '').toString();

        if (!reason) {
            res.status(400).json({ success: false, message: 'La raison est obligatoire' });
            return;
        }

        const result = await reportReview(reviewId, user.userId, user.role, reason, message);
        res.status(201).json({ success: true, data: result });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};

export const getReportsController = async (_req: Request, res: Response) => {
    try {
        const result = await getReports();
        res.status(200).json({ success: true, data: result });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};

export const getResolvedReportsController = async (_req: Request, res: Response) => {
    try {
        const result = await getResolvedReports();
        res.status(200).json({ success: true, data: result });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};

export const dismissReportController = async (req: Request, res: Response) => {
    try {
        const reportId = Number(req.params['id']);
        const result = await dismissReport(reportId);
        res.status(200).json({ success: true, data: result });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};

export const takeActionController = async (req: Request, res: Response) => {
    try {
        const reportId = Number(req.params['id']);
        const user = (req as Request & { user?: { userId: number; id?: number } }).user;
        const adminId = user?.id ?? user?.userId;

        if (!adminId) {
            res.status(400).json({ success: false, message: 'Admin non authentifié' });
            return;
        }

        const result = await takeAction(reportId, adminId);
        res.status(200).json({ success: true, data: result });
    } catch (error: any) {
        res.status(400).json({ success: false, message: error.message });
    }
};
