import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/core/services/location_service.dart';
import 'package:intl/intl.dart';

class SalonInfoSection extends StatelessWidget {
  final Map<String, dynamic> salonData;

  const SalonInfoSection({super.key, required this.salonData});

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  String _distanceLabel(AppLocationService locationService) {
    final userLat = locationService.latitude;
    final userLng = locationService.longitude;
    final salonLat = _toDouble(salonData['latitude']);
    final salonLng = _toDouble(salonData['longitude']);

    if (userLat != null &&
        userLng != null &&
        salonLat != null &&
        salonLng != null) {
      final distanceKm =
          Geolocator.distanceBetween(userLat, userLng, salonLat, salonLng) /
          1000;

      return '${distanceKm.toStringAsFixed(1)} km';
    }

    final apiDistance = salonData['distance']?.toString().trim();
    if (apiDistance != null &&
        apiDistance.isNotEmpty &&
        apiDistance != '--' &&
        apiDistance.toLowerCase() != 'unknown') {
      return apiDistance;
    }

    return '--';
  }

  @override
  Widget build(BuildContext context) {
    final locationService = AppLocationService.instance;

    final now = DateTime.now();
    final currentDay = now.weekday;
    final workingHours = salonData['workingHours'] as List<dynamic>? ?? [];
    final todayHours = workingHours.firstWhere(
      (wh) => wh['dayOfWeek'] == currentDay,
      orElse: () => null,
    );

    final int reviewsCount =
        (salonData['reviews'] as List<dynamic>?)?.length ?? 0;
    final String displayRating = reviewsCount == 0
        ? '0.0'
        : (salonData['rating']?.toString() ?? '0.0');

    bool isOpen = false;
    String? closeTimeStr;

    if (todayHours != null) {
      final isDayOff = todayHours['isDayOff'] ?? false;
      if (!isDayOff) {
        final oTime = todayHours['openTime'] as String?;
        final cTime = todayHours['closeTime'] as String?;
        if (oTime != null && cTime != null) {
          try {
            final format = DateFormat.Hm();
            final openDT = format.parse(oTime);
            final closeDT = format.parse(cTime);
            final currentDT = DateTime(1970, 1, 1, now.hour, now.minute);

            if (currentDT.isAfter(openDT) && currentDT.isBefore(closeDT)) {
              isOpen = true;
              closeTimeStr = DateFormat.jm().format(closeDT);
            }
          } catch (_) {
            isOpen = true;
            closeTimeStr = cTime;
          }
        }
      }
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (salonData['speciality'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    salonData['speciality'].toString().toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              const Spacer(),
              _buildStatusBadge(context),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            salonData['name'] ?? 'Salon',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: locationService,
            builder: (context, _) {
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.black, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          displayRating,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$reviewsCount avis',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '|',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _distanceLabel(locationService),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 40, color: Color(0xFFF5F5F5)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primaryBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            salonData['address'] ??
                                tr(context, 'address_ariana'),
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: AppColors.primaryBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOpen
                              ? "Ouvert jusqu'a ${closeTimeStr ?? ''}"
                              : 'Ferme actuellement',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isOpen
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOpen ? 'OUVERT' : 'FERME',
                  style: TextStyle(
                    color: isOpen ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final String status = salonData['approvalStatus'] ?? 'PENDING';
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'APPROVED':
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        label = tr(context, 'active');
        break;
      case 'SUSPENDED':
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        label = tr(context, 'deactivated');
        break;
      case 'PENDING':
      default:
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        label = tr(context, 'waiting_approval');
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
