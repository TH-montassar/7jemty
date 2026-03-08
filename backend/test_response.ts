import { prisma } from './src/lib/db.js';

// Simulates what getSalonById returns
async function main() {
    const id = 1; // Change this to the salon ID you're viewing

    const salon = await prisma.salon.findUnique({
        where: { id },
        include: {
            patron: { include: { profile: true } },
            services: true,
            employees: { include: { profile: true } },
            socialLinks: true,
            workingHours: true,
            portfolio: true,
            reviews: {
                include: { client: { include: { profile: true } } },
                orderBy: { createdAt: 'desc' }
            }
        }
    });

    if (!salon) {
        console.log('Salon NOT FOUND');
        return;
    }

    const formattedReviews = salon.reviews.map(rev => ({
        id: rev.id,
        clientId: rev.clientId,
        clientName: rev.client.fullName,
        clientImage: rev.client.profile?.avatarUrl || null,
        rating: rev.rating,
        comment: rev.comment,
        createdAt: rev.createdAt,
    }));

    const response = {
        id: salon.id,
        name: salon.name,
        rating: salon.rating ? (salon.rating as number).toFixed(1) : "4.5",
        reviews: formattedReviews,
    };

    console.log("=== API RESPONSE (simplified) ===");
    console.log(JSON.stringify(response, null, 2));
    console.log(`\n✅ Reviews count: ${formattedReviews.length}`);
}

main().catch(console.error).finally(() => prisma.$disconnect());
