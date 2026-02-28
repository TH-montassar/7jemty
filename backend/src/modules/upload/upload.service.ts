import cloudinary from '../../lib/cloudinary.js';

export const uploadToCloudinary = async (file: Express.Multer.File, folder: string = '7jemty_profiles'): Promise<{ url: string; public_id: string }> => {
    return new Promise((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
            {
                resource_type: 'auto',
                folder: folder,
            },
            (error, result) => {
                if (error || !result) {
                    return reject(error || new Error('Upload to Cloudinary failed'));
                }
                resolve({
                    url: result.secure_url,
                    public_id: result.public_id,
                });
            }
        );

        uploadStream.end(file.buffer);
    });
};
