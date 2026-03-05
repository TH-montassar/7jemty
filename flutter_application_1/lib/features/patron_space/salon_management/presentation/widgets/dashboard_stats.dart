import 'package:hjamty/core/localization/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:hjamty/core/widgets/info_card.dart';

class DashboardStats extends StatelessWidget {
  const DashboardStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- كارت الاشتراك ---
        Expanded(
          child: InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Abonnement',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Statut: Actif',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '4',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'RDV restants',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(tr(context, 'renew_btn')),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // --- كارت النقاط ---
        Expanded(
          child: InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Points Fidélité',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.star_border, color: Colors.blue, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Points: 1200',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Prochaine récompense: 2800 pts',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 1200 / 2800,
                    backgroundColor: Colors.grey[200],
                    color: Colors.blue,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
