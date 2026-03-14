import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/features/admin_space/presentation/pages/admin_home_page.dart';
import 'package:hjamty/features/admin_space/presentation/pages/manage_reports_page.dart';
import 'package:hjamty/features/admin_space/presentation/pages/manage_salons_page.dart';
import 'package:hjamty/features/admin_space/presentation/pages/manage_users_page.dart';
import 'package:hjamty/features/client_space/profile/presentation/pages/client_profile_page.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboardPage(),
    const ManageSalonsPage(),
    const ManageUsersPage(),
    const ManageReportsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: _buildBottomNav(),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white, // White nav bar
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded),
          _buildNavItem(1, Icons.storefront_rounded),
          _buildNavItem(2, Icons.people_rounded),
          _buildNavItem(3, Icons.report_gmailerrorred_rounded),
          _buildNavItem(4, Icons.person_rounded),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        transform: Matrix4.translationValues(0, isSelected ? -20 : 0, 0),
        padding: EdgeInsets.all(isSelected ? 14 : 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withAlpha(100),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Colors.transparent,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey.shade500,
          size: isSelected ? 26 : 22,
        ),
      ),
    );
  }
}
