import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/core/services/location_service.dart';
import 'package:hjamty/features/client_space/salon_profile/data/salon_service.dart';
import 'package:hjamty/features/patron_space/salon_dashboard_screen.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const String _filterAll = 'All';
  static const String _filterNearest = 'Nearest';
  static const String _filterTopRated = 'Top Rated';
  static const String _filterOpenNow = 'Open Now';

  final AppLocationService _locationService = AppLocationService.instance;
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  bool _isLoading = false;
  bool _isLoadingAllSalons = true;
  bool _isHydratingPriceData = false;
  bool _hasSearched = false;
  String _selectedQuickFilter = _filterAll;
  String? _lastLocationKey;

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _allSalons = [];
  final Map<int, Map<String, dynamic>> _hydratedSalonCache = {};

  double? _maxDistanceKm;
  String _selectedPriceRange = 'Any';
  String? _selectedOpenUntil;
  double? _minRating;

  @override
  void initState() {
    super.initState();
    _locationService.addListener(_handleLocationChanged);
    unawaited(_locationService.initialize());
    _fetchAllSalons();
  }

  @override
  void dispose() {
    _locationService.removeListener(_handleLocationChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleLocationChanged() {
    final nextLocationKey = _buildLocationKey();
    if (_locationService.isLoading || nextLocationKey == _lastLocationKey) {
      return;
    }

    if (_searchController.text.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingAllSalons = true;
        });
      }
      _fetchAllSalons();
      return;
    }

    unawaited(_performSearch(_searchController.text.trim(), showLoader: false));
  }

  String _buildLocationKey() {
    return "${_locationService.latitude ?? 'null'}:${_locationService.longitude ?? 'null'}";
  }

  Future<void> _fetchAllSalons() async {
    try {
      _lastLocationKey = _buildLocationKey();
      final salons = await SalonService.getAllSalons(
        lat: _locationService.latitude,
        lng: _locationService.longitude,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _allSalons = salons
            .whereType<Map>()
            .map((salon) => Map<String, dynamic>.from(salon))
            .toList();
        _isLoadingAllSalons = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingAllSalons = false;
        _allSalons = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${tr(context, 'error_title')}: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    if (mounted) {
      setState(() {});
    }

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _performSearch(query.trim()),
    );
  }

  Future<void> _performSearch(String query, {bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
        _hasSearched = true;
      });
    }

    try {
      _lastLocationKey = _buildLocationKey();
      final results = await SalonService.searchSalons(
        query,
        lat: _locationService.latitude,
        lng: _locationService.longitude,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _searchResults = results
            .whereType<Map>()
            .map((salon) => Map<String, dynamic>.from(salon))
            .toList();
        _isLoading = false;
        _hasSearched = true;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _searchResults = [];
        _isLoading = false;
        _hasSearched = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showAdvancedFiltersSheet() async {
    double? tempMaxDistanceKm = _maxDistanceKm;
    String tempSelectedPriceRange = _selectedPriceRange;
    String? tempSelectedOpenUntil = _selectedOpenUntil;
    double? tempMinRating = _minRating;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildFilterSection(
                        title: 'Distance',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildChoiceChip(
                              label: 'Any',
                              isSelected: tempMaxDistanceKm == null,
                              onSelected: () {
                                setModalState(() {
                                  tempMaxDistanceKm = null;
                                });
                              },
                            ),
                            _buildChoiceChip(
                              label: '< 5 km',
                              isSelected: tempMaxDistanceKm == 5,
                              onSelected: () {
                                setModalState(() {
                                  tempMaxDistanceKm = 5;
                                });
                              },
                            ),
                            _buildChoiceChip(
                              label: '< 10 km',
                              isSelected: tempMaxDistanceKm == 10,
                              onSelected: () {
                                setModalState(() {
                                  tempMaxDistanceKm = 10;
                                });
                              },
                            ),
                            _buildChoiceChip(
                              label: '< 20 km',
                              isSelected: tempMaxDistanceKm == 20,
                              onSelected: () {
                                setModalState(() {
                                  tempMaxDistanceKm = 20;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      if (!_locationService.hasCoordinates)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            'Enable location bech distance filters ykounou d9a9.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      _buildFilterSection(
                        title: 'Service Price',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildChoiceChip(
                              label: 'Any',
                              isSelected: tempSelectedPriceRange == 'Any',
                              onSelected: () {
                                setModalState(() {
                                  tempSelectedPriceRange = 'Any';
                                });
                              },
                            ),
                            _buildChoiceChip(
                              label: '< 20 DT',
                              isSelected: tempSelectedPriceRange == 'Under20',
                              onSelected: () {
                                setModalState(() {
                                  tempSelectedPriceRange = 'Under20';
                                });
                              },
                            ),
                            _buildChoiceChip(
                              label: '20 - 40 DT',
                              isSelected: tempSelectedPriceRange == '20To40',
                              onSelected: () {
                                setModalState(() {
                                  tempSelectedPriceRange = '20To40';
                                });
                              },
                            ),
                            _buildChoiceChip(
                              label: '40+ DT',
                              isSelected: tempSelectedPriceRange == '40Plus',
                              onSelected: () {
                                setModalState(() {
                                  tempSelectedPriceRange = '40Plus';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      _buildFilterSection(
                        title: 'Open Until',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildChoiceChip(
                              label: 'Any',
                              isSelected: tempSelectedOpenUntil == null,
                              onSelected: () {
                                setModalState(() {
                                  tempSelectedOpenUntil = null;
                                });
                              },
                            ),
                            _buildChoiceChip(
                              label: '18:00+',
                              isSelected: tempSelectedOpenUntil == '18:00',
                              onSelected: () {
                                setModalState(() {
                                  tempSelectedOpenUntil = '18:00';
                                });
                              },
                            ),
                            _buildChoiceChip(
                              label: '20:00+',
                              isSelected: tempSelectedOpenUntil == '20:00',
                              onSelected: () {
                                setModalState(() {
                                  tempSelectedOpenUntil = '20:00';
                                });
                              },
                            ),
                            _buildChoiceChip(
                              label: '22:00+',
                              isSelected: tempSelectedOpenUntil == '22:00',
                              onSelected: () {
                                setModalState(() {
                                  tempSelectedOpenUntil = '22:00';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      _buildFilterSection(
                        title: 'Minimum Rating',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildChoiceChip(
                              label: 'Any',
                              isSelected: tempMinRating == null,
                              onSelected: () {
                                setModalState(() {
                                  tempMinRating = null;
                                });
                              },
                            ),
                            _buildChoiceChip(
                              label: '4.0+',
                              isSelected: tempMinRating == 4.0,
                              onSelected: () {
                                setModalState(() {
                                  tempMinRating = 4.0;
                                });
                              },
                            ),
                            _buildChoiceChip(
                              label: '4.5+',
                              isSelected: tempMinRating == 4.5,
                              onSelected: () {
                                setModalState(() {
                                  tempMinRating = 4.5;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  tempMaxDistanceKm = null;
                                  tempSelectedPriceRange = 'Any';
                                  tempSelectedOpenUntil = null;
                                  tempMinRating = null;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textDark,
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Clear all',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (tempMaxDistanceKm != null &&
                                    !_locationService.hasCoordinates) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Enable location 9bal ma تستعمل distance filter.',
                                      ),
                                      backgroundColor: AppColors.textDark,
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  await _applyAdvancedFilters(
                                    sheetContext: sheetContext,
                                    maxDistanceKm: tempMaxDistanceKm,
                                    selectedPriceRange: tempSelectedPriceRange,
                                    selectedOpenUntil: tempSelectedOpenUntil,
                                    minRating: tempMinRating,
                                  );
                                } catch (error) {
                                  if (!mounted) {
                                    return;
                                  }

                                  setState(() {
                                    _isHydratingPriceData = false;
                                  });
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text('Filter apply failed: $error'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _applyAdvancedFilters({
    required BuildContext sheetContext,
    required double? maxDistanceKm,
    required String selectedPriceRange,
    required String? selectedOpenUntil,
    required double? minRating,
  }) async {
    final currentQuery = _searchController.text.trim();
    final shouldHydratePriceData = selectedPriceRange != 'Any';

    if (mounted) {
      setState(() {
        _maxDistanceKm = maxDistanceKm;
        _selectedPriceRange = selectedPriceRange;
        _selectedOpenUntil = selectedOpenUntil;
        _minRating = minRating;
        _isHydratingPriceData = shouldHydratePriceData;
      });
    }

    if (Navigator.of(sheetContext).canPop()) {
      Navigator.of(sheetContext).pop();
    }

    if (!shouldHydratePriceData) {
      return;
    }

    if (currentQuery.isEmpty) {
      await _fetchAllSalons();
    } else {
      await _performSearch(currentQuery, showLoader: false);
    }

    await _hydrateMissingPriceData();
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primaryBlue,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textDark,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }

  void _onQuickFilterTap(String filter) {
    if (filter == _filterNearest && !_locationService.hasCoordinates) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable location bech nearest sorting ykoun d9i9.'),
          backgroundColor: AppColors.textDark,
        ),
      );
      return;
    }

    setState(() {
      _selectedQuickFilter = filter;
    });
  }

  List<Map<String, dynamic>> _applySalonView(
    List<Map<String, dynamic>> source,
  ) {
    final salons = source
        .where(
          (salon) =>
              (salon['approvalStatus']?.toString().toUpperCase() ??
                  'APPROVED') ==
              'APPROVED',
        )
        .where(_matchesAdvancedFilters)
        .toList();

    if (_selectedQuickFilter == _filterOpenNow) {
      salons.retainWhere(_isOpenNow);
      salons.sort(_compareByDistanceThenRating);
      return salons;
    }

    if (_selectedQuickFilter == _filterNearest) {
      salons.sort(_compareByDistanceThenRating);
      return salons;
    }

    if (_selectedQuickFilter == _filterTopRated) {
      salons.sort(_compareByTopRated);
      return salons;
    }

    return salons;
  }

  bool _matchesAdvancedFilters(Map<String, dynamic> salon) {
    final ratingValue = _ratingValue(salon);
    final distanceKm = _distanceKm(salon);
    final servicePrices = _servicePrices(salon);

    if (_maxDistanceKm != null) {
      if (distanceKm == null || distanceKm > _maxDistanceKm!) {
        return false;
      }
    }

    if (_selectedPriceRange != 'Any') {
      if (servicePrices.isEmpty) {
        return false;
      }

      if (!_matchesSelectedPriceRange(servicePrices)) {
        return false;
      }
    }

    if (_selectedOpenUntil != null) {
      final time = _parseTimeOfDay(_selectedOpenUntil!);
      if (time == null || !_isOpenUntil(salon, time)) {
        return false;
      }
    }

    if (_minRating != null && ratingValue < _minRating!) {
      return false;
    }

    return true;
  }

  int _compareByDistanceThenRating(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final aDistance = _distanceKm(a);
    final bDistance = _distanceKm(b);

    if (aDistance == null && bDistance == null) {
      return _compareByTopRated(a, b);
    }
    if (aDistance == null) {
      return 1;
    }
    if (bDistance == null) {
      return -1;
    }

    final distanceCompare = aDistance.compareTo(bDistance);
    if (distanceCompare != 0) {
      return distanceCompare;
    }

    return _compareByTopRated(a, b);
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

  Future<void> _hydrateMissingPriceData() async {
    final baseSalons = _hasSearched ? _searchResults : _allSalons;
    final salonIds = baseSalons
        .where(_needsPriceHydration)
        .map(_salonId)
        .whereType<int>()
        .where((id) => !_hydratedSalonCache.containsKey(id))
        .toList();

    if (salonIds.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = _mergeHydratedSalonData(_searchResults);
          _allSalons = _mergeHydratedSalonData(_allSalons);
          _isHydratingPriceData = false;
        });
      }
      return;
    }

    final hydratedEntries = await Future.wait(
      salonIds.map((id) async {
        try {
          final detail = await SalonService.getSalonById(
            id,
            lat: _locationService.latitude,
            lng: _locationService.longitude,
          );
          return MapEntry(id, detail);
        } catch (_) {
          return null;
        }
      }),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      for (final entry in hydratedEntries.whereType<MapEntry<int, Map<String, dynamic>>>()) {
        _hydratedSalonCache[entry.key] = entry.value;
      }

      _searchResults = _mergeHydratedSalonData(_searchResults);
      _allSalons = _mergeHydratedSalonData(_allSalons);
      _isHydratingPriceData = false;
    });
  }

  List<Map<String, dynamic>> _mergeHydratedSalonData(
    List<Map<String, dynamic>> salons,
  ) {
    return salons.map((salon) {
      final id = _salonId(salon);
      if (id == null) {
        return salon;
      }

      final hydratedSalon = _hydratedSalonCache[id];
      if (hydratedSalon == null) {
        return salon;
      }

      final merged = Map<String, dynamic>.from(salon);
      final hydratedServices = hydratedSalon['services'];
      if (hydratedServices is List) {
        merged['services'] = hydratedServices;
      }

      merged['startingPrice'] =
          _toDouble(merged['startingPrice']) ??
          _calculateStartingPrice(hydratedServices);

      return merged;
    }).toList();
  }

  bool _needsPriceHydration(Map<String, dynamic> salon) {
    if (_hasPriceData(salon)) {
      return false;
    }

    return _salonId(salon) != null;
  }

  bool _hasPriceData(Map<String, dynamic> salon) {
    if (_toDouble(salon['startingPrice']) != null) {
      return true;
    }

    final services = salon['services'];
    if (services is! List) {
      return false;
    }

    return services.whereType<Map>().any(
      (service) => _toDouble(service['price']) != null,
    );
  }

  int? _salonId(Map<String, dynamic> salon) {
    final rawId = salon['id'];
    if (rawId is int) {
      return rawId;
    }
    if (rawId is num) {
      return rawId.toInt();
    }
    if (rawId is String) {
      return int.tryParse(rawId);
    }
    return null;
  }

  double? _calculateStartingPrice(dynamic services) {
    if (services is! List) {
      return null;
    }

    double? startingPrice;
    for (final service in services.whereType<Map>()) {
      final price = _toDouble(service['price']);
      if (price == null) {
        continue;
      }

      if (startingPrice == null || price < startingPrice) {
        startingPrice = price;
      }
    }

    return startingPrice;
  }

  List<Map<String, dynamic>> _matchedServices(Map<String, dynamic> salon) {
    final services = _salonServices(salon);
    if (services.isEmpty) {
      return const [];
    }

    final normalizedQuery = _normalizeSearchText(_searchController.text);
    if (normalizedQuery.isEmpty && _selectedPriceRange == 'Any') {
      return const [];
    }

    var matchedServices = services;

    if (normalizedQuery.isNotEmpty) {
      final queryMatches = services
          .where((service) => _serviceMatchesQuery(service, normalizedQuery))
          .toList();
      if (queryMatches.isNotEmpty) {
        matchedServices = queryMatches;
      }
    }

    if (_selectedPriceRange != 'Any') {
      final priceMatches = matchedServices.where((service) {
        final price = _toDouble(service['price']);
        return price != null && _matchesSelectedPrice(price);
      }).toList();

      if (priceMatches.isNotEmpty) {
        matchedServices = priceMatches;
      }
    }

    matchedServices.sort((a, b) {
      final priceCompare = (_toDouble(a['price']) ?? double.infinity).compareTo(
        _toDouble(b['price']) ?? double.infinity,
      );
      if (priceCompare != 0) {
        return priceCompare;
      }

      return (a['name']?.toString() ?? '').compareTo(b['name']?.toString() ?? '');
    });

    return matchedServices;
  }

  double? _displayStartingPrice(Map<String, dynamic> salon) {
    final matchedPrices = _matchedServices(salon)
        .map((service) => _toDouble(service['price']))
        .whereType<double>()
        .toList();

    if (matchedPrices.isNotEmpty) {
      matchedPrices.sort();
      return matchedPrices.first;
    }

    return _toDouble(salon['startingPrice']) ??
        _calculateStartingPrice(salon['services']);
  }

  List<double> _servicePrices(Map<String, dynamic> salon) {
    final services = _salonServices(salon);
    if (services.isEmpty) {
      final fallbackStartingPrice = _toDouble(salon['startingPrice']);
      return fallbackStartingPrice != null
          ? [fallbackStartingPrice]
          : const [];
    }

    final normalizedQuery = _normalizeSearchText(_searchController.text);
    final relevantServices = normalizedQuery.isEmpty
        ? services
        : services
            .where((service) => _serviceMatchesQuery(service, normalizedQuery))
            .toList();

    final priceSource = relevantServices.isNotEmpty ? relevantServices : services;
    final prices = priceSource
        .map((service) => _toDouble(service['price']))
        .whereType<double>()
        .toList();

    if (prices.isNotEmpty) {
      return prices;
    }

    final fallbackStartingPrice = _toDouble(salon['startingPrice']);
    return fallbackStartingPrice != null ? [fallbackStartingPrice] : const [];
  }

  List<Map<String, dynamic>> _salonServices(Map<String, dynamic> salon) {
    final services = salon['services'];
    if (services is! List) {
      return const [];
    }

    return services
        .whereType<Map>()
        .map((service) => Map<String, dynamic>.from(service))
        .toList();
  }

  bool _serviceMatchesQuery(
    Map<String, dynamic> service,
    String normalizedQuery,
  ) {
    final serviceName = _normalizeSearchText(service['name']?.toString() ?? '');
    if (serviceName.isEmpty || normalizedQuery.isEmpty) {
      return false;
    }

    if (serviceName.contains(normalizedQuery) ||
        normalizedQuery.contains(serviceName)) {
      return true;
    }

    final queryTokens = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((token) => token.length >= 2);

    for (final token in queryTokens) {
      if (serviceName.contains(token)) {
        return true;
      }
    }

    return false;
  }

  String _normalizeSearchText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _matchesSelectedPriceRange(List<double> prices) {
    for (final price in prices) {
      if (_matchesSelectedPrice(price)) {
        return true;
      }
    }

    return false;
  }

  bool _matchesSelectedPrice(double price) {
    return switch (_selectedPriceRange) {
      'Under20' => price < 20,
      '20To40' => price >= 20 && price <= 40,
      '40Plus' => price > 40,
      _ => true,
    };
  }

  bool _isOpenNow(Map<String, dynamic> salon) {
    if (salon['isForceClosed'] == true) {
      return false;
    }

    final todayHours = _todayWorkingHours(salon);
    if (todayHours == null || (todayHours['isDayOff'] ?? false) == true) {
      return false;
    }

    final openMinutes = _parseMinutes(todayHours['openTime']?.toString());
    final closeMinutes = _parseMinutes(todayHours['closeTime']?.toString());
    if (openMinutes == null || closeMinutes == null) {
      return false;
    }

    final now = DateTime.now();
    final currentMinutes = (now.hour * 60) + now.minute;
    return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
  }

  bool _isOpenUntil(Map<String, dynamic> salon, TimeOfDay targetTime) {
    if (salon['isForceClosed'] == true) {
      return false;
    }

    final todayHours = _todayWorkingHours(salon);
    if (todayHours == null || (todayHours['isDayOff'] ?? false) == true) {
      return false;
    }

    final openMinutes = _parseMinutes(todayHours['openTime']?.toString());
    final closeMinutes = _parseMinutes(todayHours['closeTime']?.toString());
    if (openMinutes == null || closeMinutes == null) {
      return false;
    }

    final targetMinutes = (targetTime.hour * 60) + targetTime.minute;
    return openMinutes <= targetMinutes && closeMinutes >= targetMinutes;
  }

  Map<String, dynamic>? _todayWorkingHours(Map<String, dynamic> salon) {
    final workingHours = salon['workingHours'];
    if (workingHours is! List) {
      return null;
    }

    final today = DateTime.now().weekday;
    for (final entry in workingHours.whereType<Map>()) {
      final dayValue = entry['dayOfWeek'];
      if (dayValue is num && dayValue.toInt() == today) {
        return Map<String, dynamic>.from(entry);
      }
    }

    return null;
  }

  String _openingStateLabel(Map<String, dynamic> salon) {
    if (_isOpenNow(salon)) {
      final todayHours = _todayWorkingHours(salon);
      final closeTime = todayHours?['closeTime']?.toString();
      if (closeTime != null && closeTime.isNotEmpty) {
        return 'Open until $closeTime';
      }
      return 'Open now';
    }

    return 'Closed';
  }

  Color _openingStateColor(Map<String, dynamic> salon) {
    return _isOpenNow(salon) ? AppColors.successGreen : AppColors.actionRed;
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

  int? _parseMinutes(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }

    return (hour * 60) + minute;
  }

  TimeOfDay? _parseTimeOfDay(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  int _activeAdvancedFiltersCount() {
    var count = 0;

    if (_maxDistanceKm != null) {
      count += 1;
    }
    if (_selectedPriceRange != 'Any') {
      count += 1;
    }
    if (_selectedOpenUntil != null) {
      count += 1;
    }
    if (_minRating != null) {
      count += 1;
    }

    return count;
  }

  List<String> _activeFilterSummary() {
    final summary = <String>[];

    if (_selectedQuickFilter != _filterAll) {
      summary.add(_selectedQuickFilter);
    }
    if (_maxDistanceKm != null) {
      summary.add('< ${_maxDistanceKm!.toStringAsFixed(0)} km');
    }
    if (_selectedPriceRange == 'Under20') {
      summary.add('< 20 DT');
    } else if (_selectedPriceRange == '20To40') {
      summary.add('20 - 40 DT');
    } else if (_selectedPriceRange == '40Plus') {
      summary.add('40+ DT');
    }
    if (_selectedOpenUntil != null) {
      summary.add('Until $_selectedOpenUntil');
    }
    if (_minRating != null) {
      summary.add('${_minRating!.toStringAsFixed(1)}+');
    }

    return summary;
  }

  @override
  Widget build(BuildContext context) {
    final baseSalons = _hasSearched ? _searchResults : _allSalons;
    final visibleSalons = _applySalonView(baseSalons);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildFilters(),
            if (_activeFilterSummary().isNotEmpty) _buildActiveFiltersBanner(),
            Expanded(
              child: _buildBodyContent(
                visibleSalons: visibleSalons,
                baseSalons: baseSalons,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade500,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: tr(context, 'search_hint'),
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 15,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _hasSearched = false;
                          _isLoading = false;
                          _isLoadingAllSalons = true;
                        });
                        if (_debounce?.isActive ?? false) {
                          _debounce!.cancel();
                        }
                        _fetchAllSalons();
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final activeAdvancedFilters = _activeAdvancedFiltersCount();

    return Container(
      height: 60,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _buildQuickFilterChip(
            label: _filterAll,
            icon: Icons.tune_rounded,
            isSelected: _selectedQuickFilter == _filterAll,
            onTap: () => _onQuickFilterTap(_filterAll),
          ),
          _buildQuickFilterChip(
            label: _filterNearest,
            icon: Icons.near_me_rounded,
            isSelected: _selectedQuickFilter == _filterNearest,
            onTap: () => _onQuickFilterTap(_filterNearest),
          ),
          _buildQuickFilterChip(
            label: _filterTopRated,
            icon: Icons.star_rounded,
            isSelected: _selectedQuickFilter == _filterTopRated,
            onTap: () => _onQuickFilterTap(_filterTopRated),
          ),
          _buildQuickFilterChip(
            label: _filterOpenNow,
            icon: Icons.access_time_rounded,
            isSelected: _selectedQuickFilter == _filterOpenNow,
            onTap: () => _onQuickFilterTap(_filterOpenNow),
          ),
          _buildQuickFilterChip(
            label: activeAdvancedFilters == 0
                ? 'Filters'
                : 'Filters ($activeAdvancedFilters)',
            icon: Icons.filter_list_rounded,
            isSelected: activeAdvancedFilters > 0,
            onTap: _showAdvancedFiltersSheet,
            trailingIcon: Icons.keyboard_arrow_down_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? trailingIcon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.textDark : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? (icon == Icons.star_rounded ? Colors.amber : Colors.white)
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(
                trailingIcon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersBanner() {
    final summary = _activeFilterSummary();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E5FF)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primaryBlue,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summary.join(' | '),
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent({
    required List<Map<String, dynamic>> visibleSalons,
    required List<Map<String, dynamic>> baseSalons,
  }) {
    if (_isHydratingPriceData) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (_hasSearched && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (!_hasSearched && _isLoadingAllSalons) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (baseSalons.isEmpty) {
      return _buildEmptyState(
        icon: Icons.storefront_rounded,
        title: tr(context, 'no_salon_found'),
        subtitle: 'Try another keyword or check your connection.',
      );
    }

    if (visibleSalons.isEmpty) {
      return _buildEmptyState(
        icon: Icons.filter_alt_off_rounded,
        title: 'No salons match these filters',
        subtitle: 'Badel service price, hour, distance walla rating filters.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visibleSalons.length,
      itemBuilder: (context, index) => _buildResultCard(visibleSalons[index]),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> salon) {
    final distanceKm = _distanceKm(salon);
    final isOpenNow = _isOpenNow(salon);
    final matchedServices = _matchedServices(salon);
    final startingPrice = _displayStartingPrice(salon);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SalonDashboardScreen(isPatron: false, salonId: salon['id']),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    salon['image'] ?? 'https://via.placeholder.com/150',
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 92,
                        height: 92,
                        color: Colors.grey.shade100,
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Colors.grey,
                          size: 30,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              salon['name'] ?? tr(context, 'salon_name_default'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: AppColors.textDark,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildRatingBadge(salon),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              salon['address'] ??
                                  tr(context, 'address_unavailable'),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (matchedServices.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildServiceHighlights(matchedServices),
                      ] else if (startingPrice != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Starting from ${_formatPrice(startingPrice)} DT',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (distanceKm != null)
                            _buildMetaPill(
                              icon: Icons.near_me_rounded,
                              label: '${distanceKm.toStringAsFixed(1)} km',
                            ),
                          _buildMetaPill(
                            icon: isOpenNow
                                ? Icons.schedule_rounded
                                : Icons.do_not_disturb_on_outlined,
                            label: _openingStateLabel(salon),
                            textColor: _openingStateColor(salon),
                            backgroundColor:
                                _openingStateColor(salon).withOpacity(0.08),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Padding(
                  padding: EdgeInsets.only(top: 36),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceHighlights(List<Map<String, dynamic>> services) {
    final visibleServices = services.take(2).toList();
    final hiddenCount = services.length - visibleServices.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _serviceHighlightsTitle(),
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final service in visibleServices)
              _buildServicePill(
                label:
                    '${service['name']?.toString() ?? 'Service'} - ${_formatPrice(_toDouble(service['price']) ?? 0)} DT',
              ),
            if (hiddenCount > 0) _buildServicePill(label: '+$hiddenCount services'),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingBadge(Map<String, dynamic> salon) {
    final reviews = _reviewCount(salon);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
          const SizedBox(width: 4),
          Text(
            salon['rating']?.toString() ?? '0.0',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          if (reviews > 0) ...[
            const SizedBox(width: 4),
            Text(
              '($reviews)',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaPill({
    required IconData icon,
    required String label,
    Color? textColor,
    Color? backgroundColor,
  }) {
    final resolvedColor = textColor ?? Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: resolvedColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: resolvedColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicePill({required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7E5FF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price == price.roundToDouble()) {
      return price.toStringAsFixed(0);
    }

    return price.toStringAsFixed(1);
  }

  String _serviceHighlightsTitle() {
    final hasQuery = _searchController.text.trim().isNotEmpty;
    if (_selectedPriceRange != 'Any' && !hasQuery) {
      return 'Services in range';
    }

    return 'Matching services';
  }
}
