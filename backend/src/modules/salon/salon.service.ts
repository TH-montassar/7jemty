import { prisma } from '../../lib/db.js';
import bcrypt from 'bcryptjs';
import { Role } from '../../../generated/prisma/index.js';
import { sendNotification } from '../notifications/notifications.service.js';

export const createSalon = async (patronId: number, data: any) => {
    // 1. Nthabtou ken l'Patron hetha 3andou salon deja (bech ma yasna3ch 2 salons)
    const existingSalon = await prisma.salon.findFirst({
        where: { patronId: patronId },
    });

    if (existingSalon) {
        throw new Error('3andek salon deja m9ayed fel system');
    }

    const randomRating = parseFloat((Math.random() * (5.0 - 3.5) + 3.5).toFixed(1));

    // 2. Nasn3ou e-salon
    const newSalon = await prisma.salon.create({
        data: {
            name: data.name,
            address: data.address,
            latitude: data.latitude, // <-- Save latitude
            longitude: data.longitude, // <-- Save longitude
            googleMapsUrl: data.googleMapsUrl, // <-- Save fields from new onboarding
            speciality: data.speciality,
            rating: randomRating,
            patronId: patronId, // 👈 Narbtou l'salon bel Patron mta3ou
        },
    });

    // Notify all ADMIN users
    const admins = await prisma.user.findMany({
        where: { role: Role.ADMIN },
        include: { profile: true }
    });

    for (const admin of admins) {
        await prisma.notification.create({
            data: {
                userId: admin.id,
                title: "Nouveau salon",
                body: `Le salon "${newSalon.name}" est en attente d'approbation.`
            }
        });
        if (admin.profile?.fcmToken) {
            await sendNotification(
                admin.profile.fcmToken,
                "Nouveau salon",
                `Le salon "${newSalon.name}" est en attente d'approbation.`,
                { type: 'NEW_SALON', salonId: newSalon.id.toString() }
            );
        }
    }

    return newSalon;
};

export const updateSalon = async (patronId: number, data: any) => {
    const existingSalon = await prisma.salon.findFirst({
        where: { patronId: patronId },
    });

    if (!existingSalon) {
        throw new Error("Ma 3andekch salon bech tbadlou");
    }

    const salonId = existingSalon.id;

    // Update main salon fields
    const updatedSalon = await prisma.salon.update({
        where: { id: salonId },
        data: {
            ...(data.name !== undefined && { name: data.name }),
            ...(data.description !== undefined && { description: data.description }),
            ...(data.contactPhone !== undefined && { contactPhone: data.contactPhone }),
            ...(data.address !== undefined && { address: data.address }),
            ...(data.latitude !== undefined && { latitude: data.latitude }),
            ...(data.longitude !== undefined && { longitude: data.longitude }),
            ...(data.googleMapsUrl !== undefined && { googleMapsUrl: data.googleMapsUrl }),
            ...(data.websiteUrl !== undefined && { websiteUrl: data.websiteUrl }),
            ...(data.coverImageUrl !== undefined && { coverImageUrl: data.coverImageUrl }),
            ...(data.speciality !== undefined && { speciality: data.speciality }),
        },
    });

    // Handle social links: delete all then re-insert
    if (data.socialLinks !== undefined) {
        await prisma.salonSocialLink.deleteMany({ where: { salonId } });
        if (data.socialLinks.length > 0) {
            await prisma.salonSocialLink.createMany({
                data: data.socialLinks.map((link: { platform: string; url: string }) => ({
                    salonId,
                    platform: link.platform,
                    url: link.url,
                })),
            });
        }
    }

    return updatedSalon;
};


export const getSalonByPatronId = async (patronId: number) => {
    const salon = await prisma.salon.findFirst({
        where: { patronId: patronId },
        include: {
            employees: {
                include: {
                    profile: true
                }
            },
            socialLinks: true,
            services: true,
            workingHours: true,
            portfolio: true,
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
    // 1. Nthabtou l'patron 3andou salon bech nzidoulou sona3 (if no salonId is provided)
    let salonIdToUse = data.salonId;
    if (!salonIdToUse) {
        const salon = await prisma.salon.findFirst({
            where: { patronId: patronId },
        });

        if (!salon) {
            throw new Error("Lazem ykoun 3andek salon bech tzid personnel");
        }
        salonIdToUse = salon.id;
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

    // 4. Nasn3ou l'User wel Profile f nafs l wa9t (Nested Write - Atomic by default)
    const newUser = await prisma.user.create({
        data: {
            phoneNumber: data.phoneNumber,
            passwordHash: passwordHash,
            fullName: data.name,
            role: Role.EMPLOYEE,
            workplaceSalonId: salonIdToUse, // Nrabtouha direct b salon l patron

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

    // Nraj3ouha f nafs l format eli yestanna fih l frontend
    return {
        id: newUser.id,
        userId: newUser.id,
        salonId: salonIdToUse,
        name: newUser.fullName,
        role: data.role || 'Spécialiste',
        bio: data.bio || null,
        description: data.description || null,
        imageUrl: data.imageUrl || null,
        createdAt: newUser.createdAt
    };
};

export const getAllSalons = async (lat?: number, lng?: number, includeUnapproved: boolean = false) => {
    // Njibou tous les salons men base de données
    const salons = await prisma.salon.findMany({
        where: !includeUnapproved ? { approvalStatus: 'APPROVED' } : {},
    });

    // Ken 3ana les coordonnées mta3 el client, n7esbou el distance (en km mthln)
    let salonsWithDistance = salons.map(salon => {
        let distance: string | null = null;
        if (lat && lng && salon.latitude && salon.longitude) {
            // Calcul basique de distance Haversine
            const R = 6371; // Rayon de la terre en km
            const dLat = (salon.latitude - lat) * (Math.PI / 180);
            const dLon = (salon.longitude - lng) * (Math.PI / 180);
            const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(lat * (Math.PI / 180)) * Math.cos(salon.latitude * (Math.PI / 180)) *
                Math.sin(dLon / 2) * Math.sin(dLon / 2);
            const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
            const _distance = R * c;
            distance = _distance.toFixed(1) + ' km';
        }

        return {
            ...salon,
            distance: distance,
            // l'app yesta3mel 'image' ltaw fi mocked data, nejmou nraj3ou coverImageUrl 
            image: salon.coverImageUrl || 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=500&q=80',
            // Default rating for now, or you can calculate if reviews relation is added
            rating: (salon as any).rating ? ((salon as any).rating as number).toFixed(1) : "4.5"
        };
    });

    // Ken distance mawjouda lel salons lkol wella partie menhom, nratbouhom (Ascendant)
    if (lat && lng) {
        salonsWithDistance.sort((a, b) => {
            if (!a.distance && !b.distance) return 0;
            if (!a.distance) return 1;
            if (!b.distance) return -1;
            return parseFloat(a.distance) - parseFloat(b.distance);
        });
    }

    return salonsWithDistance;
};

export const createService = async (patronId: number, data: any) => {
    let salonIdToUse = data.salonId;
    if (!salonIdToUse) {
        const salon = await prisma.salon.findFirst({
            where: { patronId: patronId },
        });

        if (!salon) {
            throw new Error("Lazem ykoun 3andek salon bech tzid service");
        }
        salonIdToUse = salon.id;
    }

    const newService = await prisma.service.create({
        data: {
            salonId: salonIdToUse,
            name: data.name,
            description: data.description || null,
            price: data.price,
            durationMinutes: data.durationMinutes,
            imageUrl: data.imageUrl || null,
        },
    });

    return newService;
};

export const getServices = async (patronId: number) => {
    const salon = await prisma.salon.findFirst({
        where: { patronId: patronId },
    });

    if (!salon) {
        throw new Error("Salon introuvable");
    }

    const services = await prisma.service.findMany({
        where: { salonId: salon.id },
    });

    return services;
};

export const getSalonById = async (id: number) => {
    const salon = await prisma.salon.findUnique({
        where: { id },
        include: {
            patron: {
                include: { profile: true }
            },
            services: true,
            employees: {
                include: {
                    profile: true,
                }
            },
            socialLinks: true,
            workingHours: true,
            portfolio: true,
            reviews: {
                include: {
                    client: {
                        include: { profile: true }
                    }
                },
                orderBy: { createdAt: 'desc' }
            }
        },
    });

    if (!salon) {
        throw new Error(`Salon avec l'ID ${id} introuvable`);
    }

    const formattedEmployees = salon.employees.map(emp => ({
        id: emp.id,
        userId: emp.id,
        salonId: salon.id,
        name: emp.fullName,
        role: emp.profile?.specialityTitle || 'Spécialiste',
        bio: emp.profile?.bio || null,
        description: emp.profile?.description || null,
        imageUrl: emp.profile?.avatarUrl || null,
        createdAt: emp.createdAt,
    }));

    const formattedReviews = salon.reviews.map(rev => ({
        id: rev.id,
        clientId: rev.clientId,
        clientName: rev.client.fullName,
        clientImage: rev.client.profile?.avatarUrl || null,
        rating: rev.rating,
        comment: rev.comment,
        createdAt: rev.createdAt,
    }));

    console.log(`[getSalonById] Finalizing response for Salon ${salon.id}. Reviews: ${formattedReviews.length}`);

    return {
        id: salon.id,
        patronId: salon.patronId,
        name: salon.name,
        description: salon.description,
        contactPhone: salon.contactPhone,
        address: salon.address,
        latitude: salon.latitude,
        longitude: salon.longitude,
        googleMapsUrl: salon.googleMapsUrl,
        websiteUrl: salon.websiteUrl,
        coverImageUrl: salon.coverImageUrl,
        speciality: salon.speciality,
        approvalStatus: salon.approvalStatus,
        isForceClosed: salon.isForceClosed,
        createdAt: salon.createdAt,
        patron: {
            id: salon.patron.id,
            name: salon.patron.fullName,
            imageUrl: salon.patron.profile?.avatarUrl || null,
        },
        services: salon.services,
        socialLinks: salon.socialLinks,
        workingHours: salon.workingHours,
        portfolio: salon.portfolio,
        employees: formattedEmployees,
        reviews: formattedReviews,
        image: salon.coverImageUrl || 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=500&q=80',
        rating: salon.rating ? (salon.rating as number).toFixed(1) : "4.5",
    };
};

export const getTopRatedSalons = async (limit: number = 10, includeUnapproved: boolean = false) => {
    const salons = await prisma.salon.findMany({
        where: !includeUnapproved ? { approvalStatus: 'APPROVED' } : {},
        orderBy: { rating: 'desc' } as any,
        take: limit,
        // Removed include: { services: true } to speed up startup
    });

    return salons.map(salon => ({
        ...salon,
        image: salon.coverImageUrl || 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=500&q=80',
        rating: (salon as any).rating ? ((salon as any).rating as number).toFixed(1) : "4.5",
    }));
};

export const searchSalons = async (query: string, includeUnapproved: boolean = false) => {
    const salons = await prisma.salon.findMany({
        where: {
            ...(!includeUnapproved ? { approvalStatus: 'APPROVED' } : {}),
            OR: [
                { name: { contains: query, mode: 'insensitive' } },
                { description: { contains: query, mode: 'insensitive' } },
                { services: { some: { name: { contains: query, mode: 'insensitive' } } } }
            ]
        },
        include: {
            services: true,
            workingHours: true,
        },
        take: 20, // Limit results for performance
    });

    return salons.map(salon => ({
        ...salon,
        image: salon.coverImageUrl || 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=500&q=80',
        rating: (salon as any).rating ? ((salon as any).rating as number).toFixed(1) : "4.5",
    }));
};