import 'package:hjamty/core/localization/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/features/client_space/salon_profile/data/salon_service.dart';

class ReviewsTab extends StatefulWidget {
  final Map<String, dynamic> salonData;
  final bool allowReport;

  const ReviewsTab({
    super.key,
    required this.salonData,
    this.allowReport = false,
  });

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  Future<void> _showReportDialog(int reviewId) async {
    final controller = TextEditingController();
    String selectedReason = 'INAPPROPRIATE';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tr(context, 'report_review_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedReason,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'INAPPROPRIATE',
                    child: Text('Inappropriate language'),
                  ),
                  DropdownMenuItem(
                    value: 'SPAM',
                    child: Text('Spam / fake review'),
                  ),
                  DropdownMenuItem(
                    value: 'HARASSMENT',
                    child: Text('Harassment / insult'),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setDialogState(() => selectedReason = v);
                },
                decoration: InputDecoration(
                  labelText: tr(context, 'report_reason_label'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: tr(context, 'report_review_hint'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr(context, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr(context, 'report_btn')),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await SalonService.reportReview(
        reviewId,
        reason: selectedReason,
        message: controller.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'report_review_success'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // 🚀 1. هذي الفونكسيون اللّي تطلع النافذة من اللوطة (حطيناها الفوق قبل الـ build)
  // 🚀 The _showAddReviewSheet was removed here because reviews should be tied to specific appointments.
  // Users leave reviews via their Appointments History.

  @override
  Widget build(BuildContext context) {
    final List reviews = widget.salonData['reviews'] ?? [];
    final int reviewsCount = reviews.length;
    final String avgRating = reviewsCount == 0
        ? "0.0"
        : (widget.salonData['rating']?.toString() ?? "0.0");
    final double avgRatingValue = double.tryParse(avgRating) ?? 0.0;

    // ignore: avoid_print
    debugPrint('[ReviewsTab] salonData keys: ${widget.salonData.keys.toList()}');
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
                      color: index < avgRatingValue.floor()
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
                      if (widget.allowReport)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'report') {
                              final reviewId = (r['id'] as num?)?.toInt();
                              if (reviewId != null && reviewId > 0) {
                                _showReportDialog(reviewId);
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'report',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.priority_high_rounded,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(tr(context, 'report_btn')),
                                ],
                              ),
                            ),
                          ],
                          icon: const Icon(Icons.more_vert_rounded),
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
