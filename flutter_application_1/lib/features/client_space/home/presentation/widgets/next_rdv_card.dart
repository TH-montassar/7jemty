import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class NextRdvCard extends StatelessWidget {
  const NextRdvCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ), // Shadow خفيف برشا باش يطلع أنيق
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. الهيدر: Prochain Rendez-vous & Voir sur la Map
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Rendez-vous jey",
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              // 🚀 هذي رديناها Clickable باش تهز للماب
              GestureDetector(
                onTap: () {
                  // TODO: حل الـ Google Maps ولا صفحة الخريطة
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Kaaed yhel fel map 🗺️")),
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

          // 2. التاريخ والوقت (Date & Heure)
          Row(
            children: const [
              Icon(
                Icons.calendar_today,
                color: AppColors.textDark,
                size: 20,
              ), // بدلت اللون باش يطابق التصويرة
              SizedBox(width: 12),
              Text(
                "Lyoum, 15:00",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // 3. اسم الصالون والخدمة (Salon & Service)
          Row(
            children: const [
              Icon(Icons.storefront, color: Colors.grey, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Barber King - Coupe Cheveux + Barbe",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis, // باش الكتيبة ما تخرجش على السطر
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4. الوقت المتبقي وحالة الموعد (Statut)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.access_time,
                    color: AppColors.primaryBlue,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Mazel 2h 30min",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              // Badge الأخضر متاع Confirmé
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1), // أخضر شفاف
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text(
                      "M'akd",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
