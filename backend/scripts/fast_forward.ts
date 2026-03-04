import 'dotenv/config';
import { PrismaClient } from '../generated/prisma/index.js';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';

const { Pool } = pg;
const pool = new Pool({ connectionString: process.env.DATABASE_URL! });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
    console.log("Looking for nearest CONFIRMED and IN_PROGRESS appointments...");

    // Find the nearest confirmed appointment
    const confirmedApt = await prisma.appointment.findFirst({
        where: { status: 'CONFIRMED' },
        orderBy: { appointmentDate: 'asc' },
    });

    // Find the nearest in-progress appointment
    const inProgressApt = await prisma.appointment.findFirst({
        where: { status: 'IN_PROGRESS' },
        orderBy: { appointmentDate: 'asc' },
    });

    if (!confirmedApt && !inProgressApt) {
        console.log("No confirmed or in-progress appointments found.");
        return;
    }

    const now = new Date();
    now.setMinutes(now.getMinutes() + 1);

    const startTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;

    if (confirmedApt) {
        // Fast forward start time
        await prisma.appointment.update({
            where: { id: confirmedApt.id },
            data: {
                appointmentDate: now,
            },
        });
        console.log(`\n✅ Updated CONFIRMED appointment ID: ${confirmedApt.id}`);
        console.log(`✅ New Start Date: ${now.toLocaleDateString()}`);
        console.log(`✅ New Start Time: ${startTime}`);
        console.log(`\nGo check the app now! In 1 minute, the start button should appear and you should get a notification.`);
    }

    if (inProgressApt) {
        // Fast forward end time
        await prisma.appointment.update({
            where: { id: inProgressApt.id },
            data: {
                estimatedEndTime: now,
            },
        });
        console.log(`\n✅ Updated IN_PROGRESS appointment ID: ${inProgressApt.id}`);
        console.log(`✅ New End Date: ${now.toLocaleDateString()}`);
        console.log(`✅ New End Time: ${startTime}`);
        console.log(`\nGo check the app now for the in-progress ride! In 1 minute, the completion prompt should trigger.`);
    }
}

main()
    .catch(console.error)
    .finally(async () => {
        await prisma.$disconnect();
    });
