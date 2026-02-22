import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class SalonInfoSection extends StatelessWidget {
  const SalonInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  "Barber King 👑",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text("Ouvert", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              // TODO: Ouvre GPS
            },
            child: Row(
              children: const [
                Icon(Icons.location_on, color: AppColors.primaryBlue, size: 18),
                SizedBox(width: 5),
                Text("Avenue Habib Bourguiba, Ariana", style: TextStyle(color: Colors.grey, fontSize: 14, decoration: TextDecoration.underline)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: const [
              Icon(Icons.star, color: Colors.amber, size: 20),
              SizedBox(width: 5),
              Text("4.9", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(" (120 avis)", style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}