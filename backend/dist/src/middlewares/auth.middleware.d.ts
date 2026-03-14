import type { Request, Response, NextFunction } from 'express';
export interface AuthRequest extends Request {
    user?: {
        userId: number;
        role: string;
    };
}
export declare const protect: (req: AuthRequest, res: Response, next: NextFunction) => void;
export declare const isPatron: (req: AuthRequest, res: Response, next: NextFunction) => void;
export declare const isAdmin: (req: AuthRequest, res: Response, next: NextFunction) => void;
export declare const isPatronOrAdmin: (req: AuthRequest, res: Response, next: NextFunction) => void;
//# sourceMappingURL=auth.middleware.d.ts.map