import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class ReviewsTab extends StatelessWidget {
  const ReviewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Note Globale
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("4.9", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.amber, size: 18))),
                const SizedBox(height: 5),
                const Text("Basé sur 120 avis", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit, color: AppColors.primaryBlue),
            label: const Text("Écrire un avis", style: TextStyle(color: AppColors.primaryBlue)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryBlue),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 30),
        
        // Liste des avis
        ...List.generate(3, (index) => Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 15, backgroundColor: Colors.grey[300], child: const Icon(Icons.person, size: 18, color: Colors.white)),
                      const SizedBox(width: 10),
                      const Text("Ahmed B.", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Text("Il y a 2 jours", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 5),
              Row(children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.amber, size: 14))),
              const SizedBox(height: 10),
              const Text("Service impeccable, le dégradé est parfait. Je recommande vivement !", style: TextStyle(color: AppColors.textDark)),
              const Divider(height: 30),
            ],
          ),
        )),
      ],
    );
  }
}