import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hjamty/features/auth/signIn.dart';

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _ProfileMenuItem(
            icon: Icons.local_shipping_outlined,
            title: tr(context, 'product_orders'),
            subtitle: "2 mazelou",
          ),
          Divider(height: 1, indent: 60),
          _ProfileMenuItem(
            icon: Icons.favorite_border,
            title: tr(context, 'favorite_salons'),
            subtitle: "4 salons",
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: _buildIconBox(Icons.language),
            title: Text(
              tr(context, 'language'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  TranslationProvider.of(context).currentLang == 'tn'
                      ? "TN"
                      : "EN",
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
            onTap: () {
              // Ouvrir un dialog de choix de langue
              _showLanguageDialog();
            },
          ),
          const Divider(height: 1, indent: 60),
          ListTile(
            leading: _buildIconBox(Icons.notifications_outlined),
            title: Text(
              tr(context, 'notifications'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            trailing: Switch(
              value: _isNotifOn,
              activeThumbColor: AppColors.primaryBlue,
              onChanged: (val) => setState(() => _isNotifOn = val),
            ),
          ),
          const Divider(height: 1, indent: 60),
          _ProfileMenuItem(
            icon: Icons.help_outline,
            title: tr(context, 'help_support'),
          ),
          const Divider(height: 1, indent: 60),
          _ProfileMenuItem(
            icon: Icons.description_outlined,
            title: tr(context, 'terms'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(tr(context, 'language')),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(tr(context, 'tunisian_lang')),
                trailing: TranslationProvider.of(context).currentLang == 'tn'
                    ? const Icon(Icons.check, color: AppColors.primaryBlue)
                    : null,
                onTap: () {
                  TranslationProvider.of(context).setLanguage('tn');
                  Navigator.pop(dialogContext);
                },
              ),
              ListTile(
                title: Text(tr(context, 'english_lang_title')),
                trailing: TranslationProvider.of(context).currentLang == 'en'
                    ? const Icon(Icons.check, color: AppColors.primaryBlue)
                    : null,
                onTap: () {
                  TranslationProvider.of(context).setLanguage('en');
                  Navigator.pop(dialogContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.textDark, size: 20),
    );
  }
}

// --------------------------------------------------------
// 3. Bouton Déconnexion
// --------------------------------------------------------
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.actionRed.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.logout, color: AppColors.actionRed, size: 20),
        ),
        title: Text(
          tr(context, 'logout'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.actionRed,
          ),
        ),
        onTap: () => _logout(context),
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

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: AppColors.bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textDark, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          : null,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: () {},
    );
  }
}
