import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/features/client_space/appointments/data/appointment_service.dart';

void showReviewModalBottomSheet(
  BuildContext context,
  Map<String, dynamic> appointmentData, {
  VoidCallback? onReviewSubmitted,
}) {
  int _rating = 5;
  TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  final barberName = appointmentData['barber']?['fullName'] ?? 'Barber';
  final salonName = appointmentData['salon']?['name'] ?? 'Salon';
  final appointmentId = appointmentData['id'] as int;
  final salonId = appointmentData['salonId'] as int;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false, // Force them to review or hit "Fout"
    enableDrag: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateModal) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.check_circle,
                  color: AppColors.successGreen,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  tr(context, 'review_modal_title'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr(
                    context,
                    'review_modal_desc',
                    args: [barberName, salonName],
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Text(
                  tr(context, 'review_modal_question'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              setStateModal(() {
                                _rating = index + 1;
                              });
                            },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _reviewController,
                  maxLines: 3,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    hintText: tr(context, 'review_comment_hint'),
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            setStateModal(() {
                              _isSubmitting = true;
                            });
                            try {
                              await AppointmentService.submitReview(
                                appointmentId: appointmentId,
                                salonId: salonId,
                                rating: _rating,
                                comment: _reviewController.text.trim(),
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      tr(context, 'review_sent_thank_you'),
                                    ),
                                    backgroundColor: AppColors.successGreen,
                                  ),
                                );
                                if (onReviewSubmitted != null) {
                                  onReviewSubmitted();
                                }
                              }
                            } catch (e) {
                              setStateModal(() {
                                _isSubmitting = false;
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: AppColors.actionRed,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            tr(context, 'submit_review_btn'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context),
                  child: Text(
                    tr(context, 'skip_btn'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
