import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/localization/translation_service.dart';

class ClientBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const ClientBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // شفافية عالية جداً
            blurRadius: 30, // انتشار واسع للظل
            spreadRadius: 0,
            offset: const Offset(0, 10), // الظل يميل للأسفل
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: tr(context, 'home')),

          // 🔄 Houni badelna el bouton wel icône
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: tr(context, 'appointments_short'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.production_quantity_limits),
            label: tr(context, 'products'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: tr(context, 'profile'),
          ),
        ],
      ),
    );
  }
}
