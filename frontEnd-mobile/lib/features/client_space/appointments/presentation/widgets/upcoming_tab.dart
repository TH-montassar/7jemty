import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/features/client_space/appointments/data/appointment_service.dart';
import 'package:hjamty/features/client_space/appointments/presentation/widgets/appointment_details_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class UpcomingTab extends StatefulWidget {
  const UpcomingTab({super.key});

  @override
  State<UpcomingTab> createState() => _UpcomingTabState();
}

class _UpcomingTabState extends State<UpcomingTab> {
  bool _isLoading = true;
  List<dynamic> _allAppointments = [];
  List<dynamic> _appointments = [];
  String _selectedStatus = 'All';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final data = await AppointmentService.getClientAppointments();
      if (!mounted) return;
      _allAppointments = data
          .where(
            (a) => [
              'PENDING',
              'CONFIRMED',
              'ARRIVED',
            ].contains((a['status'] as String).toUpperCase()),
          )
          .toList();

      _applyFilters();
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<dynamic> filtered = List.from(_allAppointments);

    // Filter by Status
    if (_selectedStatus != 'All') {
      filtered = filtered.where((a) {
        final status = (a['status'] as String).toUpperCase();
        return status == _selectedStatus.toUpperCase();
      }).toList();
    }

    // Filter by Date
    if (_selectedDate != null) {
      filtered = filtered.where((a) {
        final dateStr = a['appointmentDate'];
        if (dateStr == null) return false;
        final date = DateTime.parse(dateStr).toLocal();
        return date.year == _selectedDate!.year &&
            date.month == _selectedDate!.month &&
            date.day == _selectedDate!.day;
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      int getPriority(String? s) {
        final st = (s ?? '').toUpperCase();
        if (st == 'CONFIRMED' || st == 'IN_PROGRESS' || st == 'ARRIVED') {
          return 1;
        }
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

    setState(() {
      _appointments = filtered;
    });
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
          content: Text(
            tr(context, 'error_with_message', args: [e.toString()]),
          ),
          backgroundColor: AppColors.actionRed,
        ),
      );
    }
  }

  Future<void> _openMaps(Map<String, dynamic> salon) async {
    final String? googleMapsUrl = salon['googleMapsUrl'];
    final dynamic latVal = salon['latitude'];
    final dynamic lngVal = salon['longitude'];
    final String? address = salon['address'];
    final String? name = salon['name'];

    List<Uri> possibleUris = [];

    // 1. Direct Google Maps URL
    if (googleMapsUrl != null && googleMapsUrl.isNotEmpty) {
      try {
        possibleUris.add(Uri.parse(googleMapsUrl));
      } catch (_) {}
    }

    // 2. Latitude and Longitude
    if (latVal != null && lngVal != null) {
      possibleUris.add(
        Uri.parse(
          "https://www.google.com/maps/search/?api=1&query=$latVal,$lngVal",
        ),
      );
    }

    // 3. Address
    if (address != null && address.isNotEmpty) {
      possibleUris.add(
        Uri.parse(
          "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}",
        ),
      );
    }

    // 4. Name
    if (name != null && name.isNotEmpty) {
      possibleUris.add(
        Uri.parse(
          "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(name)}",
        ),
      );
    }

    for (var uri in possibleUris) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _appointments.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchAppointments,
                  color: AppColors.primaryBlue,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _appointments.length,
                    itemBuilder: (context, index) {
                      final apt = _appointments[index];
                      final salonName =
                          apt['salon']?['name'] ?? tr(context, 'unknown_salon');
                      final barberName =
                          apt['barber']?['fullName'] ??
                          tr(context, 'unassigned_professional');

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
                          ? tr(context, 'status_confirmed')
                          : (status == 'IN_PROGRESS'
                                ? tr(context, 'status_in_progress', args: [])
                                : tr(context, 'status_pending'));

                      // Countdown logic
                      final now = DateTime.now();
                      final difference = date.difference(now);
                      final bool canCancel =
                          difference.inHours >= 1 && status != 'IN_PROGRESS';

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
                        } else {
                          countdownText = tr(
                            context,
                            'time_remaining_min',
                            args: [difference.inMinutes.toString()],
                          );
                        }
                      }

                      // Extract services and total price
                      final servicesList =
                          apt['services'] as List<dynamic>? ?? [];
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
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.2,
                              ),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue.withValues(
                                        alpha: 0.1,
                                      ),
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
                                          color: statusColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
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
                                  const Icon(
                                    Icons.cut,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
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
                                    "${tr(context, 'professional')}: $barberName",
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
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        if (apt['salon'] != null) {
                                          _openMaps(apt['salon']);
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.map_outlined,
                                        size: 18,
                                      ),
                                      label: Text(
                                        tr(context, 'directions'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryBlue,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: canCancel
                                          ? () => _showCancelWarningDialog(
                                              context,
                                              apt['id'],
                                            )
                                          : null,
                                      icon: Icon(
                                        Icons.close,
                                        size: 18,
                                        color: canCancel
                                            ? AppColors.actionRed
                                            : Colors.grey,
                                      ),
                                      label: Text(
                                        tr(context, 'cancel'),
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
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 70,
              color: AppColors.primaryBlue.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            tr(context, 'No Appointments'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Your scheduled appointments will appear here.",
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 15, bottom: 5),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          // Date Filter Chip
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primaryBlue,
                        onPrimary: Colors.white,
                        onSurface: AppColors.textDark,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() => _selectedDate = date);
                _applyFilters();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedDate != null
                      ? AppColors.primaryBlue
                      : Colors.grey.shade300,
                  width: _selectedDate != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _selectedDate != null
                        ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                        : tr(context, 'filter_by_date'),
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: _selectedDate != null
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.textDark,
                  ),
                ],
              ),
            ),
          ),

          // All Chip
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedStatus = 'All';
                _selectedDate = null;
              });
              _applyFilters();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedStatus == 'All'
                      ? AppColors.primaryBlue
                      : Colors.grey.shade300,
                  width: _selectedStatus == 'All' ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  tr(context, 'all'),
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: _selectedStatus == 'All'
                        ? FontWeight.bold
                        : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),

          // Status Dropdown
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: Colors.white,
            offset: const Offset(0, 45),
            onSelected: (String status) {
              setState(() => _selectedStatus = status);
              _applyFilters();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'Confirmed',
                child: Text(
                  tr(context, 'status_confirmed'),
                  style: TextStyle(
                    color: _selectedStatus == 'Confirmed'
                        ? AppColors.primaryBlue
                        : AppColors.textDark,
                    fontWeight: _selectedStatus == 'Confirmed'
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'Pending',
                child: Text(
                  tr(context, 'status_pending'),
                  style: TextStyle(
                    color: _selectedStatus == 'Pending'
                        ? AppColors.primaryBlue
                        : AppColors.textDark,
                    fontWeight: _selectedStatus == 'Pending'
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (_selectedStatus != 'All')
                      ? AppColors.primaryBlue
                      : Colors.grey.shade300,
                  width: (_selectedStatus != 'All') ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _selectedStatus != 'All'
                        ? tr(context, 'status_${_selectedStatus.toLowerCase()}')
                        : tr(context, 'status') ?? 'Status',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: (_selectedStatus != 'All')
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.textDark,
                  ),
                ],
              ),
            ),
          ),
        ],
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
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.actionRed,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                tr(parentContext, 'attention'),
                style: const TextStyle(
                  color: AppColors.actionRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            tr(parentContext, 'confirm_cancel_appointment'),
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                tr(parentContext, 'go_back'),
                style: const TextStyle(
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
                      content: Text(tr(parentContext, 'appointment_cancelled')),
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
              child: Text(
                tr(parentContext, 'yes_cancel'),
                style: const TextStyle(
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
