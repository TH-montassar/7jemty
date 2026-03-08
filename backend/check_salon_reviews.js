import { PrismaClient } from './generated/prisma/index.js';
const prisma = new PrismaClient();

async function main() {
    const salon = await prisma.salon.findFirst({
        where: { name: { contains: 'Ibehi', mode: 'insensitive' } },
        include: {
            reviews: {
                include: { client: true }
            }
        }
    });

    if (salon) {
        console.log(`Found Salon: ${salon.name} (ID: ${salon.id})`);
        console.log(`Reviews count: ${salon.reviews.length}`);
        salon.reviews.forEach(r => {
            console.log(`- Review ID: ${r.id}, Rating: ${r.rating}, Comment: ${r.comment}, Client: ${r.client?.fullName}`);
        });
    } else {
        console.log('Salon not found');
    }
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
