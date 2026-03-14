import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/services/fcm_service.dart';
import 'package:hjamty/features/auth/data/auth_service.dart';
import 'package:hjamty/features/client_space/profile/presentation/pages/client_profile_page.dart';
import 'package:hjamty/core/widgets/notification_bell.dart';
import 'employee_agenda_page.dart';

class EmployeeMainLayout extends StatefulWidget {
  final int initialIndex;

  const EmployeeMainLayout({super.key, this.initialIndex = 0});

  @override
  State<EmployeeMainLayout> createState() => _EmployeeMainLayoutState();
}

class _EmployeeMainLayoutState extends State<EmployeeMainLayout> {
  late int _selectedIndex;
  StreamSubscription<Map<String, dynamic>>? _notificationTapSubscription;
  Map<String, dynamic>? _userData;

  final List<Widget> _pages = [const EmployeeAgendaPage(), const ProfilePage()];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _fetchUserData();
    _setupNotificationTapListener();
  }

  Future<void> _fetchUserData() async {
    try {
      final result = await AuthService.getMe();
      if (!mounted) return;
      setState(() {
        _userData = result['data'];
      });
    } catch (_) {}
  }

  Widget _buildProfileNavIcon({required bool active}) {
    final avatarUrl = _userData?['profile']?['avatarUrl']?.toString();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    if (!hasAvatar) {
      return Icon(active ? Icons.person : Icons.person_outline);
    }

    return Container(
      width: active ? 26 : 22,
      height: active ? 26 : 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? AppColors.primaryBlue : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: CircleAvatar(
        radius: active ? 13 : 11,
        backgroundColor: Colors.grey[200],
        backgroundImage: NetworkImage(avatarUrl),
      ),
    );
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
    if (appointmentId == null || !mounted) return;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }

    final rebuildMarker = DateTime.now().microsecondsSinceEpoch;
    setState(() {
      _pages[0] = EmployeeAgendaPage(
        key: ValueKey('employee_notif_${appointmentId}_$rebuildMarker'),
        focusAppointmentId: appointmentId,
      );
      _selectedIndex = 0;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _notificationTapSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.cut, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 8),
            const Text(
              "7jemty",
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
              radius: 15,
              child: const NotificationBell(
                iconColor: AppColors.primaryBlue,
                badgeColor: AppColors.actionRed,
              ),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: _buildProfileNavIcon(active: false),
            activeIcon: _buildProfileNavIcon(active: true),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
