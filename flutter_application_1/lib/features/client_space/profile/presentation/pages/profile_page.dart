import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../widgets/profile_header.dart';
import '../widgets/loyalty_cards_section.dart';
import '../widgets/profile_menus.dart';

import 'package:hjamty/core/localization/translation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final role = prefs.getString('user_role');

    if (mounted) {
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoggedIn = false;
          _userRole = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoggedIn = true;
          _userRole = role;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgColor,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    if (!_isLoggedIn) {
      return const Scaffold(
        backgroundColor: AppColors.bgColor,
        body: SizedBox.shrink(),
      );
    }

    final isEmployee = _userRole == 'EMPLOYEE';

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          tr(context, 'my_profile'),
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Photo, Nom, Email
            const ProfileHeader(),
            const SizedBox(height: 30),

            // 2. Cartes Salons (Tampons) - Only for Clients
            if (!isEmployee) ...[
              Text(
                tr(context, 'loyalty_cards'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 15),
              const LoyaltyCardsSection(),
              const SizedBox(height: 30),
            ],

            // 3. Mes Activités (Commandes & Favoris)
            Text(
              tr(context, 'my_activities'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 15),
            const ActivityMenu(),
            const SizedBox(height: 30),

            // 4. Paramètres
            Text(
              tr(context, 'settings'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 15),
            const SettingsMenu(),
            const SizedBox(height: 30),

            // 5. Déconnexion
            const LogoutButton(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
