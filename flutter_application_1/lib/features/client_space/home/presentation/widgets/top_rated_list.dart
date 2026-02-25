import 'package:flutter/material.dart';
import 'package:hjamty/features/client_space/salon_profile/presentation/pages/salon_profile_page.dart';
import '../../../../../core/constants/app_colors.dart';
// 🚀 1. هوني زادة أعمل Import لصفحة الصالون باش كي يكليكي تهزو ليها
// import '../../salon_profile/presentation/pages/salon_profile_page.dart';

class TopRatedList extends StatelessWidget {
  const TopRatedList({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 Mock Data: ليستة أحسن الصالونات
    final List<Map<String, dynamic>> topSalons = [
      {
        'name': 'Barber King 👑',
        'address': 'Avenue Habib Bourguiba, Ariana',
        'price': 'à partir de 15 DT',
        'image': 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=500&q=80',
      },
      {
        'name': 'The Classic Barber',
        'address': 'Ennasr 2, Tunis',
        'price': 'à partir de 20 DT',
        'image': 'https://images.unsplash.com/photo-1503342394128-c104d54dba01?auto=format&fit=crop&w=500&q=80',
      },
      {
        'name': 'Salon El Baze',
        'address': 'Menzah 5, Ariana',
        'price': 'à partir de 12 DT',
        'image': 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?auto=format&fit=crop&w=500&q=80',
      },
    ];

    return ListView.builder(
      shrinkWrap: true, // 🚀 مهمة برشا باش تخدم في وسط SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // باش السكرول يتبع الصفحة كاملة موش الليستة بركا
      padding: EdgeInsets.zero, // باش نحيو الفراغ الزايد من الفوق
      itemCount: topSalons.length,
      itemBuilder: (context, index) {
        final salon = topSalons[index];
        
        return GestureDetector(
          onTap: () {
            // 🚀 2. كي يكليكي على الكارطة يهزو لبروفيل الصالون
           
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
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // --- 1. التصويرة اللّي على اليسار ---
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    salon['image'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    // 🚀 3. نحيو الـ X الحمراء كان التصويرة ما تخدمش
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.storefront, color: Colors.grey, size: 30),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 15),
                
                // --- 2. المعلومات (الاسم، العنوان، السوم) ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        salon['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        salon['address'],
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        salon['price'],
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // --- 3. فلسة Réserver ---
                SizedBox(
                  height: 35,
                  child: ElevatedButton(
                    onPressed: () {
                      // 🚀 هوني تنجم تهزو ديركت لصفحة الحجز زادة كان تحب
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SalonProfilePage()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.actionRed, // اللون الوردي/الأحمر
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      "Réserver",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}