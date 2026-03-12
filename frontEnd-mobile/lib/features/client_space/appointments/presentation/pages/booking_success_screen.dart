import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/features/client_space/main_layout/presentation/pages/client_main_layout.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingSuccessScreen extends StatelessWidget {
  final String salonName;
  final String salonAddress;
  final DateTime date;
  final String time;
  final int durationMinutes;
  final List<Map<String, dynamic>> services;
  final double totalPrice;
  final String barberName;

  const BookingSuccessScreen({
    super.key,
    required this.salonName,
    required this.salonAddress,
    required this.date,
    required this.time,
    required this.durationMinutes,
    required this.services,
    required this.totalPrice,
    required this.barberName,
  });

  DateTime _buildStartDateTime() {
    final parts = time.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Uri _buildGoogleCalendarUri() {
    final start = _buildStartDateTime();
    final end = start.add(Duration(minutes: durationMinutes));
    final utcFormat = DateFormat("yyyyMMdd'T'HHmmss'Z'");
    final startUtc = utcFormat.format(start.toUtc());
    final endUtc = utcFormat.format(end.toUtc());
    final serviceNames = services
        .map((service) => service['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .join(', ');

    final details = StringBuffer()
      ..write('Salon: $salonName')
      ..write('\nSpécialiste: $barberName');

    if (serviceNames.isNotEmpty) {
      details.write('\nServices: $serviceNames');
    }

    return Uri.parse('https://calendar.google.com/calendar/render').replace(
      queryParameters: {
        'action': 'TEMPLATE',
        'text': 'Rendez-vous - $salonName',
        'dates': '$startUtc/$endUtc',
        'details': details.toString(),
        'location': salonAddress,
      },
    );
  }

  Future<void> _addToCalendar(BuildContext context) async {
    final uri = _buildGoogleCalendarUri();
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible d'ouvrir le calendrier pour le moment."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateStr = DateFormat('EEE., MMM. d', 'fr_FR').format(date);

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkmark Circle
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Réservation en attente',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Description
              const Text(
                'Votre rendez-vous est en attente. Le personnel du\nsalon le confirmera sous peu.',
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Salon Name
                    Center(
                      child: Text(
                        salonName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Date Row
                    _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      title: dateStr,
                      subtitle: 'Date',
                    ),
                    const SizedBox(height: 15),

                    // Time Row
                    _buildInfoRow(
                      icon: Icons.access_time_outlined,
                      title: time,
                      subtitle: '$durationMinutes min',
                    ),
                    const SizedBox(height: 15),

                    // Location Row
                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      title: salonAddress.isNotEmpty
                          ? salonAddress
                          : 'Adresse non spécifiée',
                      subtitle: 'Emplacement',
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.grey, thickness: 0.5),
                    const SizedBox(height: 15),

                    // Services List
                    ...services.map(
                      (service) => Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              service['name'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              '${service['price']} TND',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Divider(color: Colors.grey, thickness: 0.5),
                    const SizedBox(height: 15),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$totalPrice TND',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Specialist
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SPÉCIALISTE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          barberName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Calendar Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _addToCalendar(context),
                  icon: const Icon(
                    Icons.share,
                    size: 20,
                    color: Colors.black87,
                  ),
                  label: const Text(
                    'Ajouter au calendrier',
                    style: TextStyle(color: Colors.black87),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // View Appointments Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ClientMainLayout(initialIndex: 1),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Voir mes rendez-vous',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.isNotEmpty ? title : '---',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
