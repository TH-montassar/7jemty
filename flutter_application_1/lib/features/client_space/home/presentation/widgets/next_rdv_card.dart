import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/translation_service.dart';
import 'package:intl/intl.dart';

class NextRdvCard extends StatelessWidget {
  final Map<String, dynamic>? appointmentData;

  const NextRdvCard({super.key, this.appointmentData});

  @override
  Widget build(BuildContext context) {
    // If appointmentData is null, we return nothing
    if (appointmentData == null) {
      return const SizedBox.shrink();
    }

    final dateStr = appointmentData!['date'] as String?;
    final timeStr = appointmentData!['time'] ?? '00:00';
    final salonData = appointmentData!['salon'] as Map<String, dynamic>?;
    final salonName = salonData?['name'] ?? 'Salon';

    DateTime? parsedDate;
    if (dateStr != null) {
      try {
        parsedDate = DateTime.parse(dateStr).toLocal();
      } catch (_) {}
    }
    final dateToDisplay = parsedDate ?? DateTime.now();

    // Determine the difference to show 'Mazel [time]'
    final appointmentDateTime = DateTime(
      dateToDisplay.year,
      dateToDisplay.month,
      dateToDisplay.day,
      int.tryParse(timeStr.split(':').first) ?? 0,
      int.tryParse(timeStr.split(':').last) ?? 0,
    );
    final now = DateTime.now();
    final difference = appointmentDateTime.difference(now);

    String timeLeft = '';
    if (difference.isNegative) {
      timeLeft = "L'wa9t r7el";
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      if (hours > 24) {
        timeLeft = 'Mazal ${difference.inDays} jour(s)';
      } else if (hours > 0) {
        timeLeft = 'Mazal ${hours}h ${minutes}min';
      } else {
        timeLeft = 'Mazal ${minutes}min';
      }
    }

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
              Text(
                tr(context, 'next_appointment'),
                style: const TextStyle(
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
                    SnackBar(content: Text(tr(context, 'opening_map'))),
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
            children: [
              const Icon(
                Icons.calendar_today,
                color: AppColors.textDark,
                size: 20,
              ), // بدلت اللون باش يطابق التصويرة
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "${DateFormat('dd/MM/yyyy').format(dateToDisplay)} à $timeStr",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // 3. اسم الصالون والخدمة (Salon & Service)
          Row(
            children: [
              const Icon(Icons.storefront, color: Colors.grey, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  salonName,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Badge الأخضر متاع Confirmé
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF2ECA7F,
                      ).withValues(alpha: 0.1), // أخضر شفاف
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check, color: Color(0xFF2ECA7F), size: 14),
                        SizedBox(width: 4),
                        Text(
                          "M'akd",
                          style: TextStyle(
                            color: Color(0xFF2ECA7F),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (timeLeft.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        timeLeft,
                        style: const TextStyle(
                          color: AppColors.actionRed,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
