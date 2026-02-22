import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';
// 🚀 N3aytou lel page mta3 l'profil hena zeda
import '../../../salon_profile/presentation/pages/salon_profile_page.dart';

class TopRatedList extends StatelessWidget {
  const TopRatedList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // 🚀 Navigation mel carte lkol
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SalonProfilePage()),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(12),
           decoration: BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(20),
 boxShadow: [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.05), // شفافية عالية جداً
    blurRadius: 30,                              // انتشار واسع للظل
    spreadRadius: 0,
    offset: const Offset(0, 10),                 // الظل يميل للأسفل
  )
]
),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network('https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=500&q=80', height: 90, width: 90, fit: BoxFit.cover),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Salon Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                      SizedBox(height: 4),
                      Text("Adresse de salon...", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      SizedBox(height: 10),
                      Text("à partir de 15 DT", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 🚀 Navigation mel bouton "Réserver"
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SalonProfilePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionRed, 
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                  ),
                  child: const Text("Réserver", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}