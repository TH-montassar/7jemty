import 'package:flutter/material.dart';

class AppointmentCard extends StatelessWidget {
  // المتغيرات اللي تستحقهم الكارت بش تظهر المعلومات
  final String name;
  final String service;
  final String time;

  const AppointmentCard({
    super.key,
    required this.name,
    required this.service,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // تنجم تزيد الظل لهنا كان تحب، وإلا تخليه بسيط
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: const Icon(Icons.person, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Service: $service',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                Text(
                  'Heure: $time',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
