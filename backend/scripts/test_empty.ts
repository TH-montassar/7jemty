import 'dotenv/config';
import { PrismaClient } from '../generated/prisma/index.js';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';
import { normalizeDatabaseUrl } from '../src/lib/normalizeDatabaseUrl.js';

const { Pool } = pg;
const pool = new Pool({ connectionString: normalizeDatabaseUrl(process.env.DATABASE_URL!) });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('Testing prisma.salon.findMany() on current database...');
  try {
    const salons = await prisma.salon.findMany({
        where: { approvalStatus: 'APPROVED' },
    });
    console.log('✅ Success! Found salons:', salons.length);
  } catch (err) {
    console.error('❌ Failed!');
    console.error(err);
  } finally {
    await prisma.$disconnect();
    await pool.end();
  }
}

main();
