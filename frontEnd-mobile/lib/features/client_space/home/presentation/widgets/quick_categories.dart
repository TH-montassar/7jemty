import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';

class QuickCategories extends StatefulWidget {
  const QuickCategories({super.key});

  @override
  State<QuickCategories> createState() => _QuickCategoriesState();
}

class _QuickCategoriesState extends State<QuickCategories> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 💡 هذي ليستة الخدمات الصحيحة
    final List<Map<String, dynamic>> _categories = [
      {'title': tr(context, 'category_haircut'), 'icon': Icons.content_cut},
      {'title': tr(context, 'category_beard'), 'icon': Icons.face},
      {'title': tr(context, 'category_facial'), 'icon': Icons.spa_outlined},
      {'title': tr(context, 'category_kids'), 'icon': Icons.child_care},
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedIndex = index);
              // TODO: نزيدو اللوجيك باش نفيلتريو الصالونات اللوطة
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.transparent),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Icon(
                    _categories[index]['icon'],
                    color: isSelected ? Colors.white : Colors.black87,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _categories[index]['title'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
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
