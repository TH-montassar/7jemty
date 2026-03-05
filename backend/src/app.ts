import express from 'express';
import cors from 'cors';
import { initializeFirebase } from './config/firebase.js';
import { initCronJobs } from './config/cron.service.js';
import authRoutes from './modules/auth/auth.routes.js';
import salonRoutes from './modules/salon/salon.routes.js';
import appointmentRoutes from './modules/appointment/appointment.routes.js';
import uploadRoutes from './modules/upload/upload.routes.js';
import notificationRoutes from './modules/notifications/notifications.routes.js';
import adminRoutes from './modules/admin/admin.routes.js';

const app = express();
initializeFirebase();
initCronJobs();

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use('/api/auth', authRoutes);
app.use('/api/salon', salonRoutes);
app.use('/api/appointment', appointmentRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin', adminRoutes);

app.get('/', (req, res) => {
    res.json({ message: "Hjamty API is running smoothly! 🚀" });
});

export default app;