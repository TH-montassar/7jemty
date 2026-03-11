import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
export const protect = (req, res, next) => {
    try {
        // 1. Nchoufou ken l'header fih Authorization
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            res.status(401).json({ success: false, message: 'Non autorisé, token manquant' });
            return;
        }
        // 2. Nbadlou l'token mel string (Bearer xxxxx)
        const token = authHeader.split(' ')[1];
        if (!token) {
            res.status(401).json({ success: false, message: 'Non autorisé, token mal formaté' });
            return;
        }
        // 3. Nverifiw e-token
        const decoded = jwt.verify(token, env.JWT_SECRET);
        // 4. N7ottou e-data mta3 l'user fel Request bech nesta3mlouha fel Controllers
        req.user = decoded;
        next(); // T3adda lel etape elli ba3dha
    }
    catch (error) {
        res.status(401).json({ success: false, message: 'Token invalide ou expiré' });
    }
};
export const isPatron = (req, res, next) => {
    if (req.user && (req.user.role === 'PATRON' || req.user.role === 'ADMIN')) {
        next();
    }
    else {
        res.status(403).json({ success: false, message: 'Accès refusé, réservé aux Patrons ou Admins' });
    }
};
// Middleware bech nthabtou ken l'user Admin
export const isAdmin = (req, res, next) => {
    if (req.user && req.user.role === 'ADMIN') {
        next();
    }
    else {
        res.status(403).json({ success: false, message: 'Accès refusé, réservé aux Admins' });
    }
};
//# sourceMappingURL=auth.middleware.js.map