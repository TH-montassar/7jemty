import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../widgets/profile_header.dart';
import '../widgets/loyalty_cards_section.dart';
import '../widgets/profile_menus.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (mounted) {
      if (token == null || token.isEmpty) {
        // Ma na3mlouch redirection houni 5ater IndexedStack tchargi l'ProfilePage automatiquement
        // L'redirection 3malneha deja fi client_main_layout.dart kif yenzil 3al onglet
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoggedIn = true;
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
      // Retourni page fergha wela un message bech ma yatl3ouch des erreurs
      // 5ater l'utilisateur mouch connecté w l'IndexedStack dima tchargi hedhi
      return const Scaffold(
        backgroundColor: AppColors.bgColor,
        body: SizedBox.shrink(),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          "Mon Profil",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            // 1. Header: Photo, Nom, Email
            ProfileHeader(),
            SizedBox(height: 30),

            // 2. Cartes Salons (Tampons)
            Text(
              "Cartes de Fidélité 🎁",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 15),
            LoyaltyCardsSection(),
            SizedBox(height: 30),

            // 3. Mes Activités (Commandes & Favoris)
            Text(
              "Mes Activités",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 15),
            ActivityMenu(),
            SizedBox(height: 30),

            // 4. Paramètres
            Text(
              "Paramètres",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 15),
            SettingsMenu(),
            SizedBox(height: 30),

            // 5. Déconnexion
            LogoutButton(),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
