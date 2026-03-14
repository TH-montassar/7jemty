import 'package:flutter/material.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/core/widgets/animated_button.dart';
import 'package:hjamty/core/widgets/animated_text_button.dart';
import 'package:hjamty/core/widgets/info_card.dart';
import 'package:hjamty/features/client_space/appointments/data/appointment_service.dart';
import 'package:hjamty/features/client_space/appointments/presentation/widgets/appointment_card.dart';
import 'package:hjamty/features/client_space/salon_profile/data/salon_service.dart';
import 'package:hjamty/features/patron_space/appointments/presentation/pages/all_appointments_page.dart';
import 'package:hjamty/features/patron_space/appointments/presentation/pages/calendar_page.dart';
import 'package:hjamty/features/patron_space/appointments/presentation/pages/today_appointments_page.dart';
import 'package:hjamty/features/patron_space/salon_management/presentation/widgets/dashboard_stats.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onOpenPatronAgenda;

  const HomePage({super.key, this.onOpenPatronAgenda});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _salonData;
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await Future.wait([
        SalonService.getMySalon(),
        AppointmentService.getSalonAppointments(),
      ]);

      if (!mounted) return;

      setState(() {
        _salonData = results[0] as Map<String, dynamic>;
        _appointments = (results[1] as List<dynamic>)
            .whereType<Map>()
            .map((apt) => Map<String, dynamic>.from(apt))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  DateTime? _parseAppointmentDate(Map<String, dynamic> appointment) {
    final raw = appointment['appointmentDate'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isTodayAppointment(Map<String, dynamic> appointment) {
    final date = _parseAppointmentDate(appointment);
    if (date == null) return false;
    return _isSameDay(date, DateTime.now());
  }

  bool _isUpcomingAppointment(Map<String, dynamic> appointment) {
    final date = _parseAppointmentDate(appointment);
    if (date == null) return false;

    final status = (appointment['status'] ?? '').toString().toUpperCase();
    const activeStatuses = {
      'PENDING',
      'CONFIRMED',
      'ACCEPTED',
      'IN_PROGRESS',
      'ARRIVED',
    };

    if (!activeStatuses.contains(status)) {
      return false;
    }

    return !date.isBefore(DateTime.now().subtract(const Duration(hours: 1)));
  }

  List<String> _extractServiceNames(Map<String, dynamic> appointment) {
    final rawServices = appointment['services'];
    if (rawServices is! List) return const [];

    return rawServices.map((item) {
      if (item is Map && item['service'] is Map) {
        return item['service']['name']?.toString() ?? '';
      }
      if (item is Map && item['name'] != null) {
        return item['name'].toString();
      }
      return '';
    }).where((name) => name.isNotEmpty).cast<String>().toList();
  }

  String _formatAppointmentTime(Map<String, dynamic> appointment) {
    final date = _parseAppointmentDate(appointment);
    if (date != null) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }

    final startTime = appointment['startTime']?.toString();
    if (startTime != null && startTime.isNotEmpty) {
      return startTime;
    }

    return '--:--';
  }

  Map<String, String> _toAppointmentCardData(Map<String, dynamic> appointment) {
    final client = appointment['client'] as Map?;
    final clientName = client?['fullName']?.toString() ?? 'Client';
    final services = _extractServiceNames(appointment);

    return {
      'name': clientName,
      'service': services.isEmpty ? 'Service' : services.join(' + '),
      'time': _formatAppointmentTime(appointment),
    };
  }

  void _showMissingOrdersMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gestion des commandes indisponible pour le moment.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 44),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboardData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final todayAppointments = _appointments
        .where(_isTodayAppointment)
        .map(_toAppointmentCardData)
        .toList();

    final upcomingAppointments = _appointments
        .where(_isUpcomingAppointment)
        .toList()
      ..sort((a, b) {
        final first = _parseAppointmentDate(a) ?? DateTime(2100);
        final second = _parseAppointmentDate(b) ?? DateTime(2100);
        return first.compareTo(second);
      });

    final upcomingCardData = upcomingAppointments
        .take(2)
        .map(_toAppointmentCardData)
        .toList();

    final completedCount = _appointments.where((appointment) {
      final status = (appointment['status'] ?? '').toString().toUpperCase();
      return status == 'COMPLETED';
    }).length;

    final acceptedCount = _appointments.where((appointment) {
      final status = (appointment['status'] ?? '').toString().toUpperCase();
      return status == 'CONFIRMED' || status == 'ACCEPTED';
    }).length;

    final loyaltyPoints = completedCount;
    final nextRewardTarget = loyaltyPoints < 10
        ? 10
        : ((loyaltyPoints ~/ 10) + 1) * 10;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardStats(
                salonData: _salonData,
                loyaltyPoints: loyaltyPoints,
                nextRewardTarget: nextRewardTarget,
                remainingAppointmentsCount: acceptedCount,
                onRenewTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Renouvellement indisponible pour le moment.'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              InfoCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, color: Colors.blue),
                        SizedBox(width: 16),
                        Text(
                          'RDV Aujourd\'hui',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    AnimatedTextButton(
                      text: 'Voir RDV',
                      borderRadius: 8.0,
                      onTap: () {
                        if (todayAppointments.isEmpty) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(tr(context, 'information_title')),
                              content: const Text(
                                "Vous n'avez aucun rendez-vous pour aujourd'hui.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(tr(context, 'ok_btn')),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TodayAppointmentsPage(
                              todayAppointments: todayAppointments,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Quick Access',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedQuickAccessButton(
                    icon: Icons.calendar_view_month_outlined,
                    label: 'Gérer Mon\nCalendrier',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CalendarPage(),
                        ),
                      );
                    },
                  ),
                  AnimatedQuickAccessButton(
                    icon: Icons.list_alt_outlined,
                    label: 'Gérer Mes\nRendez-vous',
                    onTap: () {
                      widget.onOpenPatronAgenda?.call();
                    },
                  ),
                  AnimatedQuickAccessButton(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Gérer Mes\nCommandes',
                    onTap: _showMissingOrdersMessage,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Prochains Rendez-vous',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (upcomingCardData.isEmpty)
                const InfoCard(
                  child: Text(
                    'Aucun rendez-vous a venir.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Column(
                  children: upcomingCardData.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: AppointmentCard(
                        name: item['name']!,
                        service: item['service']!,
                        time: item['time']!,
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 4),
              Center(
                child: AnimatedTextButton(
                  text: 'Voir tout',
                  width: 120,
                  borderRadius: 20.0,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllAppointmentsPage(
                          appointments: upcomingAppointments
                              .map(_toAppointmentCardData)
                              .toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
