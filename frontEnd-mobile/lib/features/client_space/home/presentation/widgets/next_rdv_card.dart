import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:intl/intl.dart';
import 'package:hjamty/features/client_space/appointments/presentation/widgets/appointment_details_bottom_sheet.dart';

class NextRdvCard extends StatefulWidget {
  final Map<String, dynamic>? appointmentData;

  const NextRdvCard({super.key, this.appointmentData});

  @override
  State<NextRdvCard> createState() => _NextRdvCardState();
}

class _NextRdvCardState extends State<NextRdvCard> {
  Timer? _countdownTicker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startCountdownTicker();
  }

  @override
  void didUpdateWidget(covariant NextRdvCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appointmentData?['appointmentDate'] !=
            widget.appointmentData?['appointmentDate'] ||
        oldWidget.appointmentData?['status'] !=
            widget.appointmentData?['status']) {
      _startCountdownTicker();
    }
  }

  void _startCountdownTicker() {
    _countdownTicker?.cancel();
    _scheduleNextTick();
  }

  void _scheduleNextTick() {
    if (!mounted) return;
    final apt = widget.appointmentData;
    if (apt == null) return;

    final rawStatus = (apt['status'] as String? ?? 'PENDING').toUpperCase();
    final status = rawStatus == 'ARRIVED' ? 'IN_PROGRESS' : rawStatus;
    if (status != 'CONFIRMED' && status != 'PENDING') return;

    final dateStr = apt['appointmentDate'];
    final DateTime date = dateStr != null
        ? DateTime.parse(dateStr.toString()).toLocal()
        : DateTime.now();

    final diff = date.difference(DateTime.now());
    if (diff.isNegative) return;

    final now = DateTime.now();
    final delay = (diff.inSeconds <= 60)
        ? const Duration(seconds: 1)
        : const Duration(minutes: 1) -
              Duration(
                seconds: now.second,
                milliseconds: now.millisecond,
                microseconds: now.microsecond,
              );

    _countdownTicker = Timer(delay, () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _scheduleNextTick();
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appointmentData == null) {
      return const SizedBox.shrink();
    }

    final apt = widget.appointmentData!;
    final salonName = apt['salon']?['name'] ?? 'Salon inconnu';
    final barberName =
        apt['barber']?['fullName'] ?? 'Professionnel non assigné';

    // Format date
    final dateStr = apt['appointmentDate'];
    final DateTime date = dateStr != null
        ? DateTime.parse(dateStr).toLocal()
        : DateTime.now();

    final formattedDate = DateFormat('dd MMM - HH:mm', 'fr_FR').format(date);

    final rawStatus = (apt['status'] as String? ?? 'PENDING').toUpperCase();
    final status = rawStatus == 'ARRIVED' ? 'IN_PROGRESS' : rawStatus;
    Color statusColor = status == 'CONFIRMED'
        ? const Color(0xFF2ECA7F)
        : (status == 'IN_PROGRESS' ? AppColors.primaryBlue : Colors.orange);
    String statusText = status == 'CONFIRMED'
        ? tr(context, 'status_confirmed')
        : (status == 'IN_PROGRESS'
              ? tr(context, 'status_in_progress')
              : tr(context, 'status_pending'));

    // Countdown logic
    final difference = date.difference(_now);

    String countdownText = "";
    if (status == 'CONFIRMED' || status == 'PENDING') {
      if (difference.isNegative) {
        countdownText = tr(context, 'time_passed');
      } else if (difference.inHours > 0) {
        countdownText = tr(
          context,
          'time_remaining_hours_min',
          args: [
            difference.inHours.toString(),
            (difference.inMinutes % 60).toString(),
          ],
        );
      } else if (difference.inSeconds <= 60) {
        final secondsLeft = ((difference.inMilliseconds) / 1000).ceil().clamp(
          0,
          60,
        );
        countdownText = tr(
          context,
          'time_remaining_sec',
          args: [secondsLeft.toString()],
        );
      } else if (difference.inMinutes > 0) {
        countdownText = tr(
          context,
          'time_remaining_min',
          args: [difference.inMinutes.toString()],
        );
      }
    }

    // Extract services and total price
    final servicesList = apt['services'] as List<dynamic>? ?? [];
    final serviceNames = servicesList.isNotEmpty
        ? servicesList.map((s) => s['service']['name']).join(' + ')
        : 'Service';
    final price = apt['totalPrice'] ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          showAppointmentDetailsBottomSheet(
            context: context,
            appointment: widget.appointmentData!,
            showClientDetails: false,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.transparent),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Prochain Rendez-vous & Voir sur la Map
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr(context, 'next_appointment'),
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr(context, 'opening_map'))),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.map_outlined,
                            color: AppColors.primaryBlue,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tr(context, 'see_on_map'),
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Date format Box & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
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
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Salon Name
              Row(
                children: [
                  Text(
                    salonName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.verified,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Services & Price
              Row(
                children: [
                  const Icon(
                    Icons.cut_outlined,
                    size: 18,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "$serviceNames - $price DT",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Professional Name
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr(context, 'professional_label', args: [barberName]),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
