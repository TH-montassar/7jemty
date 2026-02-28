import { Router } from 'express';
import multer from 'multer';
import cloudinary from '../../lib/cloudinary.js';
import { protect } from '../../middlewares/auth.middleware.js';

const router = Router();
const upload = multer({ storage: multer.memoryStorage() });

router.post('/', protect, upload.single('file'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ success: false, message: 'No file uploaded' });
        }

        // Convert buffer to base64 to send to Cloudinary
        const b64 = Buffer.from(req.file.buffer).toString('base64');
        let dataURI = 'data:' + req.file.mimetype + ';base64,' + b64;

        const result = await cloudinary.uploader.upload(dataURI, {
            resource_type: 'auto',
            folder: '7jemty_profiles'
        });

        res.json({
            success: true,
            url: result.secure_url,
            public_id: result.public_id
        });
    } catch (error: any) {
        console.error('Cloudinary upload error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

export default router;
