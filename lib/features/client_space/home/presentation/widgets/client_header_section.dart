import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';

class ClientHeaderSection extends StatelessWidget {
  const ClientHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 40),
      decoration: const BoxDecoration(color: AppColors.primaryBlue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // التحية والإشعارات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Ahla, Sami 👋", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                  Positioned(
                    right: 2, top: 2,
                    child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.actionRed, shape: BoxShape.circle)),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // الموقع والنقاط
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(children: const [
                  Icon(Icons.location_on, color: AppColors.primaryBlue, size: 16),
                  SizedBox(width: 5),
                  Text("Ariana, Tunis", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(color: AppColors.accentYellow, borderRadius: BorderRadius.circular(20)),
                child: Row(children: const [
                  Icon(Icons.emoji_events, color: Colors.black87, size: 16),
                  SizedBox(width: 5),
                  Text("150 Pts", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // شريط البحث
          Container(
            height: 50,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
            child: Row(
              children: [
                const SizedBox(width: 15),
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 10),
                const Expanded(child: TextField(decoration: InputDecoration(hintText: "Lawej 3la salon, service...", border: InputBorder.none, hintStyle: TextStyle(color: Colors.grey)))),
                Container(
                  margin: const EdgeInsets.all(4),
                  width: 42, height: 42,
                  decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle),
                  child: const Icon(Icons.menu, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}