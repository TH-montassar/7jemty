import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/features/admin_space/data/admin_service.dart';
import 'manage_users_page.dart';
import 'manage_salons_page.dart';
import 'package:hjamty/features/client_space/profile/presentation/pages/client_profile_page.dart';
import 'package:hjamty/core/widgets/notification_bell.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  bool _isLoading = true;
  int _totalUsers = 0;
  int _totalSalons = 0;
  int _pendingSalons = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final users = await AdminService.getAllUsers();
      final salons = await AdminService.getAllSalons();
      if (mounted) {
        setState(() {
          _totalUsers = users.length;
          _totalSalons = salons.length;
          _pendingSalons = salons
              .where((s) => s['approvalStatus'] == 'PENDING')
              .length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: Text(
          tr(context, 'admin_dashboard'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.indigo.shade900,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: NotificationBell(iconColor: Colors.white),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'system_overview'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: tr(context, 'total_users'),
                          count: _totalUsers.toString(),
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildStatCard(
                          title: tr(context, 'total_salons'),
                          count: _totalSalons.toString(),
                          icon: Icons.store,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildStatCard(
                    title: tr(context, 'pending_approvals'),
                    count: _pendingSalons.toString(),
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                    isWide: true,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    tr(context, 'administrative_actions'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildMenuCard(
                    title: tr(context, 'manage_users'),
                    subtitle: tr(context, 'users_management_desc'),
                    icon: Icons.manage_accounts,
                    color: Colors.blue.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageUsersPage(),
                      ),
                    ).then((_) => _loadStats()),
                  ),
                  const SizedBox(height: 15),
                  _buildMenuCard(
                    title: tr(context, 'manage_salons'),
                    subtitle: tr(context, 'salons_management_desc'),
                    icon: Icons.storefront,
                    color: Colors.purple.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageSalonsPage(),
                      ),
                    ).then((_) => _loadStats()),
                  ),
                  const SizedBox(height: 15),
                  _buildMenuCard(
                    title: tr(context, 'my_profile'),
                    subtitle: tr(context, 'admin_profile_desc'),
                    icon: Icons.person,
                    color: Colors.teal.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    bool isWide = false,
  }) {
    return Container(
      width: isWide ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: isWide
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
