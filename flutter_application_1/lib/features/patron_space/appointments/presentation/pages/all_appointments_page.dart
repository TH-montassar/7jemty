import 'package:hjamty/core/localization/translation_service.dart';
import 'package:flutter/material.dart';

class AllAppointmentsPage extends StatelessWidget {
  // Hethi l data elli bech tjina mel HomePage
  final List<Map<String, String>> appointments;

  const AllAppointmentsPage({super.key, required this.appointments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'all_appointments')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // Houni l ListView bech tkhallik tscroli kima t7eb
        child: ListView.separated(
          itemCount: appointments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = appointments[index];
            return _buildAppointmentCard(item);
          },
        ),
      ),
    );
  }

  // Hazzina l widget mta3 l card houni zeda bech nsta3mlouha
  Widget _buildAppointmentCard(Map<String, String> item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
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
                  item['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Service: ${item['service']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                Text(
                  'Heure: ${item['time']}',
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
