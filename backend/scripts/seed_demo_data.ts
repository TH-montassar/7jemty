import 'dotenv/config';
import bcrypt from 'bcryptjs';
import { PrismaClient, ApprovalStatus, Role } from '../generated/prisma/index.js';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';
import { normalizeDatabaseUrl } from '../src/lib/normalizeDatabaseUrl.js';

const { Pool } = pg;
const pool = new Pool({ connectionString: normalizeDatabaseUrl(process.env.DATABASE_URL!) });
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

function pad2(value: number): string {
  return value.toString().padStart(2, '0');
}

function makeRunToken(): string {
  return Date.now().toString().slice(-6);
}

function makePhone(prefix: string, runToken: string, ...parts: number[]): string {
  const rawSuffix = `${runToken}${parts.map((p) => pad2(p)).join('')}`.replace(/\D/g, '');
  const suffix = rawSuffix.length >= 6 ? rawSuffix.slice(-6) : rawSuffix.padStart(6, '0');
  return `${prefix}${suffix}`;
}

function createWorkingHours() {
  return Array.from({ length: 7 }, (_, idx) => ({
    dayOfWeek: idx + 1,
    openTime: '09:00',
    closeTime: '20:00',
    isDayOff: idx === 6, // Sunday off for some variety
  }));
}

async function main() {
  const runToken = makeRunToken();
  console.log('🚀 Starting Seeding with Professional Tunisian Data...');
  const passwordHash = await bcrypt.hash(DEFAULT_PASSWORD, 10);

  // 1. Create Clients
  console.log('👥 Creating 10 Clients...');
  for (let i = 0; i < CLIENT_COUNT; i++) {
    const name = TUNISIAN_MALE_NAMES[i % TUNISIAN_MALE_NAMES.length];
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
            address: `Avenue Habib Bourguiba, Tunis`,
          },
        },
      },
    });
  }

  // 2. Create Patrons, Salons, Employees and Services
  console.log('🏪 Creating 10 Salons with Specialists and Services...');
  for (let p = 0; p < PATRON_COUNT; p++) {
    const isBeautySalon = p % 2 === 1; // Alternate between Barber and Beauty
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
          },
        },
      },
    });

    const salonName = SALON_NAMES[p % SALON_NAMES.length];
    const salon = await prisma.salon.create({
      data: {
        patronId: patron.id,
        name: isBeautySalon ? `${salonName} (Femme)` : `${salonName} (Homme)`,
        description: isBeautySalon
          ? 'Centre de beauté haut de gamme spécialisé en coiffure femme, esthétique et soins.'
          : 'Barbershop professionnel avec une expertise en coupe moderne et soin de barbe.',
        contactPhone: patron.phoneNumber,
        address: isBeautySalon ? `Ennasr II, Tunis` : `Lac I, Tunis`,
        speciality: isBeautySalon ? 'Coiffure & Esthétique' : 'Barbier & Coiffure',
        approvalStatus: ApprovalStatus.APPROVED,
        workingHours: { create: createWorkingHours() },
      },
    });

    // Create Employees
    const employeeNames = isBeautySalon ? TUNISIAN_FEMALE_NAMES : TUNISIAN_MALE_NAMES;
    for (let e = 0; e < EMPLOYEES_PER_SALON; e++) {
      const eName = employeeNames[(e + p) % employeeNames.length];
      await prisma.user.create({
        data: {
          fullName: `${eName} Specialist`,
          phoneNumber: makePhone('98', runToken, p, e),
          passwordHash,
          role: Role.EMPLOYEE,
          isVerified: true,
          workplaceSalonId: salon.id,
          profile: {
            create: { bio: `Expert en ${isBeautySalon ? 'soins esthétiques' : 'coiffure masculine'} avec 5 ans d'expérience.` },
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
