import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/features/client_space/profile/presentation/widgets/client_profile_header.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // A slightly cooler, "pro" grey background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA), // Match scaffold background
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false, // Left-align for a more modern, dashboard feel
        titleSpacing: 24,
        automaticallyImplyLeading: false,
        title: Text(
          tr(context, 'my_profile'),
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Photo, Nom, Email
            ProfileHeader(userData: _userData, onUpdate: _checkLoginStatus),
            const SizedBox(height: 32),

            // 3. Mes Activités (Commandes & Favoris)
            if (_userData != null && _userData!['role'] == 'CLIENT') ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  tr(context, 'my_activities'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const ActivityMenu(),
              const SizedBox(height: 32),
            ],

            // 4. Paramètres
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                tr(context, 'settings'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SettingsMenu(),
            const SizedBox(height: 32),

            // 5. Déconnexion
            const LogoutButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
