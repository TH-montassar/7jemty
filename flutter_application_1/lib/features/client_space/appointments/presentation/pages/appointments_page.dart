import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../widgets/upcoming_tab.dart';
import '../widgets/history_tab.dart';
import '../widgets/cancelled_tab.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.bgColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          // Na7ina l'flèche mta3 retour 5ater hethi page principale fel BottomNav
          automaticallyImplyLeading: false, 
          title: const Text(
            "Mes Rendez-vous",
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryBlue,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "À venir"),
              Tab(text: "Historique"),
              Tab(text: "Annulés"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UpcomingTab(),   // 1. المواعيد الجاية
            HistoryTab(),    // 2. المواعيد القديمة
            CancelledTab(),  // 3. المواعيد الملغاة
          ],
        ),
      ),
    );
  }
}