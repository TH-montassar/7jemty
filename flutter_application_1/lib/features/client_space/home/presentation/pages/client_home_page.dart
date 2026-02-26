import 'package:flutter/material.dart';
import 'package:hjamty/features/client_space/home/presentation/widgets/top_rated_list.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/translation_service.dart'; // Added this import
import '../widgets/client_header_section.dart';
import '../widgets/next_rdv_card.dart';
import '../widgets/quick_categories.dart';
import '../widgets/near_you_list.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgColor,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

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
                      if (_isLoggedIn) ...[
                        const NextRdvCard(),
                        const SizedBox(height: 25),
                      ],

                      Text(
                        tr(context, 'top_categories'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const QuickCategories(),

                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Text(
                            tr(context, 'near_you'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const Icon(
                            Icons.location_on,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const NearYouList(),

                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Text(
                            tr(context, 'top_rated'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.star_border,
                            color: Colors.grey,
                            size: 20,
                          ),
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
      // TODO: Remove this FloatingActionButton once FCM is fully integrated
      floatingActionButton: _isLoggedIn
          ? FloatingActionButton(
              onPressed: () => _showReviewModal(context),
              backgroundColor: AppColors.primaryBlue,
              child: const Icon(
                Icons.notifications_active,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  void _showReviewModal(BuildContext context) {
    int _rating = 5;
    TextEditingController _reviewController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                  const Text(
                    "Sa77atoulek!",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Rendez-vous mte3ek maa Ahmed fi salon 'Barbershop VIP' kmal.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "3jebtek l7jema?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        onPressed: () {
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
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(tr(context, 'review_sent')),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        tr(context, 'send_review'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      tr(context, 'skip'),
                      style: TextStyle(color: Colors.grey),
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
}
