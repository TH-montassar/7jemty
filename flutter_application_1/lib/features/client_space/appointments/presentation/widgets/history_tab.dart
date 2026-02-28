import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/translation_service.dart';
import '../../../../../services/appointment_service.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
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
                'COMPLETED',
                'CANCELLED',
                'DECLINED',
              ].contains((a['status'] as String).toUpperCase()),
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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
          tr(context, 'no_history') ?? 'Aucun historique récent.',
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

          final isCancelled = [
            'CANCELLED',
            'DECLINED',
          ].contains((apt['status'] as String).toUpperCase());

          // Format date
          final dateStr = apt['appointmentDate'];
          final DateTime date = dateStr != null
              ? DateTime.parse(dateStr)
              : DateTime.now();
          final formattedDate = DateFormat('dd MMM yyyy', 'fr_FR').format(date);

          final salonName = apt['salon']?['name'] ?? 'Salon inconnu';

          // Extract services and total price
          final servicesList = apt['services'] as List<dynamic>? ?? [];
          final serviceNames = servicesList
              .map((s) => s['service']['name'])
              .join(' + ');
          final price = apt['totalPrice'] ?? 0;

          final statusText = isCancelled ? 'Tbatel' : 'Kmal';

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: isCancelled
                  ? Border.all(color: Colors.red.withValues(alpha: 0.2))
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
                    color: isCancelled ? Colors.grey : AppColors.textDark,
                  ),
                ),
                Text(
                  "$serviceNames - $price DT",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (!isCancelled) ...[
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.amber),
                            foregroundColor: Colors.amber[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            tr(context, 'leave_review') ?? 'Khali avis',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue.withValues(
                              alpha: 0.1,
                            ),
                            foregroundColor: AppColors.primaryBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(tr(context, 'rebook') ?? 'Aawed Ahjez'),
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
    );
  }
}
