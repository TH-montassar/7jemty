import { Router } from 'express';
import multer from 'multer';
import { uploadFileHandler } from './upload.controller.js';
import { protect } from '../../middlewares/auth.middleware.js';
const router = Router();
const upload = multer({ storage: multer.memoryStorage() });
router.post('/', protect, upload.single('file'), uploadFileHandler);
export default router;
//# sourceMappingURL=upload.routes.js.map