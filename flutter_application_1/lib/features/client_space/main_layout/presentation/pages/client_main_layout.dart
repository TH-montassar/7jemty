import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hjamty/features/client_space/products/presentation/pages/products_page.dart';

// 1. N3aytou lel pages lkol
import '../../../home/presentation/pages/client_home_page.dart';
import '../../../appointments/presentation/pages/appointments_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

// 2. N3aytou lel SignIn w l'BottomNav
import '../../../../auth/signIn.dart'; // 👈 Baddel l'chemin 7asb dossieretk
import '../../../home/presentation/widgets/client_bottom_nav.dart';

class ClientMainLayout extends StatefulWidget {
  const ClientMainLayout({super.key});

  @override
  State<ClientMainLayout> createState() => _ClientMainLayoutState();
}

class _ClientMainLayoutState extends State<ClientMainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
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
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: ClientBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped, // 👈 N3aytou lel fonction elli fiha l'Auth check
      ),
    );
  }
}
