import { prisma } from '../../lib/db.js';
import bcrypt from 'bcryptjs';
import { AppointmentStatus, Role } from '../../../generated/prisma/index.js';
import { sendNotification } from '../notifications/notifications.service.js';

const getSalonIdByPatronId = async (patronId: number): Promise<number> => {
    const salon = await prisma.salon.findFirst({
        where: { patronId },
        select: { id: true }
    });

    if (!salon) {
        throw new Error("Lazem ykoun 3andek salon bech tmodifi les specialistes");
    }

    return salon.id;
};

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
            latitude: data.latitude, // <-- Save latitude
            longitude: data.longitude, // <-- Save longitude
            googleMapsUrl: data.googleMapsUrl, // <-- Save fields from new onboarding
            speciality: data.speciality,
            rating: 0,
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

    // Handle working hours: delete all then re-insert
    if (data.workingHours !== undefined) {
        await prisma.workingHours.deleteMany({ where: { salonId } });
        if (data.workingHours.length > 0) {
            await prisma.workingHours.createMany({
                data: data.workingHours.map((wh: any) => ({
                    salonId,
                    dayOfWeek: wh.dayOfWeek,
                    openTime: wh.openTime,
                    closeTime: wh.closeTime,
                    isDayOff: wh.isDayOff ?? false,
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
            reviews: {
                include: {
                    client: {
                        include: { profile: true }
                    }
                },
                orderBy: { createdAt: 'desc' }
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
        phoneNumber: emp.phoneNumber,
        role: emp.profile?.specialityTitle || 'Spécialiste',
        bio: emp.profile?.bio || null,
        description: emp.profile?.description || null,
        imageUrl: emp.profile?.avatarUrl || null,
        createdAt: emp.createdAt
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

    const formattedRating = formattedReviews.length > 0 && typeof salon.rating === 'number'
        ? salon.rating.toFixed(1)
        : "0.0";

    return { ...salon, employees: formattedEmployees, reviews: formattedReviews, rating: formattedRating };
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
        phoneNumber: newUser.phoneNumber,
        role: data.role || 'Spécialiste',
        bio: data.bio || null,
        description: data.description || null,
        imageUrl: data.imageUrl || null,
        createdAt: newUser.createdAt
    };
};

export const updateEmployeeAccount = async (patronId: number, employeeId: number, data: any) => {
    const salonId = await getSalonIdByPatronId(patronId);

    const employee = await prisma.user.findFirst({
        where: {
            id: employeeId,
            role: Role.EMPLOYEE,
            workplaceSalonId: salonId
        },
        include: { profile: true }
    });

    if (!employee) {
        throw new Error("Specialiste introuvable ou mouch mta3 salonek");
    }

    if (data.phoneNumber !== undefined && data.phoneNumber !== employee.phoneNumber) {
        const existingUser = await prisma.user.findUnique({
            where: { phoneNumber: data.phoneNumber }
        });

        if (existingUser && existingUser.id !== employeeId) {
            throw new Error("Nomrou hetha mawjoud deja fi system");
        }
    }

    const shouldUpdateProfile = data.role !== undefined ||
        data.bio !== undefined ||
        data.description !== undefined ||
        data.imageUrl !== undefined;

    let newPasswordHash: string | undefined;
    if (typeof data.password === 'string' && data.password.trim() !== '') {
        const salt = await bcrypt.genSalt(10);
        newPasswordHash = await bcrypt.hash(data.password, salt);
    }

    const updatedEmployee = await prisma.user.update({
        where: { id: employeeId },
        data: {
            ...(data.name !== undefined && { fullName: data.name }),
            ...(data.phoneNumber !== undefined && { phoneNumber: data.phoneNumber }),
            ...(newPasswordHash !== undefined && { passwordHash: newPasswordHash }),
            ...(shouldUpdateProfile && {
                profile: {
                    upsert: {
                        update: {
                            ...(data.role !== undefined && { specialityTitle: data.role }),
                            ...(data.bio !== undefined && { bio: data.bio }),
                            ...(data.description !== undefined && { description: data.description }),
                            ...(data.imageUrl !== undefined && { avatarUrl: data.imageUrl })
                        },
                        create: {
                            specialityTitle: data.role ?? 'Spécialiste',
                            bio: data.bio ?? null,
                            description: data.description ?? null,
                            avatarUrl: data.imageUrl ?? null
                        }
                    }
                }
            })
        },
        include: { profile: true }
    });

    return {
        id: updatedEmployee.id,
        userId: updatedEmployee.id,
        salonId,
        name: updatedEmployee.fullName,
        phoneNumber: updatedEmployee.phoneNumber,
        role: updatedEmployee.profile?.specialityTitle || 'Spécialiste',
        bio: updatedEmployee.profile?.bio || null,
        description: updatedEmployee.profile?.description || null,
        imageUrl: updatedEmployee.profile?.avatarUrl || null,
        createdAt: updatedEmployee.createdAt
    };
};

export const removeEmployeeFromSalon = async (patronId: number, employeeId: number) => {
    const salonId = await getSalonIdByPatronId(patronId);

    const employee = await prisma.user.findFirst({
        where: {
            id: employeeId,
            role: Role.EMPLOYEE,
            workplaceSalonId: salonId
        },
        select: { id: true }
    });

    if (!employee) {
        throw new Error("Specialiste introuvable ou mouch mta3 salonek");
    }

    const activeAppointmentsCount = await prisma.appointment.count({
        where: {
            salonId,
            barberId: employeeId,
            status: {
                in: [
                    AppointmentStatus.PENDING,
                    AppointmentStatus.CONFIRMED,
                    AppointmentStatus.IN_PROGRESS,
                    AppointmentStatus.ARRIVED
                ]
            }
        }
    });

    if (activeAppointmentsCount > 0) {
        throw new Error("Specialiste 3andou rendez-vous actifs. Badelhom 9bal suppression.");
    }

    await prisma.user.update({
        where: { id: employeeId },
        data: {
            workplaceSalonId: null,
            role: Role.CLIENT
        }
    });

    return { id: employeeId, removed: true };
};

export const getAllSalons = async (lat?: number, lng?: number, includeUnapproved: boolean = false) => {
    // Njibou tous les salons men base de données
    const salons = await prisma.salon.findMany({
        where: !includeUnapproved ? { approvalStatus: 'APPROVED' } : {},
        include: {
            _count: {
                select: {
                    reviews: true,
                }
            }
        }
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
            rating: (salon as any)._count?.reviews > 0 && (salon as any).rating ? ((salon as any).rating as number).toFixed(1) : "0.0"
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

export const updateService = async (patronId: number, serviceId: number, data: any) => {
    const service = await prisma.service.findFirst({
        where: {
            id: serviceId,
            salon: { patronId }
        }
    });

    if (!service) {
        throw new Error("Service introuvable ou mouch mta3 salonek");
    }

    const updatedService = await prisma.service.update({
        where: { id: serviceId },
        data: {
            ...(data.name !== undefined && { name: data.name }),
            ...(data.price !== undefined && { price: data.price }),
            ...(data.durationMinutes !== undefined && { durationMinutes: data.durationMinutes }),
            ...(data.description !== undefined && { description: data.description }),
            ...(data.imageUrl !== undefined && { imageUrl: data.imageUrl })
        }
    });

    return updatedService;
};

export const deleteService = async (patronId: number, serviceId: number) => {
    const service = await prisma.service.findFirst({
        where: {
            id: serviceId,
            salon: { patronId }
        }
    });

    if (!service) {
        throw new Error("Service introuvable ou mouch mta3 salonek");
    }

    const linkedAppointmentsCount = await prisma.appointmentService.count({
        where: { serviceId }
    });

    if (linkedAppointmentsCount > 0) {
        throw new Error("Service mawjoud fi rendez-vous. Ma ynajemch yitfaskh.");
    }

    await prisma.service.delete({
        where: { id: serviceId }
    });

    return { id: serviceId, deleted: true };
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
        phoneNumber: emp.phoneNumber,
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
        rating: formattedReviews.length > 0 && typeof salon.rating === "number" ? salon.rating.toFixed(1) : "0.0",
    };
};

export const getTopRatedSalons = async (limit: number = 10, includeUnapproved: boolean = false) => {
    const salons = await prisma.salon.findMany({
        where: !includeUnapproved ? { approvalStatus: 'APPROVED' } : {},
        orderBy: { rating: 'desc' } as any,
        take: limit,
        include: {
            _count: {
                select: {
                    reviews: true,
                }
            }
        }
    });

    return salons.map(salon => ({
        ...salon,
        image: salon.coverImageUrl || 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=500&q=80',
        rating: (salon as any)._count?.reviews > 0 && (salon as any).rating ? ((salon as any).rating as number).toFixed(1) : "0.0",
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
            _count: {
                select: {
                    reviews: true,
                }
            }
        },
        take: 20, // Limit results for performance
    });

    return salons.map(salon => ({
        ...salon,
        image: salon.coverImageUrl || 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=500&q=80',
        rating: (salon as any)._count?.reviews > 0 && (salon as any).rating ? ((salon as any).rating as number).toFixed(1) : "0.0",
    }));
};

export const toggleFavoriteSalon = async (clientId: number, salonId: number) => {
    // Check if it's already favorited
    const existingFavorite = await prisma.favoriteSalon.findFirst({
        where: {
            clientId,
            salonId
        }
    });

    if (existingFavorite) {
        // Remove from favorites
        await prisma.favoriteSalon.delete({
            where: { id: existingFavorite.id }
        });
        return { isFavorite: false };
    } else {
        // Add to favorites
        await prisma.favoriteSalon.create({
            data: {
                clientId,
                salonId
            }
        });
        return { isFavorite: true };
    }
};

export const checkFavoriteStatus = async (clientId: number, salonId: number) => {
    const favorite = await prisma.favoriteSalon.findFirst({
        where: {
            clientId,
            salonId
        }
    });
    return { isFavorite: !!favorite };
};

export const getFavoriteSalons = async (clientId: number) => {
    const favorites = await prisma.favoriteSalon.findMany({
        where: { clientId },
        include: {
            salon: {
                include: {
                    services: true,
                    workingHours: true,
                    _count: {
                        select: {
                            reviews: true,
                        }
                    }
                }
            }
        },
        orderBy: { createdAt: 'desc' }
    });

    return favorites.map(fav => ({
        ...fav.salon,
        image: fav.salon.coverImageUrl || 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=500&q=80',
        rating: (fav.salon as any)._count?.reviews > 0 && (fav.salon as any).rating ? ((fav.salon as any).rating as number).toFixed(1) : "0.0",
        favoritedAt: fav.createdAt
    }));
};
