import 'package:hjamty/core/localization/translation_service.dart';
import 'package:flutter/material.dart';
import '../widgets/appointment_card.dart';

class TodayAppointmentsPage extends StatelessWidget {
  final List<Map<String, String>> todayAppointments;

  const TodayAppointmentsPage({super.key, required this.todayAppointments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'today_appointments_title'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: todayAppointments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = todayAppointments[index];
            return AppointmentCard(
              name: item['name']!,
              service: item['service']!,
              time: item['time']!,
            );
          },
        ),
      ),
    );
  }
}