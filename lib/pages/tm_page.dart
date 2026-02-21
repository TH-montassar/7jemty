// TODO Implement this library.
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
// Houni n3aytou lel page mta3 l'client elli 5demnaha
import '../features/client_space/home/presentation/pages/client_home_page.dart';
import '../pages/main_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Logo wala Titre mta3 l'App
              const Icon(Icons.content_cut, size: 80, color: AppColors.primaryBlue),
              const SizedBox(height: 20),
              const Text(
                "Mar7ba bik fi 7ajamty",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Chkoun enti lyoum?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 50),

              // 2. Bouton Espace Client
              _buildRoleCard(
                context: context,
                title: "Espace Client",
                subtitle: "Lawej 3la 7ajem w a3mel réservation",
                icon: Icons.person_outline,
                color: AppColors.primaryBlue,
                onTap: () {
                  // Navigation lel Espace Client
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ClientHomePage()),
                  );
                },
              ),
              
              const SizedBox(height: 20),

              // 3. Bouton Espace Barber
              _buildRoleCard(
                context: context,
                title: "Espace 7ajem",
                subtitle: "Gérer l'salon w les rendez-vous mte3ek",
                icon: Icons.storefront,
                color: AppColors.textDark, // Nesta3mlou l'gris fange9 bech nfar9ouh 3al client
                onTap: () {
                  // Navigation lel Espace Barber (n7ottou page test tawa)
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MainPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🧩 Widget sghir bech ma n3awdouch l'code mta3 l'bouton snin
  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ⚠️ PAGE TEST LEL BARBER (juste bech l'code ye5dem)
// ==========================================
class BarberTestPage extends StatelessWidget {
  const BarberTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Espace 7ajem"), backgroundColor: AppColors.textDark),
      body: const Center(child: Text("Hetha l'espace mta3 l'7ajem (En cours de dev...)")),
    );
  }
}