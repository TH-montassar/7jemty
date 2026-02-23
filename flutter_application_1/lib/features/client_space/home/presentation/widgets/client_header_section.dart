import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_colors.dart';

class ClientHeaderSection extends StatelessWidget {
  const ClientHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 هذي باش تحسب طول الـ Status Bar متاع أي تليفون
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      // 👈 نقصنا في الـ top والـ bottom باش الهيدر يتلم ويصغار
      padding: EdgeInsets.only(top: statusBarHeight + 15, left: 20, right: 20, bottom: 30),
      decoration: const BoxDecoration(color: AppColors.primaryBlue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. التحية والإشعارات
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
                    child: Container(
                      width: 10, 
                      height: 10, 
                      decoration: const BoxDecoration(color: AppColors.actionRed, shape: BoxShape.circle)
                    ),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 20), // 👈 نقصنا في الفراغ
          
          // 2. الموقع (Location) 
          Center(
            child: GestureDetector(
              onTap: () {
                // TODO: حل بوب أب باش يبدل البلاصة
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.location_on, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Ariana, Tunis", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20), // 👈 نقصنا في الفراغ

          // 3. شريط البحث
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(16), 
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                )
              ]
            ),
            child: Row(
              children: [
                const SizedBox(width: 15),
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 10),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Lawej 3la salon, service...", 
                      border: InputBorder.none, 
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14)
                    )
                  )
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.tune_rounded, color: AppColors.primaryBlue), 
                ),
                const SizedBox(width: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}