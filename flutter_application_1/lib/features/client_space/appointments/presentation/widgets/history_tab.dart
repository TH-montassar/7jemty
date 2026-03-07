import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/features/client_space/appointments/data/appointment_service.dart';
import 'package:toastification/toastification.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
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
              'COMPLETED',
              'CANCELLED',
              'DECLINED',
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

    // Sort by Date descending for History
    filtered.sort((a, b) {
      final dateA =
          DateTime.tryParse(a['appointmentDate'] ?? '') ?? DateTime.now();
      final dateB =
          DateTime.tryParse(b['appointmentDate'] ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA); // Reverse chronological
    });

    setState(() {
      _appointments = filtered;
    });
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
                                  if (apt['review'] == null) ...[
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
                                  ],
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {},
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
          // Date Filter Chip
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
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
        description: Text(e.toString()),
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
