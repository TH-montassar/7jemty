import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/features/client_space/salon_profile/data/salon_service.dart';
import 'package:hjamty/features/patron_space/salon_dashboard_screen.dart';
import 'package:hjamty/core/utils/cloudinary_utils.dart';

class FavoriteSalonsPage extends StatefulWidget {
  const FavoriteSalonsPage({super.key});

  @override
  State<FavoriteSalonsPage> createState() => _FavoriteSalonsPageState();
}

class _FavoriteSalonsPageState extends State<FavoriteSalonsPage> {
  late Future<List<dynamic>> _favoriteSalonsFuture;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  void _fetchFavorites() {
    setState(() {
      _favoriteSalonsFuture = SalonService.getFavoriteSalons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: Text(
          tr(context, 'favorite_salons'),
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _favoriteSalonsFuture,
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr(context, 'no_data_found'),
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final salons = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              _fetchFavorites();
            },
            color: AppColors.primaryBlue,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
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
                    ).then(
                      (_) => _fetchFavorites(),
                    ); // Refresh when coming back
                  },
                  child: Container(
                    height: 120, // عرض الكارطة
                    margin: const EdgeInsets.only(bottom: 15),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- التصويرة الفوقانية ---
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(15),
                          ),
                          child: Image.network(
                            CloudinaryUtils.getOptimizedUrl(
                                  salon['image'],
                                  width: 300,
                                ) ??
                                'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=500&q=80',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
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

                        // --- المعلومات ---
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        salon['name'] ?? 'Salon',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.favorite,
                                      color: AppColors.actionRed,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (salon['address'] != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: AppColors.primaryBlue,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          salon['address'],
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                const Spacer(),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: AppColors.primaryBlue,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      salon['rating']?.toString() ?? '4.5',
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
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
