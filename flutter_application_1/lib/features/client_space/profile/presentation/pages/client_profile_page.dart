import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/features/client_space/profile/presentation/widgets/client_profile_header.dart';
import 'package:hjamty/features/client_space/profile/presentation/widgets/loyalty_cards_section.dart';
import 'package:hjamty/features/client_space/profile/presentation/widgets/profile_menus.dart';

import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/features/auth/data/auth_service.dart';
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
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoggedIn = false;
            _userRole = null;
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch real data from DB
      final result = await AuthService.getMe();
      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _userData = result['data'];
          _userRole = _userData?['role'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
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

    final isClient = _userRole == 'CLIENT';

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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Photo, Nom, Email
            ProfileHeader(userData: _userData, onUpdate: _checkLoginStatus),
            const SizedBox(height: 30),

            // 2. Cartes Salons (Tampons) - Only for Clients
            if (isClient) ...[
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
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
