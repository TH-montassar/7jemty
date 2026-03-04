import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/translation_service.dart';
import '../../../../../services/appointment_service.dart';
import 'package:toastification/toastification.dart';

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
          tr(context, 'no_history'),
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
                      if (apt['review'] == null) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final result = await showDialog(
                                context: context,
                                builder: (_) => _ReviewDialog(appointment: apt),
                              );
                              if (result == true) {
                                _fetchAppointments(); // Refresh the list after successful review
                                if (!context.mounted) return;
                                toastification.show(
                                  context: context,
                                  type: ToastificationType.success,
                                  title: const Text('Merci!'),
                                  description: const Text(
                                    'Votre avis a été ajouté avec succès.',
                                  ),
                                  autoCloseDuration: const Duration(seconds: 3),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.amber),
                              foregroundColor: Colors.amber[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(tr(context, 'leave_review')),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
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
        title: const Text('Erreur'),
        description: const Text('Veuillez sélectionner une note.'),
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
        title: const Text('Erreur'),
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
      title: const Text(
        'Laisser un avis',
        style: TextStyle(fontWeight: FontWeight.bold),
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
              hintText: 'Votre commentaire (optionnel)',
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
          child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
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
              : const Text('Envoyer', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
