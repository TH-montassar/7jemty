// src/lib/db.ts
import 'dotenv/config';
import { PrismaClient } from '../../generated/prisma/index.js';
import { PrismaPg } from '@prisma/adapter-pg';

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });

export const prisma = new PrismaClient({
  adapter,
  log: ['query', 'info', 'warn', 'error']  // 👈 add it here
});

prisma.$connect()
  .then(() => console.log('✅ Database connected successfully'))
  .catch((err) => {
    console.error('❌ Database connection failed:', err);
    process.exit(1); // stop the server if DB is unreachable
  });