import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';

class NearYouList extends StatelessWidget {
  const NearYouList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          return Container(
            width: 130,
            margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.network('https://images.unsplash.com/photo-1503951914875-452162b7f30a?auto=format&fit=crop&w=500&q=80', height: 90, width: double.infinity, fit: BoxFit.cover),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Barber Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: const [Icon(Icons.location_on, size: 12, color: AppColors.primaryBlue), Text(" 1.2 km", style: TextStyle(fontSize: 11, color: Colors.grey))]),
                          Row(children: const [Icon(Icons.star, size: 12, color: AppColors.primaryBlue), Text(" 4.8", style: TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.bold))]),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}