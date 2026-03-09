import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';

class BookingSummaryCard extends StatelessWidget {
  final String serviceName;
  final String serviceDuration;
  final String servicePrice;

  const BookingSummaryCard({
    super.key,
    required this.serviceName,
    required this.serviceDuration,
    required this.servicePrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
        // 👈 Sala7na l'opacity houni zeda
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(serviceDuration, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Text(servicePrice, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}