// src/lib/db.ts
import 'dotenv/config';
import { PrismaClient } from '../../generated/prisma/index.js';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';
const { Pool } = pg;
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    max: 20, // Increase max connections to handle parallel Flutter app queries
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 30000, // 30 seconds to allow Neon to spin up from sleep
});
const adapter = new PrismaPg(pool);
export const prisma = new PrismaClient({
    adapter,
    log: ['error']
});
prisma.$connect()
    .then(() => console.log('✅ Database connected successfully'))
    .catch((err) => {
    console.error('❌ Database connection failed:', err);
    process.exit(1); // stop the server if DB is unreachable
});
//# sourceMappingURL=db.js.map