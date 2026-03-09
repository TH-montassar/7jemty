import 'package:flutter/material.dart';
import 'package:hjamty/features/patron_space/salon_dashboard_screen.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/features/client_space/salon_profile/data/salon_service.dart';
import 'package:hjamty/core/utils/cloudinary_utils.dart';

class NearYouList extends StatefulWidget {
  const NearYouList({super.key});

  @override
  State<NearYouList> createState() => _NearYouListState();
}

class _NearYouListState extends State<NearYouList> {
  late Future<List<dynamic>> _salonsFuture;

  @override
  void initState() {
    super.initState();
    // 💡 Houni njibou l'salons mel backend. Tnajem t3adi lat w lng ken 3andek e-position.
    _salonsFuture = SalonService.getAllSalons();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190, // طول الكارطة
      child: FutureBuilder<List<dynamic>>(
        future: _salonsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Ma famech salons 9rab ltawa.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final salons = snapshot.data!;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: salons.length,
            itemBuilder: (context, index) {
              final salon = salons[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SalonDashboardScreen(
                        isPatron: false,
                        salonId: salon['id'],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 150, // عرض الكارطة
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- التصويرة الفوقانية ---
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                          child: Image.network(
                            CloudinaryUtils.getOptimizedUrl(
                                  salon['image'],
                                  width: 300,
                                ) ??
                                'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=500&q=80',
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade100,
                                child: const Icon(
                                  Icons.storefront,
                                  color: Colors.grey,
                                  size: 30,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // --- المعلومات اللوطانية ---
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              salon['name'] ?? 'Salon',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // المسافة (Icon + Distance)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: AppColors.primaryBlue,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      salon['distance'] ?? 'N/A',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                // التقييم (Icon + Note)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: AppColors.primaryBlue,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      salon['rating']?.toString() ?? '0.0',
                                      style: const TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

