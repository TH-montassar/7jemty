import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/core/services/location_service.dart';
import 'package:hjamty/core/utils/cloudinary_utils.dart';
import 'package:hjamty/features/client_space/salon_profile/data/salon_service.dart';
import 'package:hjamty/features/patron_space/salon_dashboard_screen.dart';

class TopRatedList extends StatefulWidget {
  const TopRatedList({super.key});

  @override
  State<TopRatedList> createState() => _TopRatedListState();
}

class _TopRatedListState extends State<TopRatedList> {
  static const int _maxItems = 10;

  final AppLocationService _locationService = AppLocationService.instance;
  late Future<List<dynamic>> _topSalonsFuture;
  String? _lastLocationKey;

  @override
  void initState() {
    super.initState();
    _topSalonsFuture = _fetchTopRatedSalons();
    _locationService.addListener(_handleLocationChanged);
    unawaited(_locationService.initialize());
  }

  @override
  void dispose() {
    _locationService.removeListener(_handleLocationChanged);
    super.dispose();
  }

  void _handleLocationChanged() {
    final nextKey = _buildLocationKey();
    if (_locationService.isLoading || nextKey == _lastLocationKey) {
      return;
    }

    setState(() {
      _topSalonsFuture = _fetchTopRatedSalons();
    });
  }

  Future<List<dynamic>> _fetchTopRatedSalons() async {
    _lastLocationKey = _buildLocationKey();
    final salons = await SalonService.getAllSalons(
      lat: _locationService.latitude,
      lng: _locationService.longitude,
    );

    final rankedSalons = salons
        .whereType<Map>()
        .map((salon) => Map<String, dynamic>.from(salon))
        .where(_isApprovedSalon)
        .toList()
      ..sort(_compareByTopRated);

    if (rankedSalons.length <= _maxItems) {
      return rankedSalons;
    }

    return rankedSalons.take(_maxItems).toList();
  }

  String _buildLocationKey() {
    return "${_locationService.latitude ?? 'null'}:${_locationService.longitude ?? 'null'}";
  }

  bool _isApprovedSalon(Map<String, dynamic> salon) {
    return (salon['approvalStatus']?.toString().toUpperCase() ?? 'APPROVED') ==
        'APPROVED';
  }

  int _compareByTopRated(Map<String, dynamic> a, Map<String, dynamic> b) {
    final ratingCompare = _ratingValue(b).compareTo(_ratingValue(a));
    if (ratingCompare != 0) {
      return ratingCompare;
    }

    final reviewCompare = _reviewCount(b).compareTo(_reviewCount(a));
    if (reviewCompare != 0) {
      return reviewCompare;
    }

    return _compareByDistanceThenName(a, b);
  }

  int _compareByDistanceThenName(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final aDistance = _distanceKm(a);
    final bDistance = _distanceKm(b);

    if (aDistance != null && bDistance != null) {
      final distanceCompare = aDistance.compareTo(bDistance);
      if (distanceCompare != 0) {
        return distanceCompare;
      }
    }

    return (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? '');
  }

  double _ratingValue(Map<String, dynamic> salon) {
    return _toDouble(salon['rating']) ?? 0;
  }

  int _reviewCount(Map<String, dynamic> salon) {
    final rawCount = salon['reviewCount'];
    if (rawCount is num) {
      return rawCount.toInt();
    }

    final rawCounter = salon['_count'];
    if (rawCounter is Map && rawCounter['reviews'] is num) {
      return (rawCounter['reviews'] as num).toInt();
    }

    final reviews = salon['reviews'];
    if (reviews is List) {
      return reviews.length;
    }

    return 0;
  }

  double? _distanceKm(Map<String, dynamic> salon) {
    final directValue = _toDouble(salon['distanceKm']);
    if (directValue != null) {
      return directValue;
    }

    final distanceLabel = salon['distance']?.toString();
    if (distanceLabel == null) {
      return null;
    }

    return double.tryParse(distanceLabel.replaceAll(RegExp(r'[^0-9.]'), ''));
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _topSalonsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Mochkla fil connexion: \n${snapshot.error}",
                style: const TextStyle(color: AppColors.actionRed),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "Mawasalnech 7ata salon m9ayem tawa.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final topSalons = snapshot.data!
            .whereType<Map>()
            .map((salon) => Map<String, dynamic>.from(salon))
            .toList();

        if (topSalons.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Mawasalnech 7ata salon m9ayem tawa.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: topSalons.length,
          itemBuilder: (context, index) {
            final salon = topSalons[index];
            final startingPrice = (salon['startingPrice'] as num?)?.toDouble();

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SalonDashboardScreen(
                      isPatron: false,
                      salonId: salon['id'],
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        CloudinaryUtils.getOptimizedUrl(
                              salon['image'],
                              width: 200,
                            ) ??
                            'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=500&q=80',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade100,
                            child: const Icon(
                              Icons.storefront,
                              color: Colors.grey,
                              size: 30,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            salon['name'] ?? 'Salon',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            salon['address'] ?? 'Adresse non fournie',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            startingPrice != null
                                ? 'A partir de ${startingPrice.toStringAsFixed(0)} DT'
                                : tr(context, 'starting_from'),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    salon['rating']?.toString() ?? '0.0',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              SizedBox(
                                height: 34,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SalonDashboardScreen(
                                              isPatron: false,
                                              salonId: salon['id'],
                                            ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.actionRed,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    tr(context, 'reserve_btn'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
