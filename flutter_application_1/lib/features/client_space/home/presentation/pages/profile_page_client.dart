import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';

class ProfilePageClient extends StatelessWidget {
  const ProfilePageClient({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mon Profil",
          style: TextStyle(color: AppColors.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: const Center(
        child: Text("Profil du Client - En cours de développement..."),
      ),
    );
  }
}
