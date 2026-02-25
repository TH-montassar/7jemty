import 'package:flutter/material.dart';
import 'package:hjamty/features/client_space/home/presentation/widgets/top_rated_list.dart';
import '../../../../../core/constants/app_colors.dart';
import '../widgets/client_header_section.dart';
import '../widgets/next_rdv_card.dart';
import '../widgets/quick_categories.dart';
import '../widgets/near_you_list.dart';

// 🚀 Radineha StatelessWidget 5ater ma3adech fiha BottomNav w state
class ClientHomePage extends StatelessWidget {
  const ClientHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. الهيدر
            const ClientHeaderSection(),

            // 2. المحتوى
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.bgColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const NextRdvCard(),

                      const SizedBox(height: 25),
                      const Text(
                        "Catégories Rapides",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const QuickCategories(),

                      const SizedBox(height: 30),
                      Row(
                        children: const [
                          Text(
                            "Salons 9rab Lik ",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Icon(Icons.location_on, color: Colors.grey, size: 20),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const NearYouList(),

                      const SizedBox(height: 30),
                      Row(
                        children: const [
                          Text(
                            "Les Meilleurs Salons ",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Icon(Icons.star_border, color: Colors.grey, size: 20),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const TopRatedList(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}