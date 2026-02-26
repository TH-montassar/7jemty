import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../widgets/upcoming_tab.dart';
import '../widgets/history_tab.dart';
import '../../../../../core/localization/translation_service.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bgColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          // Na7ina l'flèche mta3 retour 5ater hethi page principale fel BottomNav
          automaticallyImplyLeading: false,
          title: Text(
            tr(context, 'my_appointments'),
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryBlue,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: tr(context, 'upcoming')),
              Tab(text: tr(context, 'history')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UpcomingTab(), // 1. المواعيد الجاية
            HistoryTab(), // 2. المواعيد القديمة (ولّات فيها زادة الملغاة)
          ],
        ),
      ),
    );
  }
}
