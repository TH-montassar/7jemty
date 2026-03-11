import * as uploadService from './upload.service.js';
export const uploadFileHandler = async (req, res) => {
    try {
        if (!req.file) {
            res.status(400).json({ success: false, message: 'No file uploaded' });
            return;
        }
        const result = await uploadService.uploadToCloudinary(req.file);
        res.json({
            success: true,
            ...result
        });
    }
    catch (error) {
        console.error('Upload handler error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
};
//# sourceMappingURL=upload.controller.js.map