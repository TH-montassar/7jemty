import 'dotenv/config';
import { PrismaClient } from '../generated/prisma/index.js';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';

const { Pool } = pg;
const pool = new Pool({ connectionString: process.env.DATABASE_URL! });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
    console.log('Looking for nearest PENDING and CONFIRMED appointments per client to test reminders...');

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

    const hourNow = new Date(now);
    hourNow.setMinutes(hourNow.getMinutes() + 60);

    const hourTenNow = new Date(now);
    hourTenNow.setMinutes(hourTenNow.getMinutes() + 70);

    const timeLabel = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;

    let thirtyUpdates = 0;
    let hourUpdates = 0;
    let hourTenUpdates = 0;

    for (let i = 0; i < clients.length; i++) {
        const { clientId } = clients[i];

        // We will distribute the clients to test the different reminders
        const typeIndex = i % 3;

        const appointment = await prisma.appointment.findFirst({
            where: {
                clientId,
                status: {
                    in: ['PENDING', 'CONFIRMED']
                }
            },
            orderBy: {
                appointmentDate: 'asc',
            },
        });

        if (appointment) {
            let targetTime = thirtyNow;
            let typeLabel = '+30m';

            if (typeIndex === 1) {
                targetTime = hourNow;
                typeLabel = '+1h';
                hourUpdates++;
            } else if (typeIndex === 2) {
                targetTime = hourTenNow;
                typeLabel = '+1h10m';
                hourTenUpdates++;
            } else {
                thirtyUpdates++;
            }

            // Reset reminder flags so they can trigger again
            await prisma.appointment.update({
                where: {
                    id: appointment.id,
                },
                data: {
                    appointmentDate: targetTime,
                    is1hReminderSent: false,
                    is10mReminderSent: false
                },
            });
            console.log(`[Client ${clientId}] Updated appointment ID: ${appointment.id} to ${typeLabel}`);
        }
    }

    console.log('');
    console.log(`Done at ${now.toLocaleDateString()} ${timeLabel}`);
    console.log(`Appointments updated to +30m: ${thirtyUpdates}`);
    console.log(`Appointments updated to +1h: ${hourUpdates}`);
    console.log(`Appointments updated to +1h10m: ${hourTenUpdates}`);
    console.log('In about 1 minute, the background cron job should trigger their respective notifications.');
}

main()
    .catch(console.error)
    .finally(async () => {
        await prisma.$disconnect();
    });
