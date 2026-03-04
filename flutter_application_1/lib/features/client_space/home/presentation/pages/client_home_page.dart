import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hjamty/features/client_space/home/presentation/widgets/top_rated_list.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/translation_service.dart'; // Added this import
import '../../../../../services/auth_service.dart';
import '../../../../../services/appointment_service.dart';
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
  String _clientName = "Client";
  Map<String, dynamic>? _nextAppointment;
  Timer? _pollingTimer;
  bool _isReviewModalShowing = false;
  final Set<int> _shownReviewApptIds = {}; // Track shown modals

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchAppointmentsSilent();
    });
  }

  Future<void> _fetchAppointmentsSilent() async {
    if (!_isLoggedIn) return;

    try {
      final appointments = await AppointmentService.getClientAppointments();

      Map<String, dynamic>? upcoming;
      for (var appt in appointments) {
        if (appt['status'] == 'CONFIRMED') {
          upcoming = appt;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _nextAppointment = upcoming;
        });
      }

      // Automatically pop the review modal if the barber just finished
      if (!_isReviewModalShowing) {
        final unreviewedAppts =
            await AppointmentService.getUnreviewedAppointments();
        if (unreviewedAppts.isNotEmpty) {
          final nextToReview = unreviewedAppts.first;
          final aptId = nextToReview['id'] as int;

          if (!_shownReviewApptIds.contains(aptId) && mounted) {
            _shownReviewApptIds.add(aptId);
            _isReviewModalShowing = true;
            _showReviewModal(context, nextToReview);
          }
        }
      }
    } catch (e) {
      // Ignore errors during silent background fetch
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token != null && token.isNotEmpty) {
      try {
        final userDataResp = await AuthService.getMe();
        final appointments = await AppointmentService.getClientAppointments();

        // Find nearest CONFIRMED appointment
        Map<String, dynamic>? upcoming;
        for (var appt in appointments) {
          if (appt['status'] == 'CONFIRMED') {
            upcoming = appt;
            break;
          }
        }

        if (mounted) {
          setState(() {
            _isLoggedIn = true;
            _clientName = (userDataResp['data']?['fullName'] ?? 'Client')
                .split(' ')
                .first;
            _nextAppointment = upcoming;
          });
        }

        // Silence old unreviewed appointments on startup
        try {
          final unreviewedAppts =
              await AppointmentService.getUnreviewedAppointments();
          if (unreviewedAppts.isNotEmpty) {
            for (var appt in unreviewedAppts) {
              final aptId = appt['id'] as int;
              _shownReviewApptIds.add(aptId);
            }
          }
        } catch (_) {}
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoggedIn = true;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
        });
      }
    }

    if (mounted) {
      setState(() {
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
      backgroundColor:
          AppColors.primaryBlue, // The space under the notch will be blue
      body: SafeArea(
        bottom: false,
        child: Container(
          color:
              AppColors.bgColor, // Below the header, background is light gray
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 1. الهيدر
                ClientHeaderSection(userName: _clientName),

                // 2. المحتوى
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.bgColor,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          if (_isLoggedIn && _nextAppointment != null) ...[
                            NextRdvCard(appointmentData: _nextAppointment),
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
        ),
      ),
      // TODO: Remove this FloatingActionButton once FCM is fully integrated
      floatingActionButton: _isLoggedIn
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.primaryBlue,
              child: const Icon(
                Icons.notifications_active,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  void _showReviewModal(
    BuildContext context,
    Map<String, dynamic> appointmentData,
  ) {
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
                  const Text(
                    "Sa77a L'7jema!",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Rendez-vous mte3ek maa $barberName fi salon '$salonName' kmal.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                      hintText: "Khali commentaire (optionnel)...",
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
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        tr(context, 'review_sent_thank_you'),
                                      ),
                                      backgroundColor: AppColors.successGreen,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setStateModal(() {
                                  _isSubmitting = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: AppColors.actionRed,
                                  ),
                                );
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
                          : const Text(
                              "Abaath l'avis",
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
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text(
                      "Fout",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isReviewModalShowing = false;
        });
      }
    });
  }
}
