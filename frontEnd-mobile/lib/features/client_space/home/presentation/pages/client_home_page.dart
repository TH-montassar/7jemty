import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hjamty/features/client_space/home/presentation/widgets/top_rated_list.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/features/auth/data/auth_service.dart';
import 'package:hjamty/features/client_space/appointments/data/appointment_service.dart';
import 'package:hjamty/core/services/location_service.dart';
import 'package:hjamty/core/services/fcm_service.dart';
import 'package:hjamty/features/client_space/home/presentation/widgets/client_header_section.dart';
import 'package:hjamty/features/client_space/home/presentation/widgets/next_rdv_card.dart';
import 'package:hjamty/features/client_space/home/presentation/widgets/quick_categories.dart';
import 'package:hjamty/features/client_space/home/presentation/widgets/near_you_list.dart';
import 'package:hjamty/features/client_space/appointments/presentation/widgets/review_modal_bottom_sheet.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:hjamty/features/client_space/search/presentation/pages/search_page.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  final AppLocationService _locationService = AppLocationService.instance;
  bool _isLoggedIn = false;
  String _clientName = "Client";
  Map<String, dynamic>? _nextAppointment;
  StreamSubscription<Map<String, dynamic>>? _fcmSubscription;
  bool _isReviewModalShowing = false;
  final Set<int> _shownReviewApptIds = {}; // Track shown modals

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _setupFcmListener();
    unawaited(_locationService.initialize());
  }

  void _setupFcmListener() {
    _fcmSubscription = FcmService.messageStream.listen((data) {
      if (data['type'] == 'APPOINTMENT_UPDATED') {
        _fetchAppointmentsSilent();
      }
    });
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    super.dispose();
  }

  String _normalizeStatus(dynamic rawStatus) {
    final status = (rawStatus as String? ?? '').toUpperCase();
    return status == 'ARRIVED' ? 'IN_PROGRESS' : status;
  }

  int _statusPriority(String status) {
    if (status == 'IN_PROGRESS') return 0;
    if (status == 'CONFIRMED') return 1;
    return 2;
  }

  DateTime _safeAppointmentDate(Map<String, dynamic> appt) {
    return DateTime.tryParse((appt['appointmentDate'] ?? '').toString())
            ?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  Map<String, dynamic>? _pickNextAppointment(List<dynamic> appointments) {
    final activeAppointments = appointments
        .whereType<Map>()
        .map((a) => Map<String, dynamic>.from(a))
        .where((a) {
          final status = _normalizeStatus(a['status']);
          return status == 'IN_PROGRESS' || status == 'CONFIRMED';
        })
        .toList();

    if (activeAppointments.isEmpty) {
      return null;
    }

    activeAppointments.sort((a, b) {
      final statusA = _normalizeStatus(a['status']);
      final statusB = _normalizeStatus(b['status']);
      final priorityCompare = _statusPriority(statusA).compareTo(
        _statusPriority(statusB),
      );
      if (priorityCompare != 0) {
        return priorityCompare;
      }

      final dateA = _safeAppointmentDate(a);
      final dateB = _safeAppointmentDate(b);
      return dateA.compareTo(dateB);
    });

    return activeAppointments.first;
  }

  Future<void> _fetchAppointmentsSilent() async {
    if (!_isLoggedIn) return;

    try {
      final appointments = await AppointmentService.getClientAppointments();
      final upcoming = _pickNextAppointment(appointments);

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
            showReviewModalBottomSheet(
              context,
              nextToReview,
              onReviewSubmitted: () {
                _fetchAppointmentsSilent();
              },
            );
          }
        }
      }
    } catch (e) {
      // Ignore errors during silent background fetch
    }
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token != null && token.isNotEmpty) {
      try {
        final userDataResp = await AuthService.getMe();
        final appointments = await AppointmentService.getClientAppointments();

        final upcoming = _pickNextAppointment(appointments);

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
  }

  Future<void> _checkLoginStatus() => _checkAuth();

  Widget _buildSectionHeader({
    required String title,
    IconData? icon,
    VoidCallback? onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 6),
                Icon(icon, color: Colors.black45, size: 22),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              tr(context, 'see_all_btn'),
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.primaryBlue, // The space under the notch will be blue
      body: SafeArea(
        bottom: false,
        child: Container(
          color: const Color(
            0xFFF5F7FA,
          ), // A slightly cooler, "pro" grey background
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 1. الهيدر
                ClientHeaderSection(userName: _clientName),

                // 2. المحتوى
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
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

                          _buildSectionHeader(
                            title: tr(context, 'top_categories'),
                          ),
                          const SizedBox(height: 15),
                          const QuickCategories(),

                          const SizedBox(height: 30),
                          AnimatedBuilder(
                            animation: _locationService,
                            builder: (context, _) {
                              return _buildSectionHeader(
                                title: _locationService.hasCoordinates
                                    ? tr(context, 'near_you')
                                    : 'Salons',
                                icon: _locationService.hasCoordinates
                                    ? Icons.location_on
                                    : Icons.storefront_rounded,
                                onSeeAll: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SearchPage(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 15),
                          const NearYouList(),

                          const SizedBox(height: 30),
                          _buildSectionHeader(
                            title: tr(context, 'top_rated'),
                            icon: Icons.star_border,
                            onSeeAll: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SearchPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 15),
                          const TopRatedList(),

                          const SizedBox(height: 30),
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
    );
  }
}
