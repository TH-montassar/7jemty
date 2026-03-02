import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/translation_service.dart';
import 'package:intl/intl.dart';

class NextRdvCard extends StatelessWidget {
  final Map<String, dynamic>? appointmentData;

  const NextRdvCard({super.key, this.appointmentData});

  @override
  Widget build(BuildContext context) {
    if (appointmentData == null) {
      return const SizedBox.shrink();
    }

    final apt = appointmentData!;
    final salonName = apt['salon']?['name'] ?? 'Salon inconnu';
    final barberName =
        apt['barber']?['fullName'] ?? 'Professionnel non assigné';

    // Format date
    final dateStr = apt['appointmentDate'];
    final DateTime date = dateStr != null
        ? DateTime.parse(dateStr).toLocal()
        : DateTime.now();

    final formattedDate = DateFormat('dd MMM - HH:mm', 'fr_FR').format(date);

    final status = (apt['status'] as String? ?? 'PENDING').toUpperCase();
    Color statusColor = status == 'CONFIRMED'
        ? const Color(0xFF2ECA7F)
        : (status == 'IN_PROGRESS' ? AppColors.primaryBlue : Colors.orange);
    String statusText = status == 'CONFIRMED'
        ? 'M\'akd'
        : (status == 'IN_PROGRESS' ? 'En cours' : 'En attente');

    // Countdown logic
    final now = DateTime.now();
    final difference = date.difference(now);

    String countdownText = "";
    if (status == 'CONFIRMED' || status == 'PENDING') {
      if (difference.isNegative) {
        countdownText = "L'wa9t r7el";
      } else if (difference.inHours > 0) {
        countdownText =
            "Mazal ${difference.inHours}h ${difference.inMinutes % 60}min";
      } else {
        countdownText = "Mazal ${difference.inMinutes}min";
      }
    }

    // Extract services and total price
    final servicesList = apt['services'] as List<dynamic>? ?? [];
    final serviceNames = servicesList.isNotEmpty
        ? servicesList.map((s) => s['service']['name']).join(' + ')
        : 'Service';
    final price = apt['totalPrice'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Prochain Rendez-vous & Voir sur la Map
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr(context, 'next_appointment'),
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr(context, 'opening_map'))),
                  );
                },
                child: const Text(
                  "Chouf fil map 🗺️",
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Date format Box & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "📅 $formattedDate",
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (countdownText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        countdownText,
                        style: const TextStyle(
                          color: AppColors.actionRed,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Salon Name
          Text(
            "$salonName 👑",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 5),

          // Services & Price
          Row(
            children: [
              const Icon(Icons.cut, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  "$serviceNames - $price DT",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Professional Name
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  "Professionnel: $barberName",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
