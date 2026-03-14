import 'dotenv/config';
const requireEnv = (key) => {
    const value = process.env[key];
    if (!value)
        throw new Error(`❌ Missing required env variable: ${key}`);
    return value;
};
export const env = {
    PORT: process.env.PORT || 3000,
    NODE_ENV: process.env.NODE_ENV || 'development',
    DATABASE_URL: requireEnv('DATABASE_URL'),
    JWT_SECRET: requireEnv('JWT_SECRET'),
    CLOUDINARY_CLOUD_NAME: requireEnv('CLOUDINARY_CLOUD_NAME'),
    CLOUDINARY_API_KEY: requireEnv('CLOUDINARY_API_KEY'),
    CLOUDINARY_API_SECRET: requireEnv('CLOUDINARY_API_SECRET'),
    FIREBASE_SERVICE_ACCOUNT_JSON: process.env.FIREBASE_SERVICE_ACCOUNT_JSON,
    FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID,
    FIREBASE_CLIENT_EMAIL: process.env.FIREBASE_CLIENT_EMAIL,
    FIREBASE_PRIVATE_KEY: process.env.FIREBASE_PRIVATE_KEY,
};
//# sourceMappingURL=env.js.map