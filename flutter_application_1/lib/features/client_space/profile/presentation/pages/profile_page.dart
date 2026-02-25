import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../widgets/profile_header.dart';
import '../widgets/loyalty_cards_section.dart';
import '../widgets/profile_menus.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, 
        title: const Text("Mon Profil", style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
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
            Text("Cartes de Fidélité 🎁", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            SizedBox(height: 15),
            LoyaltyCardsSection(),
            SizedBox(height: 30),

            // 3. Mes Activités (Commandes & Favoris)
            Text("Mes Activités", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            SizedBox(height: 15),
            ActivityMenu(),
            SizedBox(height: 30),

            // 4. Paramètres
            Text("Paramètres", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
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