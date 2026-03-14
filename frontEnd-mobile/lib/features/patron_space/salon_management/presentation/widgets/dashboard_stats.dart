import 'package:flutter/material.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/core/widgets/info_card.dart';

class DashboardStats extends StatelessWidget {
  final Map<String, dynamic>? salonData;
  final int loyaltyPoints;
  final int nextRewardTarget;
  final int remainingAppointmentsCount;
  final VoidCallback? onRenewTap;

  const DashboardStats({
    super.key,
    required this.salonData,
    required this.loyaltyPoints,
    required this.nextRewardTarget,
    required this.remainingAppointmentsCount,
    this.onRenewTap,
  });

  bool get _isSalonActive {
    final approvalStatus =
        (salonData?['approvalStatus'] ?? 'PENDING').toString().toUpperCase();
    final isForceClosed = salonData?['isForceClosed'] == true;
    return approvalStatus == 'APPROVED' && !isForceClosed;
  }

  String get _statusLabel {
    final approvalStatus =
        (salonData?['approvalStatus'] ?? 'PENDING').toString().toUpperCase();
    final isForceClosed = salonData?['isForceClosed'] == true;

    if (isForceClosed) return 'Fermé';
    if (approvalStatus == 'APPROVED') return 'Actif';
    if (approvalStatus == 'PENDING') return 'En attente';
    return 'Inactif';
  }

  @override
  Widget build(BuildContext context) {
    final progress = nextRewardTarget <= 0
        ? 0.0
        : (loyaltyPoints / nextRewardTarget).clamp(0.0, 1.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isSalonActive ? Icons.check_circle : Icons.pause_circle,
                      color: _isSalonActive ? Colors.blue : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Abonnement',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Statut: $_statusLabel',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      remainingAppointmentsCount.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'RDV restants',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onRenewTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(tr(context, 'renew_btn')),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Points Fidélité',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.star_border, color: Colors.blue, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Points: $loyaltyPoints',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Prochaine récompense: $nextRewardTarget pts',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    color: Colors.blue,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
