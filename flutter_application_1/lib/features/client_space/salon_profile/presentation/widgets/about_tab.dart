import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';

class AboutTab extends StatefulWidget {
  final Map<String, dynamic> salonData;

  const AboutTab({super.key, required this.salonData});

  @override
  State<AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends State<AboutTab> {
  double? _lat;
  double? _lng;
  bool _isLoadingMap = true;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initializeCoordinates();
  }

  void _initializeCoordinates() {
    final dynamic latVal = widget.salonData['latitude'];
    final dynamic lngVal = widget.salonData['longitude'];
    final String? googleMapsUrl = widget.salonData['googleMapsUrl'];

    double? parsedLat;
    double? parsedLng;

    if (latVal != null && lngVal != null) {
      parsedLat = double.tryParse(latVal.toString());
      parsedLng = double.tryParse(lngVal.toString());
    }

    if (parsedLat != null && parsedLng != null) {
      setState(() {
        _lat = parsedLat;
        _lng = parsedLng;
        _isLoadingMap = false;
      });
    } else if (googleMapsUrl != null && googleMapsUrl.isNotEmpty) {
      if (googleMapsUrl.contains('maps.app.goo.gl') ||
          googleMapsUrl.contains('goo.gl/maps')) {
        _resolveShortenedUrl(googleMapsUrl);
      } else {
        final coords = _extractCoordsFromUrl(googleMapsUrl);
        if (coords != null) {
          setState(() {
            _lat = coords.latitude;
            _lng = coords.longitude;
            _isLoadingMap = false;
          });
        } else {
          _geocodeAddress();
        }
      }
    } else {
      _geocodeAddress();
    }
  }

  Future<void> _resolveShortenedUrl(String shortUrl) async {
    try {
      final request = http.Request('GET', Uri.parse(shortUrl))
        ..followRedirects = true;
      final response = await http.Client().send(request);
      final finalUrl =
          response.headers['location'] ??
          response.request?.url.toString() ??
          shortUrl;

      final coords = _extractCoordsFromUrl(finalUrl);
      if (coords != null && mounted) {
        setState(() {
          _lat = coords.latitude;
          _lng = coords.longitude;
          _isLoadingMap = false;
        });
        _mapController.move(coords, 16.5);
        return;
      }
    } catch (e) {
      debugPrint('Error resolving shortened URL: $e');
    }
    _geocodeAddress();
  }

  ll.LatLng? _extractCoordsFromUrl(String url) {
    try {
      final decodedUrl = Uri.decodeComponent(url);

      // Pattern 5: !3dlat!4dlng (Google Place/Business data - MOST ACCURATE)
      final regExp5 = RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)');
      final match5 = regExp5.firstMatch(decodedUrl);
      if (match5 != null) {
        return ll.LatLng(
          double.parse(match5.group(1)!),
          double.parse(match5.group(2)!),
        );
      }

      // Pattern 1: @lat,lng (Google Maps view or pin center)
      final regExp1 = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)');
      final match1 = regExp1.firstMatch(decodedUrl);
      if (match1 != null) {
        return ll.LatLng(
          double.parse(match1.group(1)!),
          double.parse(match1.group(2)!),
        );
      }

      // Pattern 2: query=lat,lng or q=lat,lng
      final regExp2 = RegExp(r'[?&](query|q)=(-?\d+\.\d+),\s*(-?\d+\.\d+)');
      final match2 = regExp2.firstMatch(decodedUrl);
      if (match2 != null) {
        return ll.LatLng(
          double.parse(match2.group(2)!),
          double.parse(match2.group(3)!),
        );
      }

      // Pattern 3: /maps/search/lat,lng
      final regExp3 = RegExp(r'/maps/search/(-?\d+\.\d+),\s*(-?\d+\.\d+)');
      final match3 = regExp3.firstMatch(decodedUrl);
      if (match3 != null) {
        return ll.LatLng(
          double.parse(match3.group(1)!),
          double.parse(match3.group(2)!),
        );
      }

      // Pattern 4: any lat,lng in the URL (Last resort)
      final regExp4 = RegExp(r'(-?\d+\.\d+),\s*(-?\d+\.\d+)');
      final matches = regExp4.allMatches(decodedUrl);
      if (matches.isNotEmpty) {
        final lastMatch = matches.last;
        return ll.LatLng(
          double.parse(lastMatch.group(1)!),
          double.parse(lastMatch.group(2)!),
        );
      }
    } catch (e) {
      debugPrint('Error extracting coords from URL: $e');
    }
    return null;
  }

  Future<void> _geocodeAddress() async {
    final String address = widget.salonData['address'] ?? 'Tunis, Tunisia';
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1',
        ),
        headers: {'User-Agent': '7jemty_App'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final double newLat = double.parse(data[0]['lat']);
          final double newLng = double.parse(data[0]['lon']);
          if (mounted) {
            setState(() {
              _lat = newLat;
              _lng = newLng;
              _isLoadingMap = false;
            });
            // Move map to new location
            _mapController.move(ll.LatLng(newLat, newLng), 16.5);
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }

    // Fallback to default if geocoding fails
    if (mounted) {
      setState(() {
        _lat = 36.85; // Default Beja
        _lng = 9.19;
        _isLoadingMap = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openMaps(String query) async {
    final String? googleMapsUrl = widget.salonData['googleMapsUrl'];
    final dynamic latVal = widget.salonData['latitude'] ?? _lat;
    final dynamic lngVal = widget.salonData['longitude'] ?? _lng;

    Uri uri;

    if (googleMapsUrl != null && googleMapsUrl.isNotEmpty) {
      uri = Uri.parse(googleMapsUrl);
    } else if (latVal != null && lngVal != null) {
      uri = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$latVal,$lngVal",
      );
    } else {
      uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String description =
        widget.salonData['description'] ??
        tr(context, 'salon_description_placeholder');
    final String address = widget.salonData['address'] ?? 'Tunis, Tunisia';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. Quick action cards
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionCard(
              context,
              icon: Icons.phone_outlined,
              label: tr(context, 'call_btn').toUpperCase(),
              onTap: () {
                if (widget.salonData['contactPhone'] != null) {
                  _makePhoneCall(widget.salonData['contactPhone']);
                }
              },
            ),
            _buildActionCard(
              context,
              icon: Icons.camera_alt_outlined,
              label: tr(context, 'social_btn').toUpperCase(),
              onTap: () {
                // TODO: Open social links
              },
            ),
            _buildActionCard(
              context,
              icon: Icons.location_on_outlined,
              label: tr(context, 'maps_btn').toUpperCase(),
              onTap: () => _openMaps(address),
            ),
          ],
        ),
        const SizedBox(height: 30),

        // 2. Location section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr(context, 'location_title'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            TextButton(
              onPressed: () => _openMaps(address),
              child: Text(
                tr(context, 'open_in_maps'),
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.black.withAlpha(10)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Stack(
              children: [
                if (_lat != null && _lng != null)
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: ll.LatLng(_lat!, _lng!),
                      initialZoom: 16.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                        subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                        userAgentPackageName: 'com.hjamty.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: ll.LatLng(_lat!, _lng!),
                            width: 40,
                            height: 40,
                            alignment: Alignment.bottomCenter,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                if (_isLoadingMap)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.touch_app,
                            size: 16,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tr(context, 'click_to_interact').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryBlue,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),

        // 3. À Propos Section
        Text(
          tr(context, 'about_title'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 100), // Padding for bottom FAB
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.28,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withAlpha(8)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 28),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryBlue,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
