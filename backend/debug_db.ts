import { prisma } from './src/lib/db.js';

async function main() {
    const salons = await prisma.salon.findMany({
        include: {
            _count: {
                select: { reviews: true }
            }
        }
    });

    console.log("--- SALONS ---");
    salons.forEach(s => {
        console.log(`ID: ${s.id}, Name: ${s.name}, Rating: ${s.rating}, Reviews Count: ${s._count.reviews}`);
    });

    const reviews = await prisma.review.findMany({
        include: {
            salon: { select: { name: true } }
        }
    });

    console.log("\n--- REVIEWS ---");
    reviews.forEach(r => {
        console.log(`ID: ${r.id}, SalonID: ${r.salonId} (${r.salon?.name}), Rating: ${r.rating}, Comment: ${r.comment}`);
    });
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
