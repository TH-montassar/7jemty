import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hjamty/core/constants/app_colors.dart';

Future<void> showAppointmentDetailsBottomSheet({
  required BuildContext context,
  required Map<String, dynamic> appointment,
  bool showClientDetails = true,
  bool showBarberDetails = true,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _AppointmentDetailsSheet(
        appointment: appointment,
        showClientDetails: showClientDetails,
        showBarberDetails: showBarberDetails,
      );
    },
  );
}

class _AppointmentDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final bool showClientDetails;
  final bool showBarberDetails;

  const _AppointmentDetailsSheet({
    Key? key,
    required this.appointment,
    this.showClientDetails = true,
    this.showBarberDetails = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Parse data safely
    final client = appointment['client'] ?? {};
    final clientName = client['fullName'] ?? 'Client inconnu';
    final clientPhone = client['phoneNumber'] ?? '';

    final salon = appointment['salon'] ?? {};
    final salonName = salon['name'] ?? 'Salon inconnu';
    final salonAddress = salon['address'] ?? '';

    final barber = appointment['barber'] ?? {};
    final barberName = barber['fullName'] ?? 'Non assigné';

    final statusStr = (appointment['status'] ?? '').toString().toUpperCase();
    final totalPrice = appointment['totalPrice'] ?? 0;
    final totalDuration = appointment['totalDurationMinutes'] ?? 0;

    final servicesList = appointment['services'] as List<dynamic>? ?? [];

    final dateStr = appointment['appointmentDate'];
    DateTime date = DateTime.now();
    if (dateStr != null) {
      try {
        date = DateTime.parse(dateStr).toLocal();
      } catch (e) {
        // Fallback
      }
    }

    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy - HH:mm',
      'fr_FR',
    ).format(date);

    // Calculate end time
    String formattedEndTime = '--:--';
    try {
      final startTime = DateFormat(
        'HH:mm',
      ).format(date); // Get start time from the 'date' DateTime object
      final parts = startTime.split(':');
      final start = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
      final int duration = totalDuration is int
          ? totalDuration
          : (totalDuration as double).toInt();

      final int totalMins = start.hour * 60 + start.minute + duration;
      final endHour = (totalMins ~/ 60) % 24; // Apply modulo 24 here
      final endMin = totalMins % 60;
      formattedEndTime =
          "${endHour.toString().padLeft(2, '0')}:${endMin.toString().padLeft(2, '0')}";
    } catch (_) {
      // Fallback to estimatedEndTime if calculation fails or if it's available
      if (appointment['estimatedEndTime'] != null) {
        try {
          final endTimeDateTime = DateTime.parse(
            appointment['estimatedEndTime'],
          ).toLocal();
          formattedEndTime = DateFormat(
            'HH:mm',
            'fr_FR',
          ).format(endTimeDateTime);
        } catch (e) {
          // Keep default '--:--'
        }
      }
    }

    // Status config
    Color statusColor = Colors.grey;
    String statusText = statusStr;

    switch (statusStr) {
      case 'PENDING':
        statusColor = Colors.orange;
        statusText = "En attente";
        break;
      case 'CONFIRMED':
      case 'ACCEPTED':
        statusColor = const Color(0xFF2ECA7F); // green
        statusText = "Confirmé";
        break;
      case 'IN_PROGRESS':
        statusColor = AppColors.primaryBlue;
        statusText = "En cours";
        break;
      case 'COMPLETED':
        statusColor = Colors.blueGrey;
        statusText = "Terminé";
        break;
      case 'CANCELLED':
      case 'DECLINED':
        statusColor = AppColors.actionRed;
        statusText = "Annulé/Refusé";
        break;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header: Status and Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    "Détails du Rendez-vous",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date & Time
            _buildInfoRow(
              icon: Icons.calendar_today_rounded,
              title: "Date et Heure",
              value: formattedDate,
              subtitle: "Fin estimée: $formattedEndTime",
              iconColor: AppColors.primaryBlue,
            ),
            const Divider(height: 32),

            // Person Details
            if (showClientDetails) ...[
              _buildInfoRow(
                icon: Icons.person_outline,
                title: "Client",
                value: clientName,
                subtitle: clientPhone.isNotEmpty ? "Tél: $clientPhone" : null,
                iconColor: Colors.purple,
              ),
              const SizedBox(height: 16),
            ],
            if (showBarberDetails) ...[
              _buildInfoRow(
                icon: Icons.content_cut,
                title: "Spécialiste",
                value: barberName,
                iconColor: Colors.deepOrange,
              ),
              const SizedBox(height: 16),
            ],
            _buildInfoRow(
              icon: Icons.storefront_outlined,
              title: "Salon",
              value: salonName,
              subtitle: salonAddress.isNotEmpty ? salonAddress : null,
              iconColor: Colors.teal,
            ),
            const Divider(height: 32),

            // Services Breakdown
            const Text(
              "Services",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            if (servicesList.isEmpty)
              const Text(
                "Aucun service sélectionné",
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...servicesList.map((s) {
                final service = s['service'] ?? {};
                final name = service['name'] ?? 'Service';
                final price = service['price'] ?? 0;
                final duration = service['durationMinutes'] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "- $name ($duration min)",
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Text(
                        "$price DT",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

            const Divider(height: 32),

            // Total Price & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  "$totalPrice DT",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Fermer",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
