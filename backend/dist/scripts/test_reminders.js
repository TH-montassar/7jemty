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
    console.log('Looking for nearest PENDING and CONFIRMED appointments per client/employee to test reminders...');
    console.log('  +30m   → APPT_REMINDER_30M (30-min reminder)');
    console.log('  +3h    → APPT_CLIENT_LOCK_LT_1H (cancellation lock: ≤ 3h)');
    console.log('  +3h10m → APPT_REMINDER_1H10_CLIENT (pre-lock warning at exactly 3h10m)');
    const clients = await prisma.appointment.findMany({
        where: {
            status: {
                in: ['PENDING', 'CONFIRMED'],
            },
        },
        select: {
            clientId: true,
        },
        distinct: ['clientId'],
        orderBy: {
            clientId: 'asc',
        },
    });
    if (clients.length === 0) {
        console.log('No pending or confirmed appointments found.');
        return;
    }
    const now = new Date();
    const thirtyNow = new Date(now);
    thirtyNow.setMinutes(thirtyNow.getMinutes() + 30);
    const threeHourNow = new Date(now);
    threeHourNow.setMinutes(threeHourNow.getMinutes() + 180); // 3h → triggers APPT_CLIENT_LOCK_LT_1H
    const threeHourTenNow = new Date(now);
    threeHourTenNow.setMinutes(threeHourTenNow.getMinutes() + 190); // 3h10m → triggers APPT_REMINDER_1H10_CLIENT
    const timeLabel = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
    let thirtyUpdates = 0;
    let threeHourUpdates = 0;
    let threeHourTenUpdates = 0;
    let clientApptCounter = 0;
    for (const clientObj of clients) {
        if (!clientObj || clientObj.clientId === null)
            continue;
        const clientId = clientObj.clientId;
        // Fetch first 3 appointments for this client
        const appointments = await prisma.appointment.findMany({
            where: {
                clientId,
                status: { in: ['PENDING', 'CONFIRMED'] },
            },
            orderBy: { appointmentDate: 'asc' },
            take: 3,
        });
        for (const appointment of appointments) {
            const typeIndex = clientApptCounter % 3;
            clientApptCounter++;
            let targetTime = thirtyNow;
            let typeLabel = '+30m';
            if (typeIndex === 1) {
                targetTime = threeHourNow;
                typeLabel = '+3h';
                threeHourUpdates++;
            }
            else if (typeIndex === 2) {
                targetTime = threeHourTenNow;
                typeLabel = '+3h10m';
                threeHourTenUpdates++;
            }
            else {
                thirtyUpdates++;
            }
            // Reset reminder flags so they can trigger again
            await prisma.appointment.update({
                where: { id: appointment.id },
                data: {
                    appointmentDate: targetTime,
                    is1hReminderSent: false,
                    is10mReminderSent: false,
                },
            });
            console.log(`[Client ${clientId}] Updated appointment ID: ${appointment.id} to ${typeLabel}`);
        }
    }
    // ── Employee-side reminder test ───────────────────────────────────────────
    console.log('');
    console.log('Looking for nearest CONFIRMED appointments per employee to test reminders...');
    const employees = await prisma.appointment.findMany({
        where: {
            barberId: { not: null },
            status: { in: ['PENDING', 'CONFIRMED'] },
        },
        select: { barberId: true },
        distinct: ['barberId'],
        orderBy: { barberId: 'asc' },
    });
    let empThirtyUpdates = 0;
    let empHourUpdates = 0;
    let empHourTenUpdates = 0;
    let empApptCounter = 0;
    for (const empObj of employees) {
        if (!empObj || empObj.barberId === null)
            continue;
        const barberId = empObj.barberId;
        // Fetch first 3 appointments for this employee
        const appointments = await prisma.appointment.findMany({
            where: {
                barberId,
                status: { in: ['PENDING', 'CONFIRMED'] },
            },
            orderBy: { appointmentDate: 'asc' },
            take: 3,
        });
        for (const appointment of appointments) {
            const typeIndex = empApptCounter % 3;
            empApptCounter++;
            let targetTime = thirtyNow;
            let typeLabel = '+30m';
            if (typeIndex === 1) {
                targetTime = threeHourNow;
                typeLabel = '+3h';
                empHourUpdates++;
            }
            else if (typeIndex === 2) {
                targetTime = threeHourTenNow;
                typeLabel = '+3h10m';
                empHourTenUpdates++;
            }
            else {
                empThirtyUpdates++;
            }
            await prisma.appointment.update({
                where: { id: appointment.id },
                data: {
                    appointmentDate: targetTime,
                    is1hReminderSent: false,
                    is10mReminderSent: false,
                },
            });
            console.log(`[Employee ${barberId}] Updated appointment ID: ${appointment.id} to ${typeLabel}`);
        }
    }
    console.log('');
    console.log(`Done at ${now.toLocaleDateString()} ${timeLabel}`);
    console.log(`[Client]   +30m: ${thirtyUpdates}  |  +3h: ${threeHourUpdates}  |  +3h10m: ${threeHourTenUpdates}`);
    console.log(`[Employee] +30m: ${empThirtyUpdates}  |  +3h: ${empHourUpdates}  |  +3h10m: ${empHourTenUpdates}`);
    console.log('In about 1 minute, the background cron job should trigger their respective notifications.');
}
main()
    .catch(console.error)
    .finally(async () => {
    await prisma.$disconnect();
});
//# sourceMappingURL=test_reminders.js.map