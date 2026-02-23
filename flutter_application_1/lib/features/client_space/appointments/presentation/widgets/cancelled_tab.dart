import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class CancelledTab extends StatelessWidget {
  const CancelledTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 1,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("5 Février 2024", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                    child: const Text("Annulé", style: TextStyle(color: AppColors.actionRed, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text("Salon El Baze", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
              const Text("Coupe Classique", style: TextStyle(color: Colors.grey, fontSize: 13, decoration: TextDecoration.lineThrough)),
            ],
          ),
        );
      },
    );
  }
}