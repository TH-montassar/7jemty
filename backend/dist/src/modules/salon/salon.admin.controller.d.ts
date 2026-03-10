import type { Response } from 'express';
import type { AuthRequest } from '../../middlewares/auth.middleware.js';
export declare const getAllSalonsAdminHandler: (req: AuthRequest, res: Response) => Promise<void>;
export declare const updateSalonAdminHandler: (req: AuthRequest, res: Response) => Promise<void>;
export declare const updateSalonStatusAdminHandler: (req: AuthRequest, res: Response) => Promise<void>;
export declare const deleteSalonAdminHandler: (req: AuthRequest, res: Response) => Promise<void>;
export declare const getSalonStatsAdminHandler: (req: AuthRequest, res: Response) => Promise<void>;
export declare const createSalonServiceAdminHandler: (req: AuthRequest, res: Response) => Promise<void>;
export declare const updateSalonServiceAdminHandler: (req: AuthRequest, res: Response) => Promise<void>;
export declare const deleteSalonServiceAdminHandler: (req: AuthRequest, res: Response) => Promise<void>;
export declare const createSalonEmployeeAdminHandler: (req: AuthRequest, res: Response) => Promise<void>;
export declare const updateSalonEmployeeAdminHandler: (req: AuthRequest, res: Response) => Promise<void>;
export declare const deleteSalonEmployeeAdminHandler: (req: AuthRequest, res: Response) => Promise<void>;
export declare const addSalonPortfolioImageAdminHandler: (req: AuthRequest, res: Response) => Promise<void>;
export declare const removeSalonPortfolioImageAdminHandler: (req: AuthRequest, res: Response) => Promise<void>;
//# sourceMappingURL=salon.admin.controller.d.ts.map