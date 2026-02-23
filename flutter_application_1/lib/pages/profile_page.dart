import 'package:flutter/material.dart';
import '../widgets/profile_data.dart';
import '../widgets/profile_header.dart';
import '../widgets/subscription_card.dart';
import '../widgets/profile_sections.dart';
import '../widgets/profile_modals.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Functions to show Modals
  void _showCutDetails(Map<String, String> cut) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CutDetailsModal(cutData: cut),
    );
  }

  void _showPointsHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PointsHistoryModal(
        historyData: ProfileData.pointsHistory,
        rewardsData: ProfileData.rewardsHistory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header
            const ProfileHeader(),

            // 2. Floating Card
            SubscriptionCard(onPointsTap: _showPointsHistory),

            // 3. Gallery
            HaircutGallery(
              cuts: ProfileData.historyCuts,
              onCutTap: _showCutDetails,
            ),

            const SizedBox(height: 20),

            // 4. Settings
            const SettingsSection(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
