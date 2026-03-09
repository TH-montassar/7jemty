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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06), // شفافية عالية جداً
            blurRadius: 25, // انتشار واسع للظل
            spreadRadius: 1,
            offset: const Offset(0, -8), // الظل يميل للأعلى قليلا
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.primaryBlue,
            unselectedItemColor: Colors.black38,
            selectedIconTheme: const IconThemeData(size: 28),
            unselectedIconTheme: const IconThemeData(size: 24),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            items: [
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 6.0),
                  child: Icon(Icons.home_rounded),
                ),
                label: tr(context, 'home'),
              ),
              // 🔄 Houni badelna el bouton wel icône
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 6.0),
                  child: Icon(Icons.calendar_month_rounded),
                ),
                label: tr(context, 'appointments_short'),
              ),
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 6.0),
                  child: Icon(Icons.shopping_bag_outlined),
                ),
                label: tr(context, 'products'),
              ),
              BottomNavigationBarItem(
                icon: const Padding(
                  padding: EdgeInsets.only(bottom: 6.0),
                  child: Icon(Icons.person_outline_rounded),
                ),
                label: tr(context, 'profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
