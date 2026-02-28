import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/constants/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  Future<Map<String, String?>> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('user_name'),
      'role': prefs.getString('user_role'),
      'phone': prefs.getString(
        'user_phone',
      ), // Fallback if email is not available
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String?>>(
      future: _getUserData(),
      builder: (context, snapshot) {
        final name = snapshot.data?['name'] ?? 'Utilisateur';
        final roleOrPhone =
            snapshot.data?['role'] ?? snapshot.data?['phone'] ?? 'Client';

        return Container(
          padding: const EdgeInsets.all(20),
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
          child: Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                backgroundImage: const NetworkImage(
                  'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=150&q=80',
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roleOrPhone,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.bgColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  onPressed: () {
                    // TODO: Naviguer vers Edit Profile
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
