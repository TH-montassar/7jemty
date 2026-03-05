import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/features/client_space/appointments/data/appointment_service.dart';
import 'package:hjamty/features/client_space/appointments/presentation/widgets/appointment_details_bottom_sheet.dart';

class UpcomingTab extends StatefulWidget {
  const UpcomingTab({super.key});

  @override
  State<UpcomingTab> createState() => _UpcomingTabState();
}

class _UpcomingTabState extends State<UpcomingTab> {
  bool _isLoading = true;
  List<dynamic> _appointments = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final data = await AppointmentService.getClientAppointments();
      if (!mounted) return;
      setState(() {
        _appointments = data
            .where(
              (a) => [
                'PENDING',
                'CONFIRMED',
                'ARRIVED',
              ].contains((a['status'] as String).toUpperCase()),
            )
            .toList();

        _appointments.sort((a, b) {
          int getPriority(String? s) {
            final st = (s ?? '').toUpperCase();
            if (st == 'CONFIRMED' || st == 'IN_PROGRESS' || st == 'ARRIVED')
              return 1;
            if (st == 'PENDING') return 2;
            return 3;
          }

          final pA = getPriority(a['status']);
          final pB = getPriority(b['status']);
          if (pA != pB) return pA.compareTo(pB);

          final dateA =
              DateTime.tryParse(a['appointmentDate'] ?? '') ?? DateTime.now();
          final dateB =
              DateTime.tryParse(b['appointmentDate'] ?? '') ?? DateTime.now();
          return dateA.compareTo(dateB);
        });

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelAppointment(int appointmentId) async {
    try {
      await AppointmentService.updateStatus(
        appointmentId: appointmentId,
        status: 'CANCELLED',
      );
      _fetchAppointments(); // Refresh the list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.actionRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (_appointments.isEmpty) {
      return Center(
        child: Text(
          tr(context, 'no_appointments') ?? 'Aucun rendez-vous à venir.',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAppointments,
      color: AppColors.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          final apt = _appointments[index];
          final salonName = apt['salon']?['name'] ?? 'Salon inconnu';
          final barberName =
              apt['barber']?['fullName'] ?? 'Professionnel non assigné';

          // Format date
          final dateStr = apt['appointmentDate'];
          final DateTime date = dateStr != null
              ? DateTime.parse(dateStr).toLocal()
              : DateTime.now();
          final formattedDate = DateFormat(
            'dd MMM - HH:mm',
            'fr_FR',
          ).format(date);

          final status = (apt['status'] as String).toUpperCase();
          Color statusColor = status == 'CONFIRMED'
              ? const Color(0xFF2ECA7F)
              : (status == 'IN_PROGRESS'
                    ? AppColors.primaryBlue
                    : Colors.orange);
          String statusText = status == 'CONFIRMED'
              ? 'M\'akd'
              : (status == 'IN_PROGRESS' ? 'En cours' : 'En attente');

          // Countdown logic
          final now = DateTime.now();
          final difference = date.difference(now);
          final bool canCancel =
              difference.inHours >= 1 && status != 'IN_PROGRESS';

          String countdownText = "";
          if (status == 'CONFIRMED' || status == 'PENDING') {
            if (difference.isNegative) {
              countdownText = "L'wa9t r7el";
            } else if (difference.inHours > 0) {
              countdownText =
                  "Mazal ${difference.inHours}h ${difference.inMinutes % 60}min";
            } else {
              countdownText = "Mazal ${difference.inMinutes}min";
            }
          }

          // Extract services and total price
          final servicesList = apt['services'] as List<dynamic>? ?? [];
          final serviceNames = servicesList
              .map((s) => s['service']['name'])
              .join(' + ');
          final price = apt['totalPrice'] ?? 0;

          return GestureDetector(
            onTap: () {
              showAppointmentDetailsBottomSheet(
                context: context,
                appointment: apt,
                showClientDetails: false,
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "📅 $formattedDate",
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (countdownText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                countdownText,
                                style: const TextStyle(
                                  color: AppColors.actionRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "$salonName 👑",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.cut, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "$serviceNames - $price DT",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Professionnel: $barberName",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: canCancel
                              ? () =>
                                    _showCancelWarningDialog(context, apt['id'])
                              : null,
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: canCancel
                                ? AppColors.actionRed
                                : Colors.grey,
                          ),
                          label: Text(
                            tr(context, 'cancel') ?? "Batel",
                            style: TextStyle(
                              color: canCancel
                                  ? AppColors.actionRed
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: canCancel
                                  ? AppColors.actionRed
                                  : Colors.grey,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      if (!canCancel && status != 'IN_PROGRESS')
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Implement navigation to salon location if Google Maps URL is available -> MVP Phase
                          },
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text(
                            "Thneya",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCancelWarningDialog(BuildContext parentContext, int appointmentId) {
    showDialog(
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.actionRed,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                "Rod belek",
                style: TextStyle(
                  color: AppColors.actionRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            "Met'aked theb tbatel e-rendez-vous?\n\n⚠️ Kan tbatel 3 marrat wra baadhom comptek yetbloka.",
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                "Rjou3",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Save the messenger AND navigator using the safe parent context *before* await
                final scaffoldMessenger = ScaffoldMessenger.of(parentContext);
                final navigator = Navigator.of(dialogContext);

                // Pop the dialog first
                navigator.pop();

                // Wait for the backend API
                await _cancelAppointment(appointmentId);

                // Show the snackbar using the saved messenger
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        tr(parentContext, 'appointment_cancelled') ??
                            'Rendez-vous annulé',
                      ),
                      backgroundColor: AppColors.actionRed,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.actionRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Ey, Batel",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
