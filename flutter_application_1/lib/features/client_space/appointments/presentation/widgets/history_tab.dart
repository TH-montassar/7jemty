import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/translation_service.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy mixed data
    final List<Map<String, dynamic>> appointments = [
      {
        "date": "10 Janvier 2024",
        "status": tr(context, 'status_completed'),
        "salon": "The Classic Barber",
        "service": "Dégradé Américain - 20 DT",
      },
      {
        "date": "5 Février 2024",
        "status": tr(context, 'status_cancelled'),
        "salon": "Salon El Baze",
        "service": "Hjema Classique",
      },
      {
        "date": "20 Décembre 2023",
        "status": tr(context, 'status_completed'),
        "salon": "The Classic Barber",
        "service": "Hjema + Lihya - 35 DT",
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final apt = appointments[index];
        final isCancelled = apt["status"] == tr(context, 'status_cancelled');

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: isCancelled
                ? Border.all(color: Colors.red.withValues(alpha: 0.2))
                : null,
            boxShadow: isCancelled
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    apt["date"],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      apt["status"],
                      style: TextStyle(
                        color: isCancelled ? AppColors.actionRed : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                apt["salon"],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCancelled ? Colors.grey : AppColors.textDark,
                ),
              ),
              Text(
                apt["service"],
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                ),
              ),
              if (!isCancelled) ...[
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.amber),
                          foregroundColor: Colors.amber[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(tr(context, 'leave_review')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue.withValues(
                            alpha: 0.1,
                          ),
                          foregroundColor: AppColors.primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(tr(context, 'book_again')),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
