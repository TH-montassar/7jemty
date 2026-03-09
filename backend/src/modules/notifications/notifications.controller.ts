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

        broadcastNotificationToUser(req.user.userId, {
            type: 'NOTIFICATION_READ',
            id: notificationId
        });

        res.json({ message: 'Notification marquée comme lue' });
    } catch (e) {
        console.error("Failed marking notification as read:", e);
        res.status(500).json({ message: 'Erreur lors de la mise à jour de la notification' });
    }
};

// --- REAL-TIME SSE SUPPORT --- //

// Maps userId to a set of active Express Response streams
const activeClients = new Map<number, Set<Response>>();

export const streamNotifications = (req: AuthRequest, res: Response) => {
    if (!req.user || !req.user.userId) {
        res.status(401).json({ message: 'Non autorisé' });
        return;
    }

    const userId = req.user.userId;

    // Set headers required for Server-Sent Events (SSE)
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');

    // Crucial: disable the default 5-second socket timeout in Node
    req.socket.setTimeout(0);
    req.socket.setNoDelay(true);
    req.socket.setKeepAlive(true);

    // Flush headers to establish stream
    res.flushHeaders?.();

    if (!activeClients.has(userId)) {
        activeClients.set(userId, new Set());
    }
    activeClients.get(userId)!.add(res);

    // Keep connection alive with periodic pings to avoid timeout
    const intervalId = setInterval(() => {
        res.write(':\n\n'); // SSE comment to keep alive
    }, 30000);

    // Initial ping
    res.write(`data: {"connected":true}\n\n`);

    // Clean up when the client closes the connection
    req.on('close', () => {
        clearInterval(intervalId);
        activeClients.get(userId)?.delete(res);
        if (activeClients.get(userId)?.size === 0) {
            activeClients.delete(userId);
        }
    });
};

export const broadcastNotificationToUser = (userId: number, notificationData: any) => {
    const clients = activeClients.get(userId);
    if (!clients) return;

    // Broadcast the new notification stringified to all active sessions (web, mobile, etc) for this user.
    clients.forEach(clientRes => {
        clientRes.write(`data: ${JSON.stringify(notificationData)}\n\n`);
    });
};

export const broadcastToAll = (notificationData: any) => {
    activeClients.forEach((clients) => {
        clients.forEach(clientRes => {
            clientRes.write(`data: ${JSON.stringify(notificationData)}\n\n`);
        });
    });
};
