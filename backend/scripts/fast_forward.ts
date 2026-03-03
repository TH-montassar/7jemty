import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log("Looking for nearest CONFIRMED appointment...");

    // Find the nearest confirmed appointment
    const apt = await prisma.appointment.findFirst({
        where: { status: 'CONFIRMED' },
        orderBy: { appointmentDate: 'asc' },
    });

    if (!apt) {
        console.log("No confirmed appointments found.");
        return;
    }

    // Set time to 1 minute from now
    const now = new Date();
    now.setMinutes(now.getMinutes() + 1);

    const startTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;

    await prisma.appointment.update({
        where: { id: apt.id },
        data: {
            appointmentDate: now,
            startTime: startTime,
        },
    });

    console.log(`\n✅ Updated appointment ID: ${apt.id}`);
    console.log(`✅ New Date: ${now.toLocaleDateString()}`);
    console.log(`✅ New Time: ${startTime}`);
    console.log(`\nGo check the app now! In 1 minute, the button should appear and you should get a notification.`);
}

main()
    .catch(console.error)
    .finally(async () => {
        await prisma.$disconnect();
    });
