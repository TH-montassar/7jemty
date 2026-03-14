import express from 'express';
import cors from 'cors';
import { initializeFirebase } from './config/firebase.js';
import { initCronJobs } from './config/cron.service.js';
import { isAdmin, protect } from './middlewares/auth.middleware.js';
import authRoutes from './modules/auth/auth.routes.js';
import authAdminRoutes from './modules/auth/auth.admin.routes.js';
import salonRoutes from './modules/salon/salon.routes.js';
import salonAdminRoutes from './modules/salon/salon.admin.routes.js';
import appointmentRoutes from './modules/appointment/appointment.routes.js';
import appointmentAdminRoutes from './modules/appointment/appointment.admin.routes.js';
import uploadRoutes from './modules/upload/upload.routes.js';
import notificationRoutes from './modules/notifications/notifications.routes.js';
import reviewRoutes from './modules/review/review.routes.js';
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
app.use('/api/review', reviewRoutes);
// Admin endpoints stay feature-owned, with shared admin guard at app level.
app.use('/api/admin', protect, isAdmin);
app.use('/api/admin', authAdminRoutes);
app.use('/api/admin', salonAdminRoutes);
app.use('/api/admin', appointmentAdminRoutes);
app.get('/', (req, res) => {
    res.json({ message: "Hjamty API is running smoothly! 🚀" });
});
export default app;
//# sourceMappingURL=app.js.map