import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/services/fcm_service.dart';
import 'package:hjamty/core/services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = true;
  bool _showAll = false;
  List<dynamic> _notifications = [];

  bool _isRead(dynamic notification) {
    if (notification is Map) {
      return notification['isRead'] == true;
    }
    return false;
  }

  int _unreadCount() {
    return _notifications.where((n) => !_isRead(n)).length;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final data = await NotificationService.getMyNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _markAsRead(int id, int index) async {
    if (index < 0 || index >= _notifications.length) return;
    final notification = _notifications[index];
    if (notification is! Map || notification['isRead'] == true) return;

    try {
      await NotificationService.markAsRead(id);
      if (!mounted) return;
      setState(() {
        final updated = Map<String, dynamic>.from(notification);
        updated['isRead'] = true;
        _notifications[index] = updated;
      });
      NotificationService.refreshUnreadCount();
    } catch (_) {
      // Fail silently for read receipts.
    }
  }

  Future<void> _markAllAsRead() async {
    final hasUnread = _unreadCount() > 0;
    if (!hasUnread) {
      setState(() {
        _showAll = true;
      });
      return;
    }

    try {
      await NotificationService.markAllAsRead();
      if (!mounted) return;

      setState(() {
        _notifications = _notifications.map((n) {
          if (n is Map<String, dynamic>) {
            return {...n, 'isRead': true};
          }
          if (n is Map) {
            final map = Map<String, dynamic>.from(n);
            map['isRead'] = true;
            return map;
          }
          return n;
        }).toList();
        _showAll = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toutes les notifications sont marquees comme lues.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Map<String, dynamic>? _extractTapPayload(Map<String, dynamic> notif) {
    final payload = <String, dynamic>{};

    final appointmentId = notif['appointmentId'];
    if (appointmentId != null) {
      payload['appointmentId'] = appointmentId.toString();
    }

    final deeplink = notif['deeplink']?.toString();
    if (deeplink != null && deeplink.isNotEmpty) {
      payload['deeplink'] = deeplink;

      if (!payload.containsKey('appointmentId')) {
        final match = RegExp(r'/appointments/(\d+)').firstMatch(deeplink);
        if (match != null) {
          payload['appointmentId'] = match.group(1)!;
        }
      }
    }

    if (notif['eventType'] != null) {
      payload['eventType'] = notif['eventType'].toString();
    }
    if (notif['type'] != null) {
      payload['type'] = notif['type'].toString();
    }
    if (notif['intent'] != null) {
      payload['intent'] = notif['intent'].toString();
    }
    if (notif['status'] != null) {
      payload['status'] = notif['status'].toString();
    }
    if (notif['newStatus'] != null) {
      payload['newStatus'] = notif['newStatus'].toString();
    }

    if (!FcmService.isAppointmentPayload(payload)) {
      return null;
    }
    return payload;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _unreadCount();
    final hasUnread = unreadCount > 0;
    final displayedNotifications =
        _showAll ? _notifications : _notifications.where((n) => !_isRead(n)).toList();

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty && hasUnread)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Tout lire',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
        centerTitle: true,
      ),
      bottomNavigationBar: !_isLoading && !_showAll && _notifications.isNotEmpty
          ? Container(
              color: AppColors.bgColor,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showAll = true;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : Column(
              children: [
                Expanded(
                  child: displayedNotifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 80,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                !_showAll
                                    ? 'Aucune notification non lue'
                                    : 'Pas de notifications',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                !_showAll
                                    ? 'Les nouvelles alertes apparaitront ici.'
                                    : 'Vos alertes apparaitront ici.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: displayedNotifications.length,
                          itemBuilder: (context, index) {
                            final rawNotif = displayedNotifications[index];
                            if (rawNotif is! Map) {
                              return const SizedBox.shrink();
                            }
                            final notif = Map<String, dynamic>.from(rawNotif);
                            final isRead = notif['isRead'] == true;
                            final notifId = _toInt(notif['id']);
                            final originalIndex = _notifications.indexWhere(
                              (n) => n is Map && n['id'] == notif['id'],
                            );
                            final createdAt = DateTime.tryParse(
                              notif['createdAt']?.toString() ?? '',
                            );

                            return GestureDetector(
                              onTap: () {
                                if (originalIndex != -1 && notifId != null) {
                                  _markAsRead(notifId, originalIndex);
                                }
                                final payload = _extractTapPayload(notif);
                                if (payload != null) {
                                  FcmService.dispatchNotificationTapPayload(
                                    payload,
                                  );
                                  Navigator.pop(context);
                                }
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                color: isRead
                                    ? Colors.white
                                    : AppColors.primaryBlue.withOpacity(0.05),
                                elevation: 0,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: isRead
                                        ? AppColors.primaryBlue
                                            .withOpacity(0.1)
                                        : AppColors.primaryBlue,
                                    child: Icon(
                                      isRead
                                          ? Icons.notifications_none
                                          : Icons.notifications_active,
                                      color: isRead
                                          ? AppColors.primaryBlue
                                          : Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    notif['title']?.toString() ?? 'Notification',
                                    style: TextStyle(
                                      fontWeight: isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notif['body']?.toString() ?? '',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (createdAt != null)
                                          Text(
                                            DateFormat(
                                              'dd MMM yyyy a HH:mm',
                                            ).format(createdAt),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
