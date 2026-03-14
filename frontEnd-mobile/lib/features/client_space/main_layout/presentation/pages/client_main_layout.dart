import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hjamty/core/services/fcm_service.dart';
import 'package:hjamty/core/services/notification_service.dart';
import 'package:hjamty/features/auth/data/auth_service.dart';
import 'package:hjamty/features/auth/signIn.dart';
import 'package:hjamty/features/client_space/appointments/presentation/pages/appointments_page.dart';
import 'package:hjamty/features/client_space/home/presentation/pages/client_home_page.dart';
import 'package:hjamty/features/client_space/home/presentation/widgets/client_bottom_nav.dart';
import 'package:hjamty/features/client_space/products/presentation/pages/products_page.dart';
import 'package:hjamty/features/client_space/profile/presentation/pages/client_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientMainLayout extends StatefulWidget {
  final int initialIndex;

  const ClientMainLayout({super.key, this.initialIndex = 0});

  @override
  State<ClientMainLayout> createState() => _ClientMainLayoutState();
}

class _ClientMainLayoutState extends State<ClientMainLayout> {
  late int _selectedIndex;
  StreamSubscription<Map<String, dynamic>>? _notificationTapSubscription;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _fetchUserData();
    if (kIsWeb) {
      NotificationService.listenToNotificationsStream();
    }
    _setupNotificationTapListener();
  }

  final List<Widget> _pages = [
    const ClientHomePage(),
    const AppointmentsPage(),
    const ProductsPage(),
    const ProfilePage(),
  ];

  Future<void> _fetchUserData() async {
    try {
      final result = await AuthService.getMe();
      if (!mounted) return;
      setState(() {
        _userData = result['data'];
      });
    } catch (_) {}
  }

  void _setupNotificationTapListener() {
    final pendingPayload = FcmService.consumePendingNotificationTap();
    if (pendingPayload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleNotificationTap(pendingPayload);
      });
    }

    _notificationTapSubscription = FcmService.notificationTapStream.listen(
      _handleNotificationTap,
    );
  }

  void _handleNotificationTap(Map<String, dynamic> payload) {
    if (!FcmService.isAppointmentPayload(payload)) return;

    final appointmentId = FcmService.extractAppointmentId(payload);
    final openHistory = FcmService.shouldOpenHistoryTab(payload);
    final openReview = FcmService.shouldOpenReview(payload);
    if (appointmentId == null || !mounted) return;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }

    final rebuildMarker = DateTime.now().microsecondsSinceEpoch;
    setState(() {
      _pages[1] = AppointmentsPage(
        key: ValueKey('appt_from_notif_${appointmentId}_$rebuildMarker'),
        initialTabIndex: openHistory ? 1 : 0,
        focusAppointmentId: appointmentId,
        openReview: openReview,
      );
      _selectedIndex = 1;
    });
  }

  void _onItemTapped(int index) async {
    if (index == 3) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final isUserLoggedIn = token != null && token.isNotEmpty;

      if (!isUserLoggedIn) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignInScreen()),
          );
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        if (index == 1) {
          _pages[1] = AppointmentsPage(key: UniqueKey());
        } else if (index == 3) {
          _pages[3] = ProfilePage(key: UniqueKey());
        }
        _selectedIndex = index;
      });
    }
  }

  @override
  void dispose() {
    _notificationTapSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: ClientBottomNav(
        selectedIndex: _selectedIndex,
        avatarUrl: _userData?['profile']?['avatarUrl']?.toString(),
        onTap: _onItemTapped,
      ),
    );
  }
}
