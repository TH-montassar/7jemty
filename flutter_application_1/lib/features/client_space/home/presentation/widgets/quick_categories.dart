import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';

class QuickCategories extends StatelessWidget {
  const QuickCategories({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // زر A9reb lik (أزرق)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(25)),
            child: Row(children: const [
              Text("A9reb lik ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Icon(Icons.location_on, color: Colors.white, size: 18),
            ]),
          ),
          const SizedBox(width: 15),
          // زر Top Avis (أبيض)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: Row(children: const [
              Text("Top Avis ", style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
              Icon(Icons.star, color: Colors.grey, size: 18),
              Icon(Icons.star, color: Colors.grey, size: 18),
            ]),
          ),
          const SizedBox(width: 15),
          // زر Produits (دائري)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: Column(children: const [
              Icon(Icons.shopping_cart_outlined, color: Colors.grey, size: 20),
              Text("Produits", style: TextStyle(color: Colors.grey, fontSize: 10)),
            ]),
          ),
        ],
      ),
    );
  }
}