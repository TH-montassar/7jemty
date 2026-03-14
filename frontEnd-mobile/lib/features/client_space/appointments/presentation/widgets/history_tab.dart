import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/core/services/fcm_service.dart';
import 'package:hjamty/features/client_space/appointments/data/appointment_service.dart';
import 'package:hjamty/features/client_space/appointments/presentation/pages/booking_flow_screen.dart';
import 'package:hjamty/features/client_space/appointments/presentation/widgets/appointment_details_bottom_sheet.dart';
import 'package:toastification/toastification.dart';

class HistoryTab extends StatefulWidget {
  final int? focusAppointmentId;

  const HistoryTab({super.key, this.focusAppointmentId});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  bool _isLoading = true;
  List<dynamic> _allAppointments = [];
  List<dynamic> _appointments = [];
  String _selectedStatus = 'All';
  String _sortField = 'APPOINTMENT_DATE';
  bool _sortAscending = false;
  StreamSubscription<Map<String, dynamic>>? _fcmSubscription;
  bool _focusHandled = false;

  DateTime? _safeDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  DateTime? _createdDate(dynamic appointment) {
    return _safeDate(appointment['createdAt']) ??
        _safeDate(appointment['created_at']) ??
        _safeDate(appointment['createdDate']);
  }

  @override
  void initState() {
    super.initState();
    _setupFcmListener();
    _fetchAppointments();
  }

  void _setupFcmListener() {
    _fcmSubscription = FcmService.messageStream.listen((data) {
      if (data['type'] == 'APPOINTMENT_UPDATED') {
        _fetchAppointments();
      }
    });
  }

  @override
  void didUpdateWidget(covariant HistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusAppointmentId != widget.focusAppointmentId) {
      _focusHandled = false;
      _tryOpenFocusedAppointment();
    }
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchAppointments() async {
    try {
      final data = await AppointmentService.getClientAppointments();
      if (!mounted) return;
      _allAppointments = data
          .where(
            (a) => [
              'COMPLETED',
              'CANCELLED',
              'DECLINED',
            ].contains((a['status'] as String).toUpperCase()),
          )
          .toList();

      _applyFilters();
      setState(() => _isLoading = false);
      _tryOpenFocusedAppointment();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _tryOpenFocusedAppointment();
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

    // Sort
    filtered.sort((a, b) {
      DateTime getSortDate(dynamic appointment) {
        if (_sortField == 'CREATED_AT') {
          return _createdDate(appointment) ??
              _safeDate(appointment['appointmentDate']) ??
              DateTime.fromMillisecondsSinceEpoch(0);
        }
        return _safeDate(appointment['appointmentDate']) ??
            _createdDate(appointment) ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }

      final compare = getSortDate(a).compareTo(getSortDate(b));
      if (compare != 0) {
        return _sortAscending ? compare : -compare;
      }

      final statusA = (a['status'] ?? '').toString().toUpperCase();
      final statusB = (b['status'] ?? '').toString().toUpperCase();
      return statusA.compareTo(statusB);
    });

    setState(() {
      _appointments = filtered;
    });
    _tryOpenFocusedAppointment();
  }

  int? _appointmentId(dynamic appointment) {
    final raw = appointment is Map ? appointment['id'] : null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  void _tryOpenFocusedAppointment() {
    if (_focusHandled || !mounted || _isLoading) return;
    final focusId = widget.focusAppointmentId;
    if (focusId == null) return;

    dynamic target;
    for (final apt in _allAppointments) {
      if (_appointmentId(apt) == focusId) {
        target = apt;
        break;
      }
    }
    if (target == null) return;

    _focusHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showAppointmentDetailsBottomSheet(
        context: context,
        appointment: Map<String, dynamic>.from(target as Map),
        showClientDetails: false,
      );
    });
  }

  void _handleRebook(Map<String, dynamic> apt) {
    final dynamic rawSalonId = apt['salonId'] ?? apt['salon']?['id'];
    final int? salonId = rawSalonId is int
        ? rawSalonId
        : int.tryParse(rawSalonId?.toString() ?? '');

    if (salonId == null) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text(tr(context, 'error_title')),
        description: const Text('Mochkla fil ma3loumet mta3 rendez-vous.'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    final services = apt['services'] as List<dynamic>? ?? [];
    final serviceIds = services
        .map<int?>((s) {
          if (s is! Map) return null;
          final serviceMap = Map<String, dynamic>.from(s);
          final dynamic nestedService = serviceMap['service'];
          final dynamic rawServiceId =
              serviceMap['serviceId'] ??
              (nestedService is Map
                  ? Map<String, dynamic>.from(nestedService)['id']
                  : null);

          if (rawServiceId is int) return rawServiceId;
          return int.tryParse(rawServiceId?.toString() ?? '');
        })
        .whereType<int>()
        .toSet()
        .toList();

    final dynamic rawBarberId = apt['barberId'] ?? apt['barber']?['id'];
    final int? barberId = rawBarberId is int
        ? rawBarberId
        : int.tryParse(rawBarberId?.toString() ?? '');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingFlowScreen(
          salonId: salonId,
          initialServiceIds: serviceIds.isEmpty ? null : serviceIds,
          initialBarberId: barberId,
          lockInitialSelections: false,
        ),
      ),
    );
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

                      final isCancelled = [
                        'CANCELLED',
                        'DECLINED',
                      ].contains((apt['status'] as String).toUpperCase());

                      // Format date
                      final dateStr = apt['appointmentDate'];
                      final DateTime date = dateStr != null
                          ? DateTime.parse(dateStr)
                          : DateTime.now();
                      final formattedDate = DateFormat(
                        'dd MMM yyyy',
                        'fr_FR',
                      ).format(date);

                      final salonName =
                          apt['salon']?['name'] ?? tr(context, 'unknown_salon');

                      // Extract services and total price
                      final servicesList =
                          apt['services'] as List<dynamic>? ?? [];
                      final serviceNames = servicesList
                          .map((s) => s['service']['name'])
                          .join(' + ');
                      final price = apt['totalPrice'] ?? 0;

                      final statusText = isCancelled
                          ? tr(context, 'status_cancelled')
                          : tr(context, 'status_completed');
                      final review = apt['review'] as Map<String, dynamic>?;
                      final reviewRating =
                          (review?['rating'] as num?)?.toInt() ?? 0;
                      final reviewComment =
                          (review?['comment'] ?? '').toString().trim();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: isCancelled
                              ? Border.all(
                                  color: Colors.red.withValues(alpha: 0.2),
                                )
                              : null,
                          boxShadow: isCancelled
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCancelled
                                        ? Colors.red.withValues(alpha: 0.1)
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: isCancelled
                                          ? AppColors.actionRed
                                          : Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              salonName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isCancelled
                                    ? Colors.grey
                                    : AppColors.textDark,
                              ),
                            ),
                            Text(
                              "$serviceNames - $price DT",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                decoration: isCancelled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            if (!isCancelled) ...[
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  if (review == null) ...[
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          final result = await showDialog(
                                            context: context,
                                            builder: (_) =>
                                                _ReviewDialog(appointment: apt),
                                          );
                                          if (result == true) {
                                            _fetchAppointments(); // Refresh the list after successful review
                                            if (!context.mounted) return;
                                            toastification.show(
                                              context: context,
                                              type: ToastificationType.success,
                                              title: Text(
                                                tr(context, 'thank_you'),
                                              ),
                                              description: Text(
                                                tr(
                                                  context,
                                                  'review_added_success',
                                                ),
                                              ),
                                              autoCloseDuration: const Duration(
                                                seconds: 3,
                                              ),
                                            );
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Colors.amber,
                                          ),
                                          foregroundColor: Colors.amber[700],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          tr(context, 'leave_review'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ] else ...[
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.amber.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  reviewRating > 0
                                                      ? '$reviewRating/5'
                                                      : tr(
                                                          context,
                                                          'thank_you_for_review',
                                                        ),
                                                  style: TextStyle(
                                                    color: Colors.amber[800],
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (reviewComment.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                reviewComment,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _handleRebook(apt),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryBlue
                                            .withValues(alpha: 0.1),
                                        foregroundColor: AppColors.primaryBlue,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: Text(tr(context, 'rebook')),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
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
              Icons.history_rounded,
              size: 70,
              color: AppColors.primaryBlue.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            tr(context, 'No History'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Your past appointments will appear here",
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
          // All Chip
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedStatus = 'All';
                _sortField = 'APPOINTMENT_DATE';
                _sortAscending = false;
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
                value: 'Completed',
                child: Text(
                  tr(context, 'status_completed'),
                  style: TextStyle(
                    color: _selectedStatus == 'Completed'
                        ? AppColors.primaryBlue
                        : AppColors.textDark,
                    fontWeight: _selectedStatus == 'Completed'
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'Cancelled',
                child: Text(
                  tr(context, 'status_cancelled'),
                  style: TextStyle(
                    color: _selectedStatus == 'Cancelled'
                        ? AppColors.primaryBlue
                        : AppColors.textDark,
                    fontWeight: _selectedStatus == 'Cancelled'
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'Declined',
                child: Text(
                  tr(context, 'status_declined'),
                  style: TextStyle(
                    color: _selectedStatus == 'Declined'
                        ? AppColors.primaryBlue
                        : AppColors.textDark,
                    fontWeight: _selectedStatus == 'Declined'
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

          // Sort Field Dropdown
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: Colors.white,
            offset: const Offset(0, 45),
            onSelected: (String value) {
              setState(() => _sortField = value);
              _applyFilters();
            },
            itemBuilder:
                (BuildContext context) => const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'APPOINTMENT_DATE',
                    child: Text('Date RDV'),
                  ),
                  PopupMenuItem<String>(
                    value: 'CREATED_AT',
                    child: Text('Date creation'),
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
                  color: _sortField != 'APPOINTMENT_DATE'
                      ? AppColors.primaryBlue
                      : Colors.grey.shade300,
                  width: _sortField != 'APPOINTMENT_DATE' ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _sortField == 'CREATED_AT' ? 'Date creation' : 'Date RDV',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: _sortField != 'APPOINTMENT_DATE'
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

          // Sort Direction
          GestureDetector(
            onTap: () {
              setState(() => _sortAscending = !_sortAscending);
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
                  color: !_sortAscending
                      ? AppColors.primaryBlue
                      : Colors.grey.shade300,
                  width: !_sortAscending ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 16,
                    color: AppColors.textDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _sortAscending ? 'Asc' : 'Desc',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight:
                          !_sortAscending ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const _ReviewDialog({required this.appointment});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_rating == 0) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: Text(tr(context, 'error')),
        description: Text(tr(context, 'please_select_rating')),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await AppointmentService.submitReview(
        appointmentId: widget.appointment['id'],
        salonId:
            widget.appointment['salonId'] ?? widget.appointment['salon']['id'],
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true); // true indicates success
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text(tr(context, 'error')),
        description: Text(e.toString().replaceAll('Exception: ', '')),
        autoCloseDuration: const Duration(seconds: 4),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        tr(context, 'leave_review'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () {
                  setState(() => _rating = index + 1);
                },
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: tr(context, 'your_comment_optional'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            tr(context, 'cancel'),
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
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
              : Text(
                  tr(context, 'send'),
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
