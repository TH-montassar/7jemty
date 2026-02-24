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