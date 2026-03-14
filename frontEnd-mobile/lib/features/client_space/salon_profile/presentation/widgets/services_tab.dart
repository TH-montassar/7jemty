import 'package:hjamty/core/localization/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/features/client_space/appointments/presentation/pages/booking_flow_screen.dart';

class ServicesTab extends StatelessWidget {
  final Map<String, dynamic>? salonData;

  const ServicesTab({super.key, this.salonData});

  void _openBooking(BuildContext context, Map<String, dynamic> service) {
    final serviceId = (service['id'] as num?)?.toInt();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingFlowScreen(
          salonId: (salonData?['id'] as num?)?.toInt() ?? 0,
          initialServiceIds: serviceId != null ? [serviceId] : null,
        ),
      ),
    );
  }

  void _showServiceDetails(BuildContext context, Map<String, dynamic> service) {
    final imageUrl = service['imageUrl']?.toString();
    final name = service['name']?.toString() ?? '';
    final description =
        service['description']?.toString().trim().isNotEmpty == true
        ? service['description'].toString().trim()
        : 'Aucune description disponible pour ce service.';
    final duration = (service['durationMinutes'] as num?)?.toInt() ?? 30;
    final price = service['price'] ?? 0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.08,
                              ),
                              child: const Icon(
                                Icons.design_services_rounded,
                                size: 52,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.primaryBlue.withValues(alpha: 0.08),
                            child: const Icon(
                              Icons.design_services_rounded,
                              size: 52,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$price DT',
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$duration min',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _openBooking(context, service);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.textDark,
                          elevation: 0,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          tr(context, 'reserve_btn'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> services = salonData?['services'] ?? [];

    if (services.isEmpty) {
      return Center(
        child: Text(
          tr(context, 'no_service_available'),
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final s = Map<String, dynamic>.from(services[index] as Map);
        return GestureDetector(
          onTap: () => _showServiceDetails(context, s),
          child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['name']?.toString() ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${s['durationMinutes'] ?? 30} min',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${s['price'] ?? 0} TND',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _openBooking(context, s),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    tr(context, 'reserve_btn'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
