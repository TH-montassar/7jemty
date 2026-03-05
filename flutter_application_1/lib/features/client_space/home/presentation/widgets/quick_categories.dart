import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';

class QuickCategories extends StatefulWidget {
  const QuickCategories({super.key});

  @override
  State<QuickCategories> createState() => _QuickCategoriesState();
}

class _QuickCategoriesState extends State<QuickCategories> {
  int _selectedIndex = 0;

  // 💡 هذي ليستة الخدمات الصحيحة
  final List<Map<String, dynamic>> _categories = [
    {'title': 'Hjema', 'icon': Icons.content_cut},
    {'title': 'Lihya', 'icon': Icons.face},
    {'title': 'Soin Visage', 'icon': Icons.spa_outlined},
    {'title': 'Sghar', 'icon': Icons.child_care},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedIndex = index);
              // TODO: نزيدو اللوجيك باش نفيلتريو الصالونات اللوطة
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : Colors.grey.shade300,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    _categories[index]['icon'],
                    color: isSelected ? Colors.white : AppColors.textDark,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _categories[index]['title'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
