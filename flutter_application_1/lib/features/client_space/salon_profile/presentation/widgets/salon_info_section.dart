import 'package:hjamty/core/localization/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class SalonInfoSection extends StatelessWidget {
  final Map<String, dynamic> salonData;

  const SalonInfoSection({super.key, required this.salonData});

  @override
  Widget build(BuildContext context) {
    // Determine current open/close status
    final now = DateTime.now();
    final currentDay = now.weekday; // Lundi = 1, Dimanche = 7

    final workingHours = salonData['workingHours'] as List<dynamic>? ?? [];
    final todayHours = workingHours.firstWhere(
      (wh) => wh['dayOfWeek'] == currentDay,
      orElse: () => null,
    );

    bool isOpen = false;
    String? closeTimeStr;

    if (todayHours != null) {
      final isDayOff = todayHours['isDayOff'] ?? false;
      if (!isDayOff) {
        final oTime = todayHours['openTime'] as String?;
        final cTime = todayHours['closeTime'] as String?;
        if (oTime != null && cTime != null) {
          try {
            final format = DateFormat.Hm();
            final openDT = format.parse(oTime);
            final closeDT = format.parse(cTime);
            final currentDT = DateTime(1970, 1, 1, now.hour, now.minute);

            if (currentDT.isAfter(openDT) && currentDT.isBefore(closeDT)) {
              isOpen = true;
              closeTimeStr = DateFormat.jm().format(closeDT); // e.g. 8:00 PM
            }
          } catch (_) {
            isOpen = true;
            closeTimeStr = cTime;
          }
        }
      }
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Pill
          if (salonData['speciality'] != null &&
              salonData['speciality'].toString().isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                salonData['speciality'].toString().toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),

          // Salon Name
          Text(
            salonData['name'] ?? 'Salon',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),

          // Rating, Reviews, Distance Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.black, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      salonData['rating']?.toString() ?? '5.0',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${salonData['reviews']?.length ?? 1} avis',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '•',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(width: 10),
              const Text(
                '3.5 km', // Hardcoded distance as in screenshot
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const Divider(height: 40, color: Color(0xFFF5F5F5)),

          // Address & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primaryBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            salonData['address'] ??
                                tr(context, 'address_ariana'),
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: AppColors.primaryBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOpen
                              ? 'Ouvert jusqu\'à ${closeTimeStr ?? ''}'
                              : 'Fermé actuellement',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isOpen
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOpen ? 'OUVERT' : 'FERMÉ',
                  style: TextStyle(
                    color: isOpen ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
