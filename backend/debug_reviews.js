import { PrismaClient } from './src/generated/prisma/index.js';
const prisma = new PrismaClient();

async function main() {
    const reviews = await prisma.review.findMany({
        include: {
            client: true,
            salon: true,
        },
        orderBy: { createdAt: 'desc' },
        take: 5
    });
    console.log(JSON.stringify(reviews, null, 2));
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
