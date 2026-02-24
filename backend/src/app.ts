import express from 'express';
import cors from 'cors';
import authRoutes from './modules/auth/auth.routes.js';
import type { Request, Response } from 'express';
import { prisma } from '../src/lib/db.js';

const app = express();

app.use(cors());
app.use(express.json());

// توجيه الروابط متع الـ Auth
app.use('/api/auth', authRoutes);

// مسار التجربة
app.get('/', (req, res) => {
    res.json({ message: "Hjamty API is running smoothly! 🚀" });
});




app.get('/users', async (req: Request, res: Response) => {
    try {
        const users = await prisma.user.findMany();
        res.json({ success: true, data: users });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
});
// POST create a user
app.post('/users', async (req: Request, res: Response) => {
    try {
        const { fullName, phoneNumber, passwordHash } = req.body;
        const user = await prisma.user.create({
            data: {
                fullName,
                phoneNumber,
                passwordHash,
            },
        });
        res.status(201).json({ success: true, data: user });
    } catch (error: any) {
        res.status(500).json({ success: false, message: error.message });
    }
});

export default app;