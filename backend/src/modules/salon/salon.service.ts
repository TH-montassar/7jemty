import { prisma } from '../../lib/db.js';

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
    });

    if (!salon) {
        throw new Error("Salon introuvable");
    }

    return salon;
};