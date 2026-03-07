import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hjamty/features/client_space/products/presentation/pages/products_page.dart';

// 1. N3aytou lel pages lkol
import 'package:hjamty/features/client_space/home/presentation/pages/client_home_page.dart';
import 'package:hjamty/features/client_space/appointments/presentation/pages/appointments_page.dart';
import 'package:hjamty/features/client_space/profile/presentation/pages/client_profile_page.dart';

// 2. N3aytou lel SignIn w l'BottomNav
import 'package:hjamty/features/auth/signIn.dart'; // 👈 Baddel l'chemin 7asb dossieretk
import 'package:hjamty/features/client_space/home/presentation/widgets/client_bottom_nav.dart';
import 'package:hjamty/core/services/notification_service.dart';

class ClientMainLayout extends StatefulWidget {
  final int initialIndex;
  const ClientMainLayout({super.key, this.initialIndex = 0});

  @override
  State<ClientMainLayout> createState() => _ClientMainLayoutState();
}

class _ClientMainLayoutState extends State<ClientMainLayout> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    NotificationService.listenToNotificationsStream();
  }

  List<Widget> _pages = [
    const ClientHomePage(),
    const AppointmentsPage(),
    const ProductsPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) async {
    // 🚀 Houni ntestiwa l'Auth 9bal ma nbadlou l'onglet
    if (index == 3) {
      // Index 3 houwa l'onglet mta3 Profil

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      bool isUserLoggedIn = token != null && token.isNotEmpty;

      if (!isUserLoggedIn) {
        // Mouch connecté -> Thezzou lel SignIn
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignInScreen()),
          );
        }
        return; // 👈 Na3mlou return bech l'application ma tbadalech l'onglet louta
      }
    }

    // Ken mouch index 3, wala ken l'utilisateur connecté, nbaddlou l'onglet 3adi
    if (mounted) {
      setState(() {
        if (index == 1) {
          // Force Upcoming/History tabs to reload data from API upon explicit click
          _pages[1] = AppointmentsPage(key: UniqueKey());
        } else if (index == 3) {
          // Force Profile tab to reload in case the user recently logged in (e.g guest booking)
          _pages[3] = ProfilePage(key: UniqueKey());
        }
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: ClientBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped, // 👈 N3aytou lel fonction elli fiha l'Auth check
      ),
    );
  }
}
