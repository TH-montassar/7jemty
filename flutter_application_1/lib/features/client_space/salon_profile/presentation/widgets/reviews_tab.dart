import 'package:hjamty/core/localization/translation_service.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class ReviewsTab extends StatelessWidget {
  const ReviewsTab({super.key});

  // 🚀 1. هذي الفونكسيون اللّي تطلع النافذة من اللوطة (حطيناها الفوق قبل الـ build)
  void _showAddReviewSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        int selectedStars = 0; 

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 25,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 20),
                    
                    Text(tr(context, 'rate_this_salon'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < selectedStars ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 40,
                          ),
                          onPressed: () {
                            setModalState(() {
                              selectedStars = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Racontez votre expérience...",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: AppColors.bgColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(15),
                      ),
                    ),
                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: selectedStars > 0 ? () {
                          Navigator.pop(context); 
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr(context, 'thank_you_for_review')),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: Text(tr(context, 'send_the_review'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🚀 2. هذا الـ UI متاع الصفحة 
  @override
  Widget build(BuildContext context) {
    // Mock Data
    final List<Map<String, dynamic>> reviews = [
      {'name': 'Ahmed B.', 'date': 'Il y a 2 jours', 'rating': 5, 'comment': 'Service impeccable, le dégradé est parfait. Je recommande vivement !'},
      {'name': 'Karim M.', 'date': 'Il y a 1 semaine', 'rating': 5, 'comment': 'Très bon salon, coiffeur à l\'écoute. Ambiance au top.'},
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // الهيدر متاع النجوم
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(tr(context, 'rating_4_9'), style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.amber, size: 18))),
                const SizedBox(height: 5),
                Text(tr(context, 'based_on_120_reviews'), style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 🚀 3. الفلسة اللّي تعيط للـ Bottom Sheet
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              _showAddReviewSheet(context); // نعيطولها هوني
            },
            icon: const Icon(Icons.edit, size: 18),
            label: Text(tr(context, 'write_a_review'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: const BorderSide(color: AppColors.primaryBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
        const SizedBox(height: 30),

        // ليستة الكومنتارات
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => const Divider(height: 30, color: Colors.black12),
          itemBuilder: (context, index) {
            final r = reviews[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 20, backgroundColor: Colors.grey.shade200, child: const Icon(Icons.person, color: Colors.grey)),
                    const SizedBox(width: 15),
                    Expanded(child: Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark))),
                    Text(r['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(children: List.generate(5, (starIndex) => Icon(starIndex < r['rating'] ? Icons.star : Icons.star_border, color: Colors.amber, size: 16))),
                const SizedBox(height: 10),
                Text(r['comment'], style: const TextStyle(color: AppColors.textDark, height: 1.4)),
              ],
            );
          },
        ),
      ],
    );
  }
}
