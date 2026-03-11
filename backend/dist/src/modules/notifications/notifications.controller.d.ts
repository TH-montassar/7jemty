import type { Response } from 'express';
import type { AuthRequest } from '../../middlewares/auth.middleware.js';
export declare const getMyNotifications: (req: AuthRequest, res: Response) => Promise<void>;
export declare const getUnreadCount: (req: AuthRequest, res: Response) => Promise<void>;
export declare const markNotificationAsRead: (req: AuthRequest, res: Response) => Promise<void>;
export declare const streamNotifications: (req: AuthRequest, res: Response) => void;
export declare const broadcastNotificationToUser: (userId: number, notificationData: any) => void;
export declare const broadcastToAll: (notificationData: any) => void;
//# sourceMappingURL=notifications.controller.d.ts.map