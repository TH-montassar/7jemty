import 'dotenv/config';
import { PrismaClient } from '../generated/prisma/index.js';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';
import { normalizeDatabaseUrl } from '../src/lib/normalizeDatabaseUrl.js';
const { Pool } = pg;
const pool = new Pool({ connectionString: normalizeDatabaseUrl(process.env.DATABASE_URL) });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });
async function main() {
    console.log('🧹 Starting Cleanup of Demo Data...');
    // Identify users created by the seed script (@7jemty.tn or specialized names)
    // We'll use the email domain @7jemty.tn as the primary identifier.
    const demoUsers = await prisma.user.findMany({
        where: {
            profile: {
                email: {
                    endsWith: '@7jemty.tn'
                }
            }
        },
        select: { id: true, fullName: true, role: true }
    });
    if (demoUsers.length === 0) {
        console.log('✨ No demo users found with @7jemty.tn domain.');
        return;
    }
    console.log(`🔍 Found ${demoUsers.length} demo users to delete.`);
    // To avoid foreign key issues, we'll delete in order:
    // 1. Appointments & associated data (Services, Faults, Reviews)
    // 2. Salons & associated data (Services, WorkingHours, etc.) -> Many are Cascade
    // 3. User Profiles & Users
    const userIds = demoUsers.map(u => u.id);
    // Find salons owned by these patrons
    const demoSalons = await prisma.salon.findMany({
        where: {
            patronId: { in: userIds }
        },
        select: { id: true, name: true }
    });
    const salonIds = demoSalons.map(s => s.id);
    console.log(`🗑️ Deleting ${demoSalons.length} demo salons...`);
    // Deleting Appointments first (they reference both Users and Salons)
    await prisma.appointment.deleteMany({
        where: {
            OR: [
                { clientId: { in: userIds } },
                { salonId: { in: salonIds } },
                { barberId: { in: userIds } }
            ]
        }
    });
    // Delete Salons (Cascade handles Services, WorkingHours, etc.)
    await prisma.salon.deleteMany({
        where: {
            id: { in: salonIds }
        }
    });
    // Delete Users (Cascade handles Profile, etc.)
    await prisma.user.deleteMany({
        where: {
            id: { in: userIds }
        }
    });
    console.log('✅ Cleanup completed successfully!');
}
main()
    .catch((e) => {
    console.error('❌ Cleanup failed:', e);
    process.exit(1);
})
    .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
});
//# sourceMappingURL=cleanup_demo_data.js.map