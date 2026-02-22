import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class ServicesTab extends StatelessWidget {
  const ServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      {'name': 'Coupe Classique', 'time': '30 min', 'price': '15 DT'},
      {'name': 'Dégradé Américain', 'time': '45 min', 'price': '20 DT'},
      {'name': 'Taille de Barbe', 'time': '20 min', 'price': '10 DT'},
      {'name': 'Soin Visage (Masque)', 'time': '30 min', 'price': '25 DT'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final s = services[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text(s['time']!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 5),
                    Text(s['price']!, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Go to Booking Flow
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.actionRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Réserver", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}