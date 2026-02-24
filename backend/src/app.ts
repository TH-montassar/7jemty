import express from 'express';
import cors from 'cors';
import authRoutes from './modules/auth/auth.routes.js';
import salonRoutes from './modules/salon/salon.routes.js';

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/salon', salonRoutes);

app.get('/', (req, res) => {
    res.json({ message: "Hjamty API is running smoothly! 🚀" });
});

export default app;