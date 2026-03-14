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

    // ── Employee-side fast-forward ────────────────────────────────────────────
    console.log('');
    console.log('Looking for nearest CONFIRMED and IN_PROGRESS appointments per employee...');

    const employees = await prisma.appointment.findMany({
        where: {
            barberId: { not: null },
            status: { in: ['CONFIRMED', 'IN_PROGRESS'] },
        },
        select: { barberId: true },
        distinct: ['barberId'],
        orderBy: { barberId: 'asc' },
    });

    let employeeConfirmedUpdates = 0;
    let employeeInProgressUpdates = 0;

    for (const { barberId } of employees) {
        if (!barberId) continue;

        // Fast-forward employee's first CONFIRMED appointment
        const empConfirmedApt = await prisma.appointment.findFirst({
            where: { barberId, status: 'CONFIRMED' },
            orderBy: { appointmentDate: 'asc' },
        });

        if (empConfirmedApt) {
            await prisma.appointment.update({
                where: { id: empConfirmedApt.id },
                data: { appointmentDate: now },
            });
            employeeConfirmedUpdates += 1;
            console.log(`[Employee ${barberId}] Updated CONFIRMED appointment ID: ${empConfirmedApt.id}`);
        }

        // Fast-forward employee's first IN_PROGRESS appointment
        const empInProgressApt = await prisma.appointment.findFirst({
            where: { barberId, status: 'IN_PROGRESS' },
            orderBy: { appointmentDate: 'asc' },
        });

        if (empInProgressApt) {
            await prisma.appointment.update({
                where: { id: empInProgressApt.id },
                data: { estimatedEndTime: now },
            });
            employeeInProgressUpdates += 1;
            console.log(`[Employee ${barberId}] Updated IN_PROGRESS appointment ID: ${empInProgressApt.id}`);
        }
    }

    console.log('');
    console.log(`Done at ${now.toLocaleDateString()} ${timeLabel}`);
    console.log(`[Client] PENDING appointments updated:    ${pendingUpdates}`);
    console.log(`[Client] CONFIRMED appointments updated:  ${confirmedUpdates}`);
    console.log(`[Client] IN_PROGRESS appointments updated: ${inProgressUpdates}`);
    console.log(`[Employee] CONFIRMED appointments updated:  ${employeeConfirmedUpdates}`);
    console.log(`[Employee] IN_PROGRESS appointments updated: ${employeeInProgressUpdates}`);
    console.log('Go check the app now. In about 1 minute, status-based actions should be visible.');
}

main()
    .catch(console.error)
    .finally(async () => {
        await prisma.$disconnect();
    });
