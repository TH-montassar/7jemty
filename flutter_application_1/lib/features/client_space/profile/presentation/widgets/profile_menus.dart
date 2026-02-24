import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

// --------------------------------------------------------
// 1. Menu des Activités (Commandes & Favoris)
// --------------------------------------------------------
class ActivityMenu extends StatelessWidget {
  const ActivityMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: const [
          _ProfileMenuItem(icon: Icons.local_shipping_outlined, title: "Mes Commandes Produits", subtitle: "2 en cours"),
          Divider(height: 1, indent: 60),
          _ProfileMenuItem(icon: Icons.favorite_border, title: "Mes Salons Favoris", subtitle: "4 salons"),
        ],
      ),
    );
  }
}

// --------------------------------------------------------
// 2. Menu des Paramètres (Langue, Notifs, Aide...)
// --------------------------------------------------------
class SettingsMenu extends StatefulWidget {
  const SettingsMenu({super.key});

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  bool _isNotifOn = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          ListTile(
            leading: _buildIconBox(Icons.language),
            title: const Text("Langue", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text("FR", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                SizedBox(width: 5),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
            onTap: () {},
          ),
          const Divider(height: 1, indent: 60),
          ListTile(
            leading: _buildIconBox(Icons.notifications_outlined),
            title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            trailing: Switch(
              value: _isNotifOn,
              activeColor: AppColors.primaryBlue,
              onChanged: (val) => setState(() => _isNotifOn = val),
            ),
          ),
          const Divider(height: 1, indent: 60),
          const _ProfileMenuItem(icon: Icons.help_outline, title: "Aide & Support"),
          const Divider(height: 1, indent: 60),
          const _ProfileMenuItem(icon: Icons.description_outlined, title: "Conditions Générales"),
        ],
      ),
    );
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(color: AppColors.bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: AppColors.textDark, size: 20),
    );
  }
}

// --------------------------------------------------------
// 3. Bouton Déconnexion
// --------------------------------------------------------
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.actionRed.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.logout, color: AppColors.actionRed, size: 20),
        ),
        title: const Text("Déconnexion", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.actionRed)),
        onTap: () {
          // TODO: Logique de déconnexion
        },
      ),
    );
  }
}

// --------------------------------------------------------
// Widget générique bech ma n3awdouch l'code
// --------------------------------------------------------
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _ProfileMenuItem({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: AppColors.bgColor, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.textDark, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () {},
    );
  }
}