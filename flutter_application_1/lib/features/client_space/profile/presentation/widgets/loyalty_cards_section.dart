import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class LoyaltyCardsSection extends StatelessWidget {
  const LoyaltyCardsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 2, 
        itemBuilder: (context, index) {
          bool isFirst = index == 0;
          return Container(
            width: 260,
            margin: const EdgeInsets.only(right: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isFirst ? "Barber King 👑" : "The Classic Barber", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    Text(isFirst ? "3/5" : "1/5", style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (stampIndex) {
                    int currentStamps = isFirst ? 3 : 1;
                    bool isStamped = stampIndex < currentStamps;
                    return Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: isStamped ? AppColors.primaryBlue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: isStamped ? AppColors.primaryBlue : Colors.transparent),
                      ),
                      child: Icon(
                        Icons.cut, 
                        size: 16, 
                        color: isStamped ? AppColors.primaryBlue : Colors.grey.withValues(alpha: 0.5)
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}