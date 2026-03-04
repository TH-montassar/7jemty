import type { Response } from 'express';
import { prisma } from '../../lib/db.js';
import type { AuthRequest } from '../../middlewares/auth.middleware.js';

export const getMyNotifications = async (req: AuthRequest, res: Response) => {
    try {
        if (!req.user || !req.user.userId) {
            res.status(401).json({ message: 'Non autorisé' });
            return;
        }

        const notifications = await prisma.notification.findMany({
            where: { userId: req.user.userId },
            orderBy: { createdAt: 'desc' }
        });

        res.json(notifications);
    } catch (e) {
        console.error("Failed fetching notifications:", e);
        res.status(500).json({ message: 'Erreur lors de la récupération des notifications' });
    }
};

export const getUnreadCount = async (req: AuthRequest, res: Response) => {
    try {
        if (!req.user || !req.user.userId) {
            res.status(401).json({ message: 'Non autorisé' });
            return;
        }

        const count = await prisma.notification.count({
            where: {
                userId: req.user.userId,
                isRead: false
            }
        });

        res.json({ count });
    } catch (e) {
        console.error("Failed fetching unread notification count:", e);
        res.status(500).json({ count: 0 });
    }
};

export const markNotificationAsRead = async (req: AuthRequest, res: Response) => {
    try {
        if (!req.user || !req.user.userId) {
            res.status(401).json({ message: 'Non autorisé' });
            return;
        }

        const notificationId = parseInt(req.params.id as string);
        if (isNaN(notificationId)) {
            res.status(400).json({ message: 'ID invalide' });
            return;
        }

        const updated = await prisma.notification.updateMany({
            where: {
                id: notificationId,
                userId: req.user.userId
            },
            data: { isRead: true }
        });

        if (updated.count === 0) {
            res.status(404).json({ message: 'Notification introuvable ou déjà lue' });
            return;
        }

        res.json({ message: 'Notification marquée comme lue' });
    } catch (e) {
        console.error("Failed marking notification as read:", e);
        res.status(500).json({ message: 'Erreur lors de la mise à jour de la notification' });
    }
};
