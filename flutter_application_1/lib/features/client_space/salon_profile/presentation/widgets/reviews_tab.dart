import 'package:hjamty/core/localization/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';

class ReviewsTab extends StatelessWidget {
  final Map<String, dynamic> salonData;

  const ReviewsTab({super.key, required this.salonData});

  // 🚀 1. هذي الفونكسيون اللّي تطلع النافذة من اللوطة (حطيناها الفوق قبل الـ build)
  // 🚀 The _showAddReviewSheet was removed here because reviews should be tied to specific appointments.
  // Users leave reviews via their Appointments History.

  @override
  Widget build(BuildContext context) {
    final List reviews = salonData['reviews'] ?? [];
    final String avgRating = salonData['rating']?.toString() ?? "4.5";
    final int reviewsCount = reviews.length;

    // ignore: avoid_print
    debugPrint('[ReviewsTab] salonData keys: ${salonData.keys.toList()}');
    // ignore: avoid_print
    debugPrint(
      '[ReviewsTab] reviews length: $reviewsCount, avgRating: $avgRating',
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Rating Overview Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              avgRating,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      Icons.star,
                      color: index < double.parse(avgRating).floor()
                          ? Colors.amber
                          : Colors.grey.shade300,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr(
                    context,
                    'based_on_n_reviews',
                    args: [reviewsCount.toString()],
                  ),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 25),

        const SizedBox(height: 10),
        const SizedBox(height: 30),

        if (reviews.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr(context, 'no_reviews_yet'),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            ),
          )
        else
          // Reviews List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 40, color: Colors.black12),
            itemBuilder: (context, index) {
              final r = reviews[index];
              final String clientName = r['clientName'] ?? 'Client';
              final String? clientImage = r['clientImage'];
              final int rating = r['rating'] ?? 5;
              final String comment = r['comment'] ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                          image: clientImage != null
                              ? DecorationImage(
                                  image: NetworkImage(clientImage),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: clientImage == null
                            ? const Icon(
                                Icons.person,
                                color: AppColors.primaryBlue,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textDark,
                              ),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (starIndex) => Icon(
                                  Icons.star,
                                  color: starIndex < rating
                                      ? Colors.amber
                                      : Colors.grey.shade300,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Text(
                        comment,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          height: 1.5,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        const SizedBox(height: 50),
      ],
    );
  }
}
