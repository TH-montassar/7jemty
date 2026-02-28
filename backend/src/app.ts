import express from 'express';
import cors from 'cors';
import authRoutes from './modules/auth/auth.routes.js';
import salonRoutes from './modules/salon/salon.routes.js';
import appointmentRoutes from './modules/appointment/appointment.routes.js';
import uploadRoutes from './modules/upload/upload.routes.js';

const app = express();
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use('/api/auth', authRoutes);
app.use('/api/salon', salonRoutes);
app.use('/api/appointment', appointmentRoutes);
app.use('/api/upload', uploadRoutes);

app.get('/', (req, res) => {
    res.json({ message: "Hjamty API is running smoothly! 🚀" });
});

export default app;