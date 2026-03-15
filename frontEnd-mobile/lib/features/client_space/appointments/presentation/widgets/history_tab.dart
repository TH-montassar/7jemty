import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/core/services/fcm_service.dart';
import 'package:hjamty/features/client_space/appointments/data/appointment_service.dart';
import 'package:hjamty/features/client_space/appointments/presentation/pages/booking_flow_screen.dart';
import 'package:hjamty/features/client_space/appointments/presentation/widgets/appointment_details_bottom_sheet.dart';
import 'package:hjamty/features/client_space/appointments/presentation/widgets/appointment_empty_state.dart';
import 'package:hjamty/features/client_space/appointments/presentation/widgets/appointment_filter_bar.dart';
import 'package:hjamty/features/client_space/appointments/presentation/widgets/review_modal_bottom_sheet.dart';
import 'package:toastification/toastification.dart';

class HistoryTab extends StatefulWidget {
  final int? focusAppointmentId;
  final bool openReview;

  const HistoryTab({
    super.key, 
    this.focusAppointmentId, 
    this.openReview = false,
  });

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
    if (oldWidget.focusAppointmentId != widget.focusAppointmentId || 
        oldWidget.openReview != widget.openReview) {
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
      
      final review = target['review'] as Map<String, dynamic>?;
      
      // If requested to open review AND no review exists yet, open the review dialog
      if (widget.openReview && review == null) {
        showReviewModalBottomSheet(
          context,
          Map<String, dynamic>.from(target as Map),
          onReviewSubmitted: () {
            if (mounted) {
              _fetchAppointments();
            }
          },
        );
      } else {
        // Otherwise just open the details bottom sheet
        showAppointmentDetailsBottomSheet(
          context: context,
          appointment: Map<String, dynamic>.from(target as Map),
          showClientDetails: false,
        );
      }
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
                                        onPressed: () {
                                          showReviewModalBottomSheet(
                                            context,
                                            apt,
                                            onReviewSubmitted: () {
                                              if (mounted) {
                                                _fetchAppointments();
                                              }
                                            },
                                          );
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
    return AppointmentEmptyState(
      icon: Icons.history_rounded,
      title: tr(context, 'No History'),
      subtitle: 'Your past appointments will appear here',
    );
  }

  Widget _buildFilters() {
    return AppointmentFilterBar(
      selectedStatus: _selectedStatus,
      sortField: _sortField,
      sortAscending: _sortAscending,
      statusOptions: const [
        AppointmentFilterOption(value: 'Completed', labelKey: 'status_completed'),
        AppointmentFilterOption(value: 'Cancelled', labelKey: 'status_cancelled'),
        AppointmentFilterOption(value: 'Declined', labelKey: 'status_declined'),
      ],
      onReset: () {
        setState(() {
          _selectedStatus = 'All';
          _sortField = 'APPOINTMENT_DATE';
          _sortAscending = false;
        });
        _applyFilters();
      },
      onStatusSelected: (status) {
        setState(() => _selectedStatus = status);
        _applyFilters();
      },
      onSortFieldSelected: (value) {
        setState(() => _sortField = value);
        _applyFilters();
      },
      onSortDirectionToggle: () {
        setState(() => _sortAscending = !_sortAscending);
        _applyFilters();
      },
    );
  }
}
