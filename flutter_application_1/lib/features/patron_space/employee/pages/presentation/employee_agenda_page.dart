import 'dart:async';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../services/appointment_service.dart';

class EmployeeAgendaPage extends StatefulWidget {
  const EmployeeAgendaPage({super.key});

  @override
  State<EmployeeAgendaPage> createState() => _EmployeeAgendaPageState();
}

class _EmployeeAgendaPageState extends State<EmployeeAgendaPage> {
  bool _isLoading = true;
  List<dynamic> _appointments = [];
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();

    // Poll the API every 10 seconds for real-time updates without fully reloading the UI
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _fetchAppointmentsSilent();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAppointments() async {
    try {
      final data = await AppointmentService.getEmployeeAppointments();
      if (!mounted) return;

      data.sort((a, b) {
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

      setState(() {
        _appointments = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAppointmentsSilent() async {
    try {
      final data = await AppointmentService.getEmployeeAppointments();
      if (!mounted) return;

      data.sort((a, b) {
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

      setState(() {
        _appointments = data;
      });
    } catch (e) {
      // Ignore errors on silent poll to not interrupt the user's flow
    }
  }

  Future<void> _updateStatus(
    int appointmentId,
    String newStatus,
    int index,
  ) async {
    try {
      toastification.show(
        context: context,
        type: ToastificationType.info,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 2),
        title: const Text(
          'Kaad ybadal...',
          style: TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.primaryBlue,
        backgroundColor: AppColors.primaryBlue,
      );

      // Call Backend API
      await AppointmentService.updateStatus(
        appointmentId: appointmentId,
        status: newStatus,
      );

      // Refresh list to get updated status from server
      await _fetchAppointments();

      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        title: const Text(
          'Badalna l\'statut! 🎉',
          style: TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.successGreen,
        backgroundColor: AppColors.successGreen,
      );
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        title: Text(
          tr(context, 'error_issue'),
          style: TextStyle(color: Colors.white),
        ),
        description: Text(
          e.toString(),
          style: const TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.actionRed,
        backgroundColor: AppColors.actionRed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Agenda mte3i",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : RefreshIndicator(
              onRefresh: _fetchAppointments,
              color: AppColors.primaryBlue,
              child: _appointments.isEmpty
                  ? const Center(
                      child: Text(
                        "Ma famma hatta rendez-vous lyoum.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _appointments.length,
                      itemBuilder: (context, index) {
                        final apt = _appointments[index];
                        return _buildAppointmentCard(apt, index);
                      },
                    ),
            ),
    );
  }

  Widget _buildAppointmentCard(dynamic apt, int index) {
    final status = (apt['status'] as String).toUpperCase();
    final isPending = status == 'PENDING';
    final isConfirmed = status == 'CONFIRMED' || status == 'ACCEPTED';
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
      statusText = "Yestanna";
    } else if (isConfirmed) {
      statusColor = AppColors.primaryBlue;
      statusText = "M'akd";
    } else if (isInProgress) {
      statusColor = Colors.purple;
      statusText = "En cours";
    } else if (isCompleted) {
      statusColor = AppColors.successGreen;
      statusText = "Kmal";
    } else if (isDeclined) {
      statusColor = AppColors.actionRed;
      statusText = "Morfodh";
    }

    String countdownText = "";
    bool isTimeReached = false;

    if (dateStr != null && (isConfirmed || isPending || isInProgress)) {
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
        countdownText = isInProgress ? "L'wa9t wfa!" : "L'wa9t r7el";

        // Auto-trigger the completion modal if the time just ran out recently (< 20 seconds) logic.
        // We do this by checking if difference is between 0 and -20s so it doesn't spam infinitely.
        if (isInProgress &&
            difference.inSeconds > -15 &&
            difference.inSeconds <= 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showCompletionModal(apt['id'], index);
          });
        }
      } else if (difference.inHours == 1 &&
          difference.inMinutes % 60 == 0 &&
          !isInProgress) {
        countdownText = "Mzel 1h";
      } else if (difference.inMinutes == 15 && !isInProgress) {
        countdownText = "Mzel 15mn";
      } else if (difference.inHours > 0) {
        countdownText =
            "Mazal ${difference.inHours}h ${difference.inMinutes % 60}min";
      } else {
        countdownText = "Mazal ${difference.inMinutes}min";
      }
    }

    return Container(
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

          if (isPending || isConfirmed || isInProgress)
            const SizedBox(height: 16),

          if (isPending) // Accept or Decline buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _updateStatus(apt['id'], 'DECLINED', index),
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
                    onPressed: () =>
                        _updateStatus(apt['id'], 'CONFIRMED', index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Ikbel",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

          if (isConfirmed && isTimeReached) // Client arrived?
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus(apt['id'], 'IN_PROGRESS', index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                label: const Text(
                  "Jek l client ?",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          if (isInProgress) // Finished?
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCompletionModal(apt['id'], index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                  "Kmalt l'hjema ?",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCompletionModal(int appointmentId, int index) {
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
              const Text(
                "Kmalt l'hjema ?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _updateStatus(appointmentId, 'COMPLETED', index);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Kamelt',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await AppointmentService.extendAppointment(
                        appointmentId: appointmentId,
                        minutes: 15,
                      );
                      _fetchAppointments();
                    } catch (e) {
                      // Handle error implicitly
                      _fetchAppointments(); // Refresh anyway just in case
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Zidni 15mn',
                    style: TextStyle(color: AppColors.textDark, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
