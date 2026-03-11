import 'dotenv/config';
import { PrismaClient } from '../generated/prisma/index.js';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';
const { Pool } = pg;
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });
async function main() {
    console.log('Looking for nearest CONFIRMED and IN_PROGRESS appointments per client...');
    const clients = await prisma.appointment.findMany({
        where: {
            status: {
                in: ['PENDING', 'CONFIRMED', 'IN_PROGRESS'],
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
        console.log('No pending, confirmed or in-progress appointments found.');
        return;
    }
    const now = new Date();
    now.setMinutes(now.getMinutes() + 1);
    const pendingNow = new Date();
    pendingNow.setMinutes(pendingNow.getMinutes() + 61);
    const timeLabel = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
    let pendingUpdates = 0;
    let confirmedUpdates = 0;
    let inProgressUpdates = 0;
    for (const { clientId } of clients) {
        // Fast-forward PENDING
        const pendingApt = await prisma.appointment.findFirst({
            where: {
                clientId,
                status: 'PENDING',
            },
            orderBy: {
                appointmentDate: 'asc',
            },
        });
        if (pendingApt) {
            await prisma.appointment.update({
                where: {
                    id: pendingApt.id,
                },
                data: {
                    appointmentDate: pendingNow,
                },
            });
            pendingUpdates += 1;
            console.log(`[Client ${clientId}] Updated PENDING appointment ID: ${pendingApt.id} to +30mn`);
        }
        // Fast-forward CONFIRMED
        const confirmedApt = await prisma.appointment.findFirst({
            where: {
                clientId,
                status: 'CONFIRMED',
            },
            orderBy: {
                appointmentDate: 'asc',
            },
        });
        if (confirmedApt) {
            await prisma.appointment.update({
                where: {
                    id: confirmedApt.id,
                },
                data: {
                    appointmentDate: now,
                },
            });
            confirmedUpdates += 1;
            console.log(`[Client ${clientId}] Updated CONFIRMED appointment ID: ${confirmedApt.id}`);
        }
        const inProgressApt = await prisma.appointment.findFirst({
            where: {
                clientId,
                status: 'IN_PROGRESS',
            },
            orderBy: {
                appointmentDate: 'asc',
            },
        });
        if (inProgressApt) {
            await prisma.appointment.update({
                where: {
                    id: inProgressApt.id,
                },
                data: {
                    estimatedEndTime: now,
                },
            });
            inProgressUpdates += 1;
            console.log(`[Client ${clientId}] Updated IN_PROGRESS appointment ID: ${inProgressApt.id}`);
        }
    }
    console.log('');
    console.log(`Done at ${now.toLocaleDateString()} ${timeLabel}`);
    console.log(`PENDING appointments updated: ${pendingUpdates}`);
    console.log(`CONFIRMED appointments updated: ${confirmedUpdates}`);
    console.log(`IN_PROGRESS appointments updated: ${inProgressUpdates}`);
    console.log('Go check the app now. In about 1 minute, status-based actions should be visible.');
}
main()
    .catch(console.error)
    .finally(async () => {
    await prisma.$disconnect();
});
//# sourceMappingURL=fast_forward.js.map