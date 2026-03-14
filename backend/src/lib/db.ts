// src/lib/db.ts
import 'dotenv/config';
import { PrismaClient } from '../../generated/prisma/index.js';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';
import { normalizeDatabaseUrl } from './normalizeDatabaseUrl.js';

const { Pool } = pg;
const pool = new Pool({
  connectionString: normalizeDatabaseUrl(process.env.DATABASE_URL!),
  max: 20, // Increase max connections to handle parallel Flutter app queries
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 30000, // 30 seconds to allow Neon to spin up from sleep
});

// Handle idle connection errors (e.g., when Neon puts the DB to sleep)
pool.on('error', (err, client) => {
  console.error('❌ Unexpected error on idle client', err);
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