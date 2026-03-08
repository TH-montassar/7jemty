import { prisma } from './src/lib/db.js';

async function main() {
    const salons = await prisma.salon.findMany();
    console.log(`Total salons: ${salons.length}`);
    salons.forEach(s => console.log(`- Salon ID: ${s.id}, Name: ${s.name}`));

    const reviews = await prisma.review.findMany({
        include: {
            client: true,
            salon: true
        }
    });

    console.log(`\nTotal reviews in DB: ${reviews.length}`);
    reviews.forEach(r => {
        console.log(`- Review ID: ${r.id}, Salon: ${r.salon?.name} (ID: ${r.salonId}), Rating: ${r.rating}, Client: ${r.client?.fullName}`);
    });
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
