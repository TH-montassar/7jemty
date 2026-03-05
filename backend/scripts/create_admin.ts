import { prisma } from '../src/lib/db.js';
import bcrypt from 'bcryptjs';

async function createAdmin() {
    const args = process.argv.slice(2);

    if (args.length < 3) {
        console.error('Usage: npm run create-admin -- <fullName> <phoneNumber> <password>');
        process.exit(1);
    }

    // Destructure and provide defaults or cast since we checked length
    const fullName = args[0] as string;
    const phoneNumber = args[1] as string;
    const password = args[2] as string;

    try {
        console.log(`Checking if user with phone ${phoneNumber} exists...`);
        const existingUser = await prisma.user.findUnique({
            where: { phoneNumber },
        });

        if (existingUser) {
            console.error(`Error: User with phone number ${phoneNumber} already exists.`);
            process.exit(1);
        }

        console.log('Hashing password...');
        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash(password, salt);

        console.log('Creating Admin user in database...');
        const user = await prisma.user.create({
            data: {
                fullName,
                phoneNumber,
                passwordHash,
                role: 'ADMIN',
                isVerified: true,
                profile: {
                    create: {
                        email: `${phoneNumber}@7jemty.com`, // Placeholder email
                    }
                }
            },
            include: {
                profile: true
            }
        });

        console.log('✅ Admin user created successfully!');
        console.log('User ID:', user.id);
        console.log('Full Name:', user.fullName);
        console.log('Phone:', user.phoneNumber);
        console.log('Role:', user.role);

    } catch (error) {
        console.error('❌ Failed to create admin user:', error);
    } finally {
        await prisma.$disconnect();
    }
}

createAdmin();
