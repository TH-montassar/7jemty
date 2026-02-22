import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';

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
    blurRadius: 30,                              // انتشار واسع للظل
    spreadRadius: 0,
    offset: const Offset(0, 10),                 // الظل يميل للأسفل
  )
]
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.star_border), label: "Top Avis"),
          // 🔄 Houni badelna el bouton wel icône
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: "Mes RDV"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profil"),
        ],
      ),
    );
  }
}