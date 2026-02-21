import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';

class NextRdvCard extends StatelessWidget {
  const NextRdvCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Prochain Rendez-vous", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 15)),
              Text("Voir sur la Map 🗺️", style: TextStyle(color: AppColors.primaryBlue, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: const [
              Icon(Icons.event_note, color: AppColors.primaryBlue),
              SizedBox(width: 10),
              Text("Aujourdhui, 15:00", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.storefront, color: Colors.grey, size: 20),
              SizedBox(width: 10),
              Text("Barber King - Coupe Cheveux + Barbe", style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: const [
                Icon(Icons.schedule, color: AppColors.primaryBlue, size: 18),
                SizedBox(width: 5),
                Text("Dans 2h 30min", style: TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
             Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: const Color(0xFFE8F8F0), // خلفية خضراء فاتحة جداً
    borderRadius: BorderRadius.circular(8)
  ),
  child: const Text("✓ Confirmé", style: TextStyle(color: Color(0xFF2ECA7F), fontWeight: FontWeight.bold, fontSize: 12)), // لون أخضر هادي
)
            ],
          ),
        ],
      ),
    );
  }
}