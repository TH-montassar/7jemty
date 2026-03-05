import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/features/client_space/search/presentation/pages/search_page.dart';
import 'package:hjamty/core/widgets/notification_bell.dart';

class ClientHeaderSection extends StatelessWidget {
  final String userName;

  const ClientHeaderSection({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Padding الفوقاني باش يتفادى الـ Status Bar متاع التليفون (البلاصة اللي فيها البطارية والريزو)
      // Tawa zedna SafeArea fel page, donc nraj3ouh wadh7.
      padding: const EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: 40, // خلينا مساحة اللوطة باش المحتوى الأبيض يركب فوقها
      ),
      decoration: const BoxDecoration(color: AppColors.primaryBlue),
      child: Column(
        children: [
          // 1. الترحيب (Ahla, Sami) والأيقونة متاع الإشعارات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${tr(context, 'greeting')}, $userName",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              // 🔔 أيقونة الإشعارات مع النقطة الحمراء (Badge)
              const NotificationBell(),
            ],
          ),
          const SizedBox(height: 20),

          // 2. الموقع (Localisation) - الفلسة اللّي في الوسط
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.15,
              ), // أزرق شفاف شوية باش يبرز
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize:
                  MainAxisSize.min, // باش تاخو كان البلاصة اللّي تستحقها
              children: const [
                Icon(Icons.location_on, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  "Ariana, Tunis",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // 3. شريط البحث (Search Bar) - رديناه GestureDetector
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 10),
                  // استعملنا Text في بلاصة TextField باش ما يتحلش الكلافيي
                  Expanded(
                    child: Text(
                      tr(context, 'search_placeholder'),
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  // أيقونة الفلتر (Filtre) في اللخر
                  Container(
                    padding: const EdgeInsets.all(5),
                    child: const Icon(Icons.tune, color: AppColors.primaryBlue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
