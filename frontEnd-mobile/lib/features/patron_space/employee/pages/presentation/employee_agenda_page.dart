import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:hjamty/core/services/fcm_service.dart';
import 'package:intl/intl.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/services/notification_service.dart';
import 'package:hjamty/features/client_space/appointments/data/appointment_service.dart';
import 'package:hjamty/features/client_space/appointments/presentation/widgets/appointment_details_bottom_sheet.dart';
import 'package:hjamty/features/patron_space/appointments/presentation/widgets/agenda_filter_bar.dart';
import 'package:hjamty/features/patron_space/appointments/presentation/widgets/agenda_list_utils.dart';
import 'package:hjamty/features/patron_space/appointments/presentation/widgets/no_show_flow.dart';
import 'package:hjamty/features/patron_space/employee/pages/presentation/employee_calendar_page.dart';

class EmployeeAgendaPage extends StatefulWidget {
  final int? focusAppointmentId;

  const EmployeeAgendaPage({super.key, this.focusAppointmentId});

  @override
  State<EmployeeAgendaPage> createState() => _EmployeeAgendaPageState();
}

class _EmployeeAgendaPageState extends State<EmployeeAgendaPage> {
  bool _isLoading = true;
  List<dynamic> _appointments = [];
  StreamSubscription<Map<String, dynamic>>? _fcmSubscription;
  Timer? _uiTimer;
  String _statusFilter = 'ALL';
  String _sortField = 'APPOINTMENT_DATE';
  bool _sortAscending = false;
  bool _focusHandled = false;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();

    if (kIsWeb) {
      NotificationService.listenToNotificationsStream();
    }
    _setupFcmListener();

    // Add per-second UI timer for granular countdown (seconds)
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {}); // Just redraw the UI
      }
    });
  }

  @override
  void didUpdateWidget(covariant EmployeeAgendaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusAppointmentId != widget.focusAppointmentId) {
      _focusHandled = false;
      _tryOpenFocusedAppointment();
    }
  }

  void _setupFcmListener() {
    _fcmSubscription = FcmService.messageStream.listen((data) {
      if (data['type'] == 'APPOINTMENT_UPDATED') {
        if (mounted) {
          _fetchAppointmentsSilent();
        }
      }
    });
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    _uiTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAppointments() async {
    try {
      final data = await AppointmentService.getEmployeeAppointments();
      if (!mounted) return;

      setState(() {
        _appointments = data;
        _isLoading = false;
      });
      _tryOpenFocusedAppointment();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _tryOpenFocusedAppointment();
    }
  }

  Future<void> _fetchAppointmentsSilent() async {
    try {
      final data = await AppointmentService.getEmployeeAppointments();
      if (!mounted) return;

      setState(() {
        _appointments = data;
      });
      _tryOpenFocusedAppointment();
    } catch (e) {
      // Ignore errors on silent poll to not interrupt the user's flow
    }
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
    for (final apt in _appointments) {
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
        showBarberDetails: false,
      );
    });
  }

  Future<void> _updateStatus(int appointmentId, String newStatus) async {
    await updateAppointmentStatusFlow(
      context: context,
      appointmentId: appointmentId,
      status: newStatus,
      loadingMessage: tr(context, 'updating'),
      successMessage: tr(context, 'status_updated_successfully'),
      errorMessage: tr(context, 'error_issue'),
      onUpdated: _fetchAppointments,
    );
  }

  Future<void> _showNoShowDialog(int appointmentId) async {
    await showNoShowDecisionDialog(
      context: context,
      appointmentId: appointmentId,
      onConfirmNoShow: (id) => _updateStatus(id, 'CANCELLED'),
      onPostpone15: (id) => postponeNoShowWithCascadeFlow(
        context: context,
        appointmentId: id,
        onRefresh: _fetchAppointments,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = 'ALL';
      _sortField = 'APPOINTMENT_DATE';
      _sortAscending = false;
    });
  }

  Widget _buildFiltersBar({required int totalCount, required int shownCount}) {
    return AgendaFilterBar(
      statusFilter: _statusFilter,
      sortField: _sortField,
      sortAscending: _sortAscending,
      totalCount: totalCount,
      shownCount: shownCount,
      statusLabel: (status) => agendaStatusLabel(context, status),
      onClearFilters: _clearFilters,
      onStatusSelected: (value) => setState(() => _statusFilter = value),
      onSortFieldSelected: (value) => setState(() => _sortField = value),
      onToggleSortDirection: () => setState(
        () => _sortAscending = !_sortAscending,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          tr(context, 'my_agenda'),
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmployeeCalendarPage(),
                ),
              );
            },
            icon: const Icon(
              Icons.calendar_month,
              color: AppColors.primaryBlue,
            ),
            tooltip: 'Voir en calendrier',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : Builder(
              builder: (context) {
                final filteredAppointments = applyAgendaFiltersAndSort(
                  source: _appointments,
                  statusFilter: _statusFilter,
                  sortField: _sortField,
                  sortAscending: _sortAscending,
                );

                return RefreshIndicator(
                  onRefresh: _fetchAppointments,
                  color: AppColors.primaryBlue,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildFiltersBar(
                          totalCount: _appointments.length,
                          shownCount: filteredAppointments.length,
                        ),
                      ),
                      if (_appointments.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              tr(context, 'no_appointments_today'),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else if (filteredAppointments.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              'Ma fama hata resultat bel filtres',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final apt = filteredAppointments[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: _buildAppointmentCard(apt, index),
                            );
                          }, childCount: filteredAppointments.length),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAppointmentCard(dynamic apt, int index) {
    final status = (apt['status'] as String).toUpperCase();
    final isPending = status == 'PENDING';
    final isConfirmed = status == 'CONFIRMED' || status == 'ACCEPTED';
    final isArrived = status == 'ARRIVED';
    final isInProgress = status == 'IN_PROGRESS';
    final isCompleted = status == 'COMPLETED';
    final isDeclined = status == 'DECLINED' || status == 'CANCELLED';

    final clientName = apt['client']?['fullName'] ?? 'Client';
    final serviceName = (apt['services'] as List?)?.isNotEmpty == true
        ? apt['services'][0]['service']['name']
        : 'Service';

    final dateStr = apt['appointmentDate'];
    final time = dateStr != null
        ? DateFormat(
            'dd MMM - HH:mm',
            'fr_FR',
          ).format(DateTime.parse(dateStr).toLocal())
        : '--:--';

    Color statusColor = Colors.grey;
    String statusText = status;

    if (isPending) {
      statusColor = Colors.orange;
      statusText = tr(context, 'status_pending');
    } else if (isConfirmed) {
      statusColor = AppColors.primaryBlue;
      statusText = tr(context, 'status_confirmed_badge');
    } else if (isArrived) {
      statusColor = Colors.teal;
      statusText = 'Arrived';
    } else if (isInProgress) {
      statusColor = Colors.purple;
      statusText = tr(context, 'status_in_progress');
    } else if (isCompleted) {
      statusColor = AppColors.successGreen;
      statusText = tr(context, 'status_completed');
    } else if (isDeclined) {
      statusColor = AppColors.actionRed;
      statusText = tr(context, 'status_cancelled');
    }

    String countdownText = "";
    bool isTimeReached = false;

    if (dateStr != null &&
        (isConfirmed || isPending || isArrived || isInProgress)) {
      DateTime targetDate;
      if (isInProgress && apt['estimatedEndTime'] != null) {
        targetDate = DateTime.parse(apt['estimatedEndTime']).toLocal();
      } else {
        targetDate = DateTime.parse(dateStr).toLocal();
      }

      final now = DateTime.now();
      final difference = targetDate.difference(now);

      if (difference.isNegative || difference.inSeconds <= 0) {
        isTimeReached = true;
        countdownText = isInProgress
            ? tr(context, 'time_is_up')
            : tr(context, 'time_passed');
      } else if (difference.inHours > 0) {
        countdownText = countdownText = tr(
          context,
          'time_remaining_hours_min',
          args: [
            difference.inHours.toString(),
            (difference.inMinutes % 60).toString(),
          ],
        );
      } else if (difference.inMinutes > 0) {
        countdownText = tr(
          context,
          'time_remaining_min',
          args: [difference.inMinutes.toString()],
        );
      } else {
        // Less than 1 minute, show seconds
        countdownText = tr(
          context,
          'time_remaining_sec',
          args: [difference.inSeconds.toString()],
        );
      }

      // Add T+t2 breakdown for in-progress appointments
      if (isInProgress) {
        int originalDuration = 0;
        final services = apt['services'] as List?;
        if (services != null) {
          for (var s in services) {
            final srv = s['service'];
            if (srv != null) {
              originalDuration +=
                  (srv['durationMinutes'] as num?)?.toInt() ?? 0;
            }
          }
        }

        int totalDurationSoFar = 0;
        if (dateStr != null && apt['estimatedEndTime'] != null) {
          final start = DateTime.parse(dateStr).toLocal();
          final end = DateTime.parse(apt['estimatedEndTime']).toLocal();
          totalDurationSoFar = end.difference(start).inMinutes;
        }

        int extensionDuration = totalDurationSoFar - originalDuration;
        String formula = "T(${originalDuration}mn)";
        if (extensionDuration > 0) {
          formula += " + t2(${extensionDuration}mn)";
        }
        countdownText = "$countdownText ($formula)";
      }
    }

    return GestureDetector(
      onTap: () {
        showAppointmentDetailsBottomSheet(
          context: context,
          appointment: apt,
          showBarberDetails: false,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textDark,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
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
            const SizedBox(height: 12),
            Text(
              clientName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              serviceName,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),

            if (isPending || isConfirmed || isArrived || isInProgress)
              const SizedBox(height: 16),

            if (isPending) // Accept or Decline buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(apt['id'], 'DECLINED'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.actionRed,
                        side: const BorderSide(color: AppColors.actionRed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(tr(context, 'reject_btn')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(apt['id'], 'CONFIRMED'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        tr(context, 'accept_btn'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),

            if (isConfirmed && isTimeReached) // Client arrived?
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showNoShowDialog(apt['id']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.actionRed,
                        side: const BorderSide(color: AppColors.actionRed),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.person_off, size: 18),
                      label: Text(
                        tr(context, 'no_show_btn'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(apt['id'], 'IN_PROGRESS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(
                        Icons.person_add_alt_1,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        tr(context, 'start_service_btn'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (isArrived)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus(apt['id'], 'IN_PROGRESS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    tr(context, 'start_service_btn'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            if (isInProgress)
              Column(
                children: [
                  if (isTimeReached) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showExtensionOptions(apt['id'], index),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textDark,
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.timer, color: Colors.grey),
                        label: Text(
                          tr(context, 'still_working'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(apt['id'], 'COMPLETED'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: Text(
                        tr(context, 'finished_haircut_q'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
  }

  void _showExtensionOptions(int appointmentId, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr(context, 'need_more_time'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr(context, 'how_much_time_to_add'),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _buildExtensionButton(ctx, appointmentId, 10, "10 mn"),
              const SizedBox(height: 12),
              _buildExtensionButton(ctx, appointmentId, 15, "15 mn"),
              const SizedBox(height: 12),
              _buildExtensionButton(ctx, appointmentId, 30, "30 mn"),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExtensionButton(
    BuildContext ctx,
    int appointmentId,
    int minutes,
    String label,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          Navigator.pop(ctx);
          try {
            await AppointmentService.extendAppointment(
              appointmentId: appointmentId,
              minutes: minutes,
            );
            _fetchAppointments();
          } catch (e) {
            _fetchAppointments();
          }
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          tr(context, 'add_time_btn', args: [label]),
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
