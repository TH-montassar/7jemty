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
        top: 24,
        left: 24,
        right: 24,
        bottom: 56, // خلينا مساحة اللوطة باش المحتوى الأبيض يركب فوقها
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF005CEE),
            Color(0xFF0044B3), // Darker shade of primary blue for a pro gradient
          ],
        ),
      ),
      child: Column(
        children: [
          // 1. الترحيب (Ahla, Sami) والأيقونة متاع الإشعارات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${tr(context, 'greeting')}, $userName",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              // 🔔 أيقونة الإشعارات مع النقطة الحمراء (Badge)
              const NotificationBell(),
            ],
          ),
          const SizedBox(height: 24),

          // 2. الموقع (Localisation) - الفلسة اللّي في الوسط
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), // أزرق شفاف شوية باش يبرز
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize:
                  MainAxisSize.min, // باش تاخو كان البلاصة اللّي تستحقها
              children: const [
                Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  "Ariana, Tunis",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 3. شريط البحث (Search Bar) - رديناه GestureDetector
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Colors.black45, size: 24),
                  const SizedBox(width: 12),
                  // استعملنا Text في بلاصة TextField باش ما يتحلش الكلافيي
                  Expanded(
                    child: Text(
                      tr(context, 'search_placeholder'),
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // أيقونة الفلتر (Filtre) في اللخر
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune_rounded, color: AppColors.primaryBlue, size: 20),
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
