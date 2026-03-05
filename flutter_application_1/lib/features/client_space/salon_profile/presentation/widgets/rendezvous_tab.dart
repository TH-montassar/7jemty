import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';

class RendezvousTab extends StatelessWidget {
  const RendezvousTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock upcoming appointments
    final appointments = [
      {
        'service': 'Coupe Classique',
        'specialist': 'Malek Ben Ali',
        'date': 'Sam 1 Mars 2026',
        'time': '10:00',
        'status': tr(context, 'status_confirmed'),
        'statusColor': Colors.green,
      },
      {
        'service': 'Taille de Barbe',
        'specialist': 'Yassine Trabelsi',
        'date': 'Dim 9 Mars 2026',
        'time': '14:30',
        'status': tr(context, 'status_pending'),
        'statusColor': Colors.orange,
      },
    ];

    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 70, color: Colors.grey.shade300),
            const SizedBox(height: 15),
            Text(
              tr(context, 'no_appointments'),
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    appt['service'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (appt['statusColor'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      appt['status'] as String,
                      style: TextStyle(
                        color: appt['statusColor'] as Color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _rowInfo(Icons.person, appt['specialist'] as String),
              const SizedBox(height: 6),
              _rowInfo(Icons.calendar_today, appt['date'] as String),
              const SizedBox(height: 6),
              _rowInfo(Icons.access_time, appt['time'] as String),
              const SizedBox(height: 14),
              // Cancel button
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: const Text(
                  "Annuler",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _rowInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}
