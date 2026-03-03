import 'package:hjamty/core/localization/translation_service.dart';
import 'package:flutter/material.dart';
import '../../pages/home_page.dart';
import '../../pages/calendar_page.dart';
import 'salon_dashboard_screen.dart';
import '../client_space/profile/presentation/pages/profile_page.dart';
import '../../services/auth_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/notification_bell.dart';

class MainPage extends StatefulWidget {
  final int initialIndex;
  const MainPage({super.key, this.initialIndex = 0});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _selectedIndex;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final result = await AuthService.getMe();
      if (mounted) {
        setState(() {
          _userData = result['data'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  // هذي القايمة متاع الصفحات اللي بش يظهرو في الوسط
  final List<Widget> _pages = [
    const HomePage(), // Index 0
    const CalendarPage(), // Index 1
    const SalonDashboardScreen(isPatron: true), // Index 2
    const ProfilePage(), // Index 3
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. الـ AppBar حطيناه هنا بش يقعد ديما ظاهر
      // Hide global AppBar for Salon Dashboard and Profile since they have their own
      appBar: (_selectedIndex == 2 || _selectedIndex == 3)
          ? null
          : AppBar(
              title: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 24,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.cut, color: Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  Text(tr(context, 'app_name_7jemty')),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            (_userData?['profile']?['avatarUrl'] != null &&
                                _userData!['profile']['avatarUrl'].isNotEmpty)
                            ? NetworkImage(_userData!['profile']['avatarUrl'])
                            : const NetworkImage(
                                'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                              ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _userData?['fullName'] ??
                            tr(context, 'salon_name_label'),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(width: 16),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                        radius: 15,
                        child: const NotificationBell(
                          iconColor: AppColors.primaryBlue,
                          badgeColor: AppColors.actionRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

      // 2. الـ Body هو اللي يتبدل حسب الـ Index
      body: _pages[_selectedIndex],

      // 3. الـ BottomNavigationBar يقعد ديما هنا
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Agenda mte3i',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Salon mte3i',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
