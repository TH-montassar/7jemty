import { prisma } from '../../lib/db.js';
import bcrypt from 'bcryptjs';
import { Role } from '../../../generated/prisma/index.js';

export const createSalon = async (patronId: number, data: any) => {
    // 1. Nthabtou ken l'Patron hetha 3andou salon deja (bech ma yasna3ch 2 salons)
    const existingSalon = await prisma.salon.findFirst({
        where: { patronId: patronId },
    });

    if (existingSalon) {
        throw new Error('3andek salon deja m9ayed fel system');
    }

    // 2. Nasn3ou e-salon
    const newSalon = await prisma.salon.create({
        data: {
            name: data.name,
            address: data.address,
            patronId: patronId, // 👈 Narbtou l'salon bel Patron mta3ou
        },
    });

    return newSalon;
};

export const updateSalon = async (patronId: number, data: any) => {
    // Nthabtou ken l'Patron 3andou salon 9bal ma nbadlou fih
    const existingSalon = await prisma.salon.findFirst({
        where: { patronId: patronId },
    });

    if (!existingSalon) {
        throw new Error("Ma 3andekch salon bech tbadlou");
    }

    // Nbadlou l'données eli jew fel request
    const updatedSalon = await prisma.salon.update({
        where: { id: existingSalon.id },
        data: {
            description: data.description !== undefined ? data.description : existingSalon.description,
            contactPhone: data.contactPhone !== undefined ? data.contactPhone : existingSalon.contactPhone,
        },
    });

    return updatedSalon;
};

export const getSalonByPatronId = async (patronId: number) => {
    const salon = await prisma.salon.findFirst({
        where: { patronId: patronId },
        include: {
            employees: true // Nraj3ou m3ah les employées
        }
    });

    if (!salon) {
        throw new Error("Salon introuvable");
    }

    return salon;
};

export const createEmployeeAccount = async (patronId: number, data: any) => {
    // 1. Nthabtou l'patron 3andou salon bech nzidoulou sona3
    const salon = await prisma.salon.findFirst({
        where: { patronId: patronId },
    });

    if (!salon) {
        throw new Error("Lazem ykoun 3andek salon bech tzid personnel");
    }

    // 2. Nthabtou ken nomrou teflon mta3 employé mouch msta3mel 9bal
    const existingUser = await prisma.user.findUnique({
        where: { phoneNumber: data.phoneNumber }
    });

    if (existingUser) {
        throw new Error("Nomrou hetha mawjoud deja fi system");
    }

    // 3. Nchafrou l mot de passe
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(data.password, salt);

    // 4. Nasn3ou l'User wel Employee f nafs l wa9t (Transaction)
    const result = await prisma.$transaction(async (tx) => {
        // A. Nasn3ou l'User b role EMPLOYEE
        const newUser = await tx.user.create({
            data: {
                phoneNumber: data.phoneNumber,
                passwordHash: passwordHash,
                fullName: data.name,
                role: Role.EMPLOYEE,
                workplaceSalonId: salon.id // Nrabtouha direct b salon l patron
            }
        });

        // B. Nasn3ou l'Employee bech yodh-hor fel salon profile
        const newEmployee = await tx.employee.create({
            data: {
                salonId: salon.id,
                name: data.name,
                role: data.role || 'Spécialiste',
                bio: data.bio || null,
                description: data.description || null,
                imageUrl: data.imageUrl || null
            }
        });

        return { user: newUser, employee: newEmployee };
    });

    return result.employee; // Nraj3ou ken donnés l'employé lel frontend
};