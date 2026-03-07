import 'package:flutter/material.dart';
import 'package:hjamty/features/client_space/notifications/presentation/pages/notifications_page.dart';
import 'package:hjamty/core/services/notification_service.dart';
import 'package:hjamty/core/constants/app_colors.dart';

class NotificationBell extends StatefulWidget {
  final Color iconColor;
  final Color badgeColor;

  const NotificationBell({
    super.key,
    this.iconColor = Colors.white,
    this.badgeColor = AppColors.actionRed,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      await NotificationService.getUnreadCount();
    } catch (e) {
      // Ignore errors for unread count
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsPage()),
        ).then((_) => _fetchUnreadCount());
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, color: widget.iconColor, size: 28),
          ValueListenableBuilder<int>(
            valueListenable: NotificationService.unreadCountNotifier,
            builder: (context, unreadCount, child) {
              if (unreadCount <= 0) return const SizedBox.shrink();
              return Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: widget.badgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
