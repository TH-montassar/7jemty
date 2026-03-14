import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/core/services/fcm_service.dart';
import 'package:hjamty/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hjamty/features/auth/signIn.dart';

import 'package:hjamty/features/client_space/profile/presentation/pages/favorite_salons_page.dart';
import 'package:hjamty/features/client_space/salon_profile/data/salon_service.dart';

// --------------------------------------------------------
// 1. Menu des Activités (Commandes & Favoris)
// --------------------------------------------------------
class ActivityMenu extends StatefulWidget {
  const ActivityMenu({super.key});

  @override
  State<ActivityMenu> createState() => _ActivityMenuState();
}

class _ActivityMenuState extends State<ActivityMenu> {
  int _favoriteCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchFavoriteCount();
  }

  Future<void> _fetchFavoriteCount() async {
    try {
      final salons = await SalonService.getFavoriteSalons();
      if (mounted) {
        setState(() {
          _favoriteCount = salons.length;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          _ProfileMenuItem(
            icon: Icons.local_shipping_outlined,
            title: tr(context, 'product_orders'),
            subtitle: tr(context, 'orders_remaining', args: ['2']),
            isTop: true,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 64, right: 16),
            child: Divider(height: 1, color: Colors.grey[200]),
          ),
          _ProfileMenuItem(
            icon: Icons.favorite_border,
            title: tr(context, 'favorite_salons'),
            subtitle: tr(
              context,
              'favorite_salons_count',
              args: ['$_favoriteCount'],
            ),
            isBottom: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoriteSalonsPage(),
                ),
              ).then((_) => _fetchFavoriteCount()); // Refresh count on return
            },
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              onTap: () => _showLanguageDialog(),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: _buildIconBox(Icons.language),
                title: Text(
                  tr(context, 'language'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textDark),
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
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 64, right: 16),
            child: Divider(height: 1, color: Colors.grey[200]),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _buildIconBox(Icons.notifications_outlined),
            title: Text(
              tr(context, 'notifications'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textDark),
            ),
            trailing: Switch(
              value: _isNotifOn,
              activeColor: Colors.white,
              activeTrackColor: AppColors.primaryBlue,
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[200],
              onChanged: (val) => setState(() => _isNotifOn = val),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 64, right: 16),
            child: Divider(height: 1, color: Colors.grey[200]),
          ),
          _ProfileMenuItem(
            icon: Icons.help_outline_rounded,
            title: tr(context, 'help_support'),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 64, right: 16),
            child: Divider(height: 1, color: Colors.grey[200]),
          ),
          _ProfileMenuItem(
            icon: Icons.description_outlined,
            title: tr(context, 'terms'),
            isBottom: true,
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.primaryBlue, size: 22),
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
    await FcmService.unregisterDeviceToken();
    NotificationService.stopListeningToNotificationsStream();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    NotificationService.resetUnreadCount();

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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _logout(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.actionRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.logout_rounded, color: AppColors.actionRed, size: 22),
                ),
                const SizedBox(width: 16),
                Text(
                  tr(context, 'logout'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.actionRed,
                  ),
                ),
              ],
            ),
          ),
        ),
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
  final VoidCallback? onTap;
  final bool isTop;
  final bool isBottom;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isTop = false,
    this.isBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(24) : Radius.zero,
          bottom: isBottom ? const Radius.circular(24) : Radius.zero,
        ),
        onTap: onTap ?? () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textDark),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
