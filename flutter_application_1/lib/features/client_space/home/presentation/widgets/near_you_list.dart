import 'package:flutter/material.dart';
import 'package:hjamty/features/client_space/salon_profile/presentation/pages/salon_profile_page.dart';
import '../../../../../core/constants/app_colors.dart';
// 🚀 1. أعمل Import لصفحة بروفيل الصالون باش كي تكليكي تهزك ليها
// (ثبت من الـ Chemin حسب كيفاش مسمي الفيشي متاعك)
// import '../../salon_profile/presentation/pages/salon_profile_page.dart';

class NearYouList extends StatelessWidget {
  const NearYouList({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 Mock Data: ليستة الصالونات اللّي قراب
    final List<Map<String, dynamic>> nearbySalons = [
      {
        'name': 'Barber King 👑',
        'distance': '1.2 km',
        'rating': '4.9',
        'image': 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=500&q=80',
      },
      {
        'name': 'The Classic Barber',
        'distance': '2.5 km',
        'rating': '4.8',
        'image': 'https://images.unsplash.com/photo-1503342394128-c104d54dba01?auto=format&fit=crop&w=500&q=80',
      },
      {
        'name': 'Salon El Baze',
        'distance': '3.0 km',
        'rating': '4.5',
        'image': 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?auto=format&fit=crop&w=500&q=80',
      },
    ];

    return SizedBox(
      height: 190, // طول الكارطة
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: nearbySalons.length,
        itemBuilder: (context, index) {
          final salon = nearbySalons[index];
          
          return GestureDetector(
            onTap: () {
             
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SalonProfilePage()),
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
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Image.network(
                        salon['image'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        // 🚀 3. هذي باش تنحيلك الـ X الحمراء الخايبة كان التصويرة ما تحلتش
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.storefront, color: Colors.grey, size: 30),
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
                          salon['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // باش كان الاسم طويل يعمل 3 نقاط (...)
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // المسافة (Icon + Distance)
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: AppColors.primaryBlue, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  salon['distance'],
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            // التقييم (Icon + Note)
                            Row(
                              children: [
                                const Icon(Icons.star, color: AppColors.primaryBlue, size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  salon['rating'],
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
      ),
    );
  }
}