import 'dotenv/config';
import bcrypt from 'bcryptjs';
import { PrismaClient, ApprovalStatus, Role } from '../generated/prisma/index.js';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';
import { normalizeDatabaseUrl } from '../src/lib/normalizeDatabaseUrl.js';
const { Pool } = pg;
const pool = new Pool({ connectionString: normalizeDatabaseUrl(process.env.DATABASE_URL) });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });
const CLIENT_COUNT = 10;
const PATRON_COUNT = 10;
const EMPLOYEES_PER_SALON = 10;
const SERVICES_PER_SALON = 10;
const DEFAULT_PASSWORD = '123456';
const TUNISIAN_MALE_NAMES = [
    'Ahmed', 'Mohamed', 'Ali', 'Yassine', 'Hamza', 'Skander', 'Montassar', 'Wael', 'Anis', 'Sami',
    'Mehdi', 'Zied', 'Fedi', 'Omar', 'Karim', 'Walid', 'Tarak', 'Hedi', 'Slim', 'Bassem'
];
const TUNISIAN_FEMALE_NAMES = [
    'Meriem', 'Olfa', 'Sarra', 'Ines', 'Rim', 'Sonia', 'Amira', 'Hela', 'Houda', 'Leila',
    'Salma', 'Nour', 'Eya', 'Fatma', 'Asma', 'Imen', 'Arij', 'Syrine', 'Soumaya', 'Nadia'
];
const SALON_NAMES = [
    'Golden Barber', 'Queen Beauty', 'Magic Hands', 'Style & More', 'The Groom Room',
    'Espace Elégance', 'L’Art de la Coupe', 'Sami Coiffure', 'Beauty Zone', 'Prestige Salon',
    'L’Escale Beauté', 'Silver Scissors', 'Modern Style', 'Royal Touch', 'Studio 7'
];
const TUNIS_AREAS = [
    { name: 'Lac I, Tunis', lat: 36.8329, lng: 10.2281 },
    { name: 'Ennasr II, Tunis', lat: 36.8580, lng: 10.1585 },
    { name: 'Centre Ville, Tunis', lat: 36.8065, lng: 10.1815 },
    { name: 'La Marsa, Tunis', lat: 36.8781, lng: 10.3247 },
    { name: 'Menzah IX, Tunis', lat: 36.8450, lng: 10.1750 }
];
const BARBER_IMAGES = [
    'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1512690194185-fb405367809a?auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1593702275677-f916c6c19266?auto=format&fit=crop&q=80'
];
const BEAUTY_IMAGES = [
    'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1527799822367-a233547f0ec4?auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1522335789183-b1500d70fef0?auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1620331311520-246422fd82f9?auto=format&fit=crop&q=80'
];
const SERVICE_IMAGES = {
    'Brushing simple': 'https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?auto=format&fit=crop&q=80',
    'Coupe femme': 'https://images.unsplash.com/photo-1595476108010-b4d1f80d91f2?auto=format&fit=crop&q=80',
    'Coloration racine': 'https://images.unsplash.com/photo-1605497788044-5a32c7078486?auto=format&fit=crop&q=80',
    'Manucure & Pédicure': 'https://images.unsplash.com/photo-1610992015732-2449b0c26670?auto=format&fit=crop&q=80',
    'Soin de visage complet': 'https://images.unsplash.com/photo-1570172619380-adb6955743f8?auto=format&fit=crop&q=80',
    'Coupe classique': 'https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&q=80',
    'Coupe dégradée': 'https://images.unsplash.com/photo-1622286332618-f280219c439c?auto=format&fit=crop&q=80',
    'Taille de barbe': 'https://images.unsplash.com/photo-1517832606299-7ae9b720a186?auto=format&fit=crop&q=80',
    'Rasage à l’ancienne': 'https://images.unsplash.com/photo-1533152680674-6b9fce293ade?auto=format&fit=crop&q=80',
    'Masque noir': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?auto=format&fit=crop&q=80'
};
const AVATAR_IMAGES = [
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80'
];
const COIFFEUSE_SERVICES = [
    { name: 'Brushing simple', price: 25, duration: 30 },
    { name: 'Brushing bouclé', price: 35, duration: 45 },
    { name: 'Coupe femme', price: 40, duration: 40 },
    { name: 'Coloration racine', price: 60, duration: 90 },
    { name: 'Mèches & Balayage', price: 150, duration: 180 },
    { name: 'Kératine / Protéine', price: 250, duration: 240 },
    { name: 'Soin de visage complet', price: 80, duration: 60 },
    { name: 'Maquillage soirée', price: 120, duration: 90 },
    { name: 'Manucure & Pédicure', price: 50, duration: 60 },
    { name: 'Épilation complète', price: 90, duration: 120 }
];
const BARBER_SERVICES = [
    { name: 'Coupe classique', price: 15, duration: 30 },
    { name: 'Coupe dégradée', price: 20, duration: 40 },
    { name: 'Taille de barbe', price: 10, duration: 20 },
    { name: 'Rasage à l’ancienne', price: 15, duration: 30 },
    { name: 'Soin barbe & visage', price: 25, duration: 40 },
    { name: 'Coupe enfant', price: 12, duration: 25 },
    { name: 'Coloration barbe', price: 20, duration: 30 },
    { name: 'Masque noir', price: 15, duration: 15 },
    { name: 'Contour & Finition', price: 5, duration: 10 },
    { name: 'Shampoing & Coiffage', price: 8, duration: 15 }
];
function pad2(value) {
    return value.toString().padStart(2, '0');
}
function makeRunToken() {
    return Date.now().toString().slice(-6);
}
function makePhone(prefix, runToken, ...parts) {
    const rawSuffix = `${runToken}${parts.map((p) => pad2(p)).join('')}`.replace(/\D/g, '');
    const suffix = rawSuffix.length >= 6 ? rawSuffix.slice(-6) : rawSuffix.padStart(6, '0');
    return `${prefix}${suffix}`;
}
function createWorkingHours() {
    return Array.from({ length: 7 }, (_, idx) => ({
        dayOfWeek: idx + 1,
        openTime: '09:00',
        closeTime: '20:00',
        isDayOff: idx === 6,
    }));
}
function getRandomLocation(base) {
    const r = 0.01; // approx 1km range
    return {
        lat: base.lat + (Math.random() - 0.5) * r,
        lng: base.lng + (Math.random() - 0.5) * r
    };
}
async function main() {
    const runToken = makeRunToken();
    console.log('🚀 Starting Seeding with Professional Tunisian Data (Schema Matched)...');
    const passwordHash = await bcrypt.hash(DEFAULT_PASSWORD, 10);
    // 1. Create Clients
    console.log('👥 Creating 10 Clients...');
    for (let i = 0; i < CLIENT_COUNT; i++) {
        const name = TUNISIAN_MALE_NAMES[i % TUNISIAN_MALE_NAMES.length];
        const baseArea = TUNIS_AREAS[i % TUNIS_AREAS.length];
        const loc = getRandomLocation(baseArea);
        await prisma.user.create({
            data: {
                fullName: `${name} Aloui`,
                phoneNumber: makePhone('22', runToken, i),
                passwordHash,
                role: Role.CLIENT,
                isVerified: true,
                profile: {
                    create: {
                        email: `client.${i}.${runToken}@7jemty.tn`,
                        address: baseArea.name,
                        latitude: loc.lat,
                        longitude: loc.lng,
                        avatarUrl: AVATAR_IMAGES[i % AVATAR_IMAGES.length] || null,
                    },
                },
            },
        });
    }
    // 2. Create Patrons, Salons, Employees and Services
    console.log('🏪 Creating 10 Salons with Specialists and Services...');
    for (let p = 0; p < PATRON_COUNT; p++) {
        const isBeautySalon = p % 2 === 1;
        const patronName = isBeautySalon
            ? TUNISIAN_FEMALE_NAMES[p % TUNISIAN_FEMALE_NAMES.length]
            : TUNISIAN_MALE_NAMES[(p + 10) % TUNISIAN_MALE_NAMES.length];
        const patron = await prisma.user.create({
            data: {
                fullName: `${patronName} Ben Ahmed`,
                phoneNumber: makePhone('55', runToken, p),
                passwordHash,
                role: Role.PATRON,
                isVerified: true,
                profile: {
                    create: {
                        email: `patron.${p}.${runToken}@7jemty.tn`,
                        avatarUrl: AVATAR_IMAGES[(p + 5) % AVATAR_IMAGES.length] || null,
                    },
                },
            },
        });
        const salonName = SALON_NAMES[p % SALON_NAMES.length];
        const baseArea = TUNIS_AREAS[p % TUNIS_AREAS.length];
        const loc = getRandomLocation(baseArea);
        const salon = await prisma.salon.create({
            data: {
                patronId: patron.id,
                name: isBeautySalon ? `${salonName} (Femme)` : `${salonName} (Homme)`,
                description: isBeautySalon
                    ? 'Centre de beauté haut de gamme spécialisé en coiffure femme, esthétique et soins.'
                    : 'Barbershop professionnel avec une expertise en coupe moderne et soin de barbe.',
                contactPhone: patron.phoneNumber,
                address: baseArea.name,
                latitude: loc.lat,
                longitude: loc.lng,
                coverImageUrl: (isBeautySalon
                    ? BEAUTY_IMAGES[p % BEAUTY_IMAGES.length]
                    : BARBER_IMAGES[p % BARBER_IMAGES.length]) || null,
                speciality: isBeautySalon ? 'Coiffure & Esthétique' : 'Barbier & Coiffure',
                approvalStatus: ApprovalStatus.APPROVED,
                rating: 4.0 + Math.random(),
                workingHours: { create: createWorkingHours() },
            },
        });
        // Create Employees (Specialists)
        const specialistTitles = isBeautySalon
            ? ['Experte Coloriste', 'Maquilleuse Pro', 'Esthéticienne', 'Spécialiste Kératine', 'Styliste Ongulaire']
            : ['Maître Barbier', 'Expert Coupe Homme', 'Spécialiste Barbe', 'Styliste Capillaire', 'Visagiste'];
        const employeeNames = isBeautySalon ? TUNISIAN_FEMALE_NAMES : TUNISIAN_MALE_NAMES;
        for (let e = 0; e < EMPLOYEES_PER_SALON; e++) {
            const eName = employeeNames[(e + p) % employeeNames.length];
            const title = specialistTitles[e % specialistTitles.length];
            await prisma.user.create({
                data: {
                    fullName: `${eName} Specialist`,
                    phoneNumber: makePhone('98', runToken, p, e),
                    passwordHash,
                    role: Role.EMPLOYEE,
                    isVerified: true,
                    workplaceSalonId: salon.id,
                    profile: {
                        create: {
                            bio: `Expert en ${isBeautySalon ? 'soins esthétiques' : 'coiffure masculine'} avec 5 ans d'expérience.`,
                            specialityTitle: title || null,
                            avatarUrl: AVATAR_IMAGES[(e + p + 10) % AVATAR_IMAGES.length] || null,
                        },
                    },
                },
            });
        }
        // Create Services
        const serviceTemplates = isBeautySalon ? COIFFEUSE_SERVICES : BARBER_SERVICES;
        const servicesToCreate = serviceTemplates.slice(0, SERVICES_PER_SALON);
        await prisma.service.createMany({
            data: servicesToCreate.map(s => ({
                salonId: salon.id,
                name: s.name,
                price: s.price,
                durationMinutes: s.duration,
                imageUrl: SERVICE_IMAGES[s.name] || null,
                description: `Service professionnel de ${s.name.toLowerCase()}.`,
            })),
        });
        console.log(`✅ Salon "${salon.name}" ready! (${EMPLOYEES_PER_SALON} Specialists, ${SERVICES_PER_SALON} Services)`);
    }
    console.log('\n✨ Seeding completed successfully!');
    console.log(`Access info: Passwords are all "${DEFAULT_PASSWORD}"`);
}
main()
    .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
})
    .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
});
//# sourceMappingURL=seed_demo_data.js.map