import { Router } from 'express';
import { protect, isAdmin, isPatronOrAdmin } from '../../middlewares/auth.middleware.js';
import { dismissReportController, getReportsController, getResolvedReportsController, reportReviewController, takeActionController, } from './review.controller.js';
const router = Router();
router.post('/:id/report', protect, isPatronOrAdmin, reportReviewController);
router.get('/reports', protect, isAdmin, getReportsController);
router.get('/reports/resolved', protect, isAdmin, getResolvedReportsController);
router.patch('/reports/:id/dismiss', protect, isAdmin, dismissReportController);
router.patch('/reports/:id/action', protect, isAdmin, takeActionController);
export default router;
//# sourceMappingURL=review.routes.js.map