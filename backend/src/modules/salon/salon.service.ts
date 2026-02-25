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
            employees: {
                include: {
                    profile: true // Nraj3ou profile bech njibou bio, description wel tsawer
                }
            }
        }
    });

    if (!salon) {
        throw new Error("Salon introuvable");
    }

    // Nbadlou el form mta3 el data bech yemchi m3a e-frontend elli yestanna { id, name, role, bio, imageUrl... }
    const formattedEmployees = salon.employees.map(emp => ({
        id: emp.id, // User id is now the employee id
        userId: emp.id,
        salonId: salon.id,
        name: emp.fullName,
        role: emp.profile?.specialityTitle || 'Spécialiste',
        bio: emp.profile?.bio || null,
        description: emp.profile?.description || null,
        imageUrl: emp.profile?.avatarUrl || null,
        createdAt: emp.createdAt
    }));

    return { ...salon, employees: formattedEmployees };
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

    // 4. Nasn3ou l'User wel Profile f nafs l wa9t (Transaction)
    const newUser = await prisma.$transaction(async (tx) => {
        // A. Nasn3ou l'User b role EMPLOYEE we nrabtouh b salon
        const user = await tx.user.create({
            data: {
                phoneNumber: data.phoneNumber,
                passwordHash: passwordHash,
                fullName: data.name,
                role: Role.EMPLOYEE,
                workplaceSalonId: salon.id, // Nrabtouha direct b salon l patron

                // B. Nasn3ou l'Profile f wist l'User (Nested Writes)
                profile: {
                    create: {
                        specialityTitle: data.role || 'Spécialiste',
                        bio: data.bio || null,
                        description: data.description || null,
                        avatarUrl: data.imageUrl || null
                    }
                }
            }
        });

        return user;
    });

    // Nraj3ouha f nafs l format eli yestanna fih l frontend
    return {
        id: newUser.id,
        userId: newUser.id,
        salonId: salon.id,
        name: newUser.fullName,
        role: data.role || 'Spécialiste',
        bio: data.bio || null,
        description: data.description || null,
        imageUrl: data.imageUrl || null,
        createdAt: newUser.createdAt
    };
};