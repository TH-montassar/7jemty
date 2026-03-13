import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocationService extends ChangeNotifier {
  AppLocationService._();

  static final AppLocationService instance = AppLocationService._();

  static const String _defaultLabel = 'Set location';
  static const String _preciseLabel = 'My location';
  static const String _labelKey = 'client_location_label';
  static const String _latitudeKey = 'client_location_latitude';
  static const String _longitudeKey = 'client_location_longitude';
  static const String _preciseKey = 'client_location_is_precise';

  Future<void>? _initializeFuture;
  bool _isLoading = false;
  String _label = _defaultLabel;
  double? _latitude;
  double? _longitude;
  bool _usesPreciseLocation = false;

  bool get isLoading => _isLoading;
  String get label => _label;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get hasCoordinates => _latitude != null && _longitude != null;
  bool get usesPreciseLocation => _usesPreciseLocation;

  Future<void> initialize() {
    return _initializeFuture ??= _loadStoredLocation();
  }

  Future<String?> refreshCurrentLocation() async {
    await initialize();

    if (_isLoading) {
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return 'F3al GPS bech nratboulek a9reb salons 7asb blastek.';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return 'A3tini permission mta3 location bech njib a9reb salons.';
      }

      if (permission == LocationPermission.deniedForever) {
        return 'Location permission maskra. 7ellha men settings bach tist3ml nearby.';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;
      _label = await _resolveLabel(position.latitude, position.longitude);
      _usesPreciseLocation = true;

      await _persistLocation();

      return null;
    } catch (_) {
      return 'Ma najamnich njib location tawa. 3awed ba3d chwaya.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearLocation() async {
    await initialize();
    _setNoLocation();
    await _persistLocation();
    notifyListeners();
  }

  Future<void> _loadStoredLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final storedLatitude = prefs.getDouble(_latitudeKey);
    final storedLongitude = prefs.getDouble(_longitudeKey);
    final storedLabel = prefs.getString(_labelKey);
    final storedPrecise = prefs.getBool(_preciseKey) ?? false;

    if (storedPrecise &&
        storedLatitude != null &&
        storedLongitude != null) {
      _latitude = storedLatitude;
      _longitude = storedLongitude;
      _label = storedLabel?.trim().isNotEmpty == true
          ? storedLabel!
          : _preciseLabel;
      _usesPreciseLocation = true;
    } else {
      // Old fallback data such as "Ariana, Tunis" is cleared on startup.
      _setNoLocation();
      await _persistLocation();
    }

    notifyListeners();
  }

  Future<void> _persistLocation() async {
    final prefs = await SharedPreferences.getInstance();

    if (_usesPreciseLocation && _latitude != null && _longitude != null) {
      await prefs.setDouble(_latitudeKey, _latitude!);
      await prefs.setDouble(_longitudeKey, _longitude!);
      await prefs.setString(_labelKey, _label);
      await prefs.setBool(_preciseKey, true);
      return;
    }

    await prefs.remove(_latitudeKey);
    await prefs.remove(_longitudeKey);
    await prefs.setString(_labelKey, _defaultLabel);
    await prefs.setBool(_preciseKey, false);
  }

  void _setNoLocation() {
    _latitude = null;
    _longitude = null;
    _label = _defaultLabel;
    _usesPreciseLocation = false;
  }

  Future<String> _resolveLabel(double latitude, double longitude) async {
    if (kIsWeb) {
      return _preciseLabel;
    }

    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        return _preciseLabel;
      }

      final placemark = placemarks.first;
      final primary = _firstNonEmpty([
        placemark.subLocality,
        placemark.locality,
        placemark.subAdministrativeArea,
        placemark.administrativeArea,
      ]);
      final secondary = _firstNonEmpty([
        placemark.locality,
        placemark.subAdministrativeArea,
        placemark.administrativeArea,
      ]);

      if (primary == null) {
        return _preciseLabel;
      }

      if (secondary != null && secondary.toLowerCase() != primary.toLowerCase()) {
        return '$primary, $secondary';
      }

      return primary;
    } catch (_) {
      return _preciseLabel;
    }
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return null;
  }
}
