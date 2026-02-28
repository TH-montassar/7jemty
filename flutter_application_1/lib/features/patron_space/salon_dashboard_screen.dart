import 'package:hjamty/core/localization/translation_service.dart';
import 'package:flutter/material.dart';
import '../../core/utils/cloudinary_utils.dart';
import '../../core/constants/app_colors.dart';
import '../../services/salon_service.dart';
import '../../services/appointment_service.dart';
import 'package:intl/intl.dart';

import '../client_space/salon_profile/presentation/pages/salon_setting_screen.dart';
import '../client_space/appointments/presentation/pages/booking_flow_screen.dart';
import 'create_salon_screen.dart';
import '../client_space/salon_profile/presentation/widgets/sticky_tab_bar_delegate.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

class SalonDashboardScreen extends StatefulWidget {
  final bool isPatron;
  final int?
  salonId; // Optional: Only provided if a client views a specific salon

  const SalonDashboardScreen({super.key, this.isPatron = false, this.salonId});

  @override
  State<SalonDashboardScreen> createState() => _SalonDashboardScreenState();
}

class _SalonDashboardScreenState extends State<SalonDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _salonData;

  @override
  void initState() {
    super.initState();
    _fetchSalonData();
  }

  Future<void> _fetchSalonData() async {
    try {
      final response = widget.isPatron
          ? await SalonService.getMySalon()
          : await SalonService.getSalonById(widget.salonId!);
      if (!mounted) return;

      setState(() {
        _salonData = response;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (e.toString().contains('Salon introuvable')) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 6),
          title: const Text(
            'Mochkla',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          description: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(color: Colors.white),
          ),
          primaryColor: AppColors.actionRed,
          backgroundColor: AppColors.actionRed,
          icon: const Icon(Icons.error_outline, color: Colors.white),
          showProgressBar: false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgColor,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    if (_salonData == null) {
      return Scaffold(
        backgroundColor: AppColors.bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                "Ma famma hatta salon.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateSalonScreen(),
                        ),
                      ).then((_) => _fetchSalonData());
                    },
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text(
                      "Aamel salon mte3ek",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _fetchSalonData,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(tr(context, 'reload_btn')),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final tabs = <Tab>[
      const Tab(text: "Tafasil"),
      const Tab(text: "Services"),
      const Tab(text: "Spécialiste"),
    ];
    if (widget.isPatron) {
      tabs.add(const Tab(text: "Rendez-vous"));
    }
    tabs.add(const Tab(text: "Avis"));

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: AppColors.bgColor,
        floatingActionButton: !widget.isPatron && widget.salonId != null
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BookingFlowScreen(salonId: widget.salonId!),
                    ),
                  );
                },
                backgroundColor: AppColors.primaryBlue,
                icon: const Icon(Icons.calendar_month, color: Colors.white),
                label: const Text(
                  "Prendre Rendez-vous",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              // 1. Header Image & AppBar
              SliverAppBar(
                expandedHeight: 220.0,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primaryBlue,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  if (widget.isPatron)
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SalonScreenUnifiee(),
                          ),
                        ).then((value) => _fetchSalonData());
                      },
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_salonData?['coverImageUrl'] != null &&
                          (_salonData!['coverImageUrl'] as String).isNotEmpty)
                        Image.network(
                          CloudinaryUtils.getOptimizedUrl(
                                _salonData!['coverImageUrl'] as String,
                                width: 1000,
                              ) ??
                              '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryBlue,
                                  Color(0xFF1565C0),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryBlue,
                                Color(0xFF1565C0),
                              ],
                            ),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Infos Salon
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _salonData?['name'] ?? 'Salon mte3i',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Mahloul",
                              style: TextStyle(
                                color: AppColors.successGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _salonData?['address'] ??
                                  'Ma famma hatta adresse',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 20, color: Colors.amber),
                          const SizedBox(width: 4),
                          const Text(
                            "4.9",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "(0 avis)",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Sticky Tabs (5 tabs)
              SliverPersistentHeader(
                pinned: true,
                delegate: StickyTabBarDelegate(
                  TabBar(
                    isScrollable: true,
                    labelColor: AppColors.primaryBlue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primaryBlue,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: tabs,
                  ),
                ),
              ),
            ];
          },

          // 4. Tab content
          body: TabBarView(
            children: [
              _buildApercuTab(),
              _buildServicesTab(),
              _buildSpecialistesTab(),
              if (widget.isPatron) _buildReservationsTab(),
              _buildAvisTab(),
            ],
          ),
        ),
      ),
    );
  }

  // TABS BUILDERS
  // ============================================

  Future<void> _launchUrlStr(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;

    // Check if it's just coordinates (used for Apple/Google Maps scheme fallback)
    Uri uri = Uri.parse(urlString);

    // If it's a generic link instead of a scheme
    if (!urlString.startsWith('http') && !urlString.startsWith('tel:')) {
      uri = Uri.parse('https://$urlString');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $urlString");
    }
  }

  void _openMap() {
    final googleMapsUrl = _salonData?['googleMapsUrl'] as String?;
    if (googleMapsUrl != null && googleMapsUrl.isNotEmpty) {
      _launchUrlStr(googleMapsUrl);
      return;
    }

    // Fallback if we only have address and lat/long
    final lat = _salonData?['latitude'];
    final lng = _salonData?['longitude'];
    if (lat != null && lng != null) {
      final String googleUrl =
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      _launchUrlStr(googleUrl);
    }
  }

  Widget _buildApercuTab() {
    final socialLinks = (_salonData?['socialLinks'] as List?) ?? [];
    final workingHours = (_salonData?['workingHours'] as List?) ?? [];
    final portfolio = (_salonData?['portfolio'] as List?) ?? [];

    // Sort working hours by dayOfWeek (1 = Monday, 7 = Sunday)
    workingHours.sort(
      (a, b) => (a['dayOfWeek'] as int? ?? 0).compareTo(
        (b['dayOfWeek'] as int? ?? 0),
      ),
    );

    final daysMap = {
      1: 'Lundi',
      2: 'Mardi',
      3: 'Mercredi',
      4: 'Jeudi',
      5: 'Vendredi',
      6: 'Samedi',
      7: 'Dimanche',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Aal salon",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _salonData?['description'] ?? 'Ma famma hatta description tawa.',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Contact & Adresse",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  final phone = _salonData?['contactPhone'];
                  if (phone != null && phone.isNotEmpty) {
                    _launchUrlStr('tel:$phone');
                  }
                },
                child: Text(
                  _salonData?['contactPhone'] ?? 'Mouch m9ayed',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on,
                size: 20,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _openMap,
                  child: Text(
                    _salonData?['address'] ?? 'Adresse mouch m9ayda',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (socialLinks.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              "Reseaux Sociaux",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: socialLinks.map<Widget>((link) {
                IconData iconData = Icons.link;
                String platform = (link['platform'] ?? '')
                    .toString()
                    .toLowerCase();
                if (platform == 'facebook') iconData = Icons.facebook;
                if (platform == 'instagram') iconData = Icons.camera_alt;
                if (platform == 'tiktok') iconData = Icons.music_note;

                return InkWell(
                  onTap: () => _launchUrlStr(link['url']),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          if (workingHours.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              "Aw9at el 5edma",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: workingHours.map<Widget>((wh) {
                  final dayName =
                      daysMap[wh['dayOfWeek']] ?? 'Jour ${wh['dayOfWeek']}';
                  final isOff = wh['isDayOff'] == true;
                  final open = wh['openTime'] ?? '--:--';
                  final close = wh['closeTime'] ?? '--:--';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          isOff ? "Mesaker" : "$open - $close",
                          style: TextStyle(
                            color: isOff ? Colors.red : Colors.grey.shade700,
                            fontWeight: isOff
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          if (portfolio.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              "Portfolio",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(), // we are in a SingleChildScrollView
              itemCount: portfolio.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final imageUrl = portfolio[index]['imageUrl'];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    CloudinaryUtils.getOptimizedUrl(imageUrl, width: 400) ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    final services = (_salonData?['services'] as List<dynamic>?) ?? [];

    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cut_outlined, size: 70, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              "Ma famma hatta service tawa.",
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            if (widget.isPatron) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to Settings and select the active tab automatically
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SalonScreenUnifiee(
                        initialTabIndex: 1, // Services tab
                        openAddForm: true,
                      ),
                    ),
                  ).then((_) => _fetchSalonData());
                },
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text(
                  "Zid service jdid",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        final String name = service['name'] ?? 'Service';
        final double price = (service['price'] as num?)?.toDouble() ?? 0.0;
        final int duration = (service['durationMinutes'] as num?)?.toInt() ?? 0;
        final String? description = service['description'];
        final String? imageUrl = service['imageUrl'];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Image or icon
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        CloudinaryUtils.getOptimizedUrl(imageUrl, width: 300) ??
                            '',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _servicePlaceholder(),
                      )
                    : _servicePlaceholder(),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${price.toStringAsFixed(0)} DT",
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$duration min",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _servicePlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: AppColors.primaryBlue.withOpacity(0.1),
    );
  }

  Widget _buildReservationsTab() {
    return FutureBuilder<List<dynamic>>(
      future: AppointmentService.getSalonAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Erreur: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 60,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Ma famma hatta rendez-vous lyoum.",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final apt = appointments[index];
            final clientName = apt['client']['fullName'] ?? 'Client';
            final clientPhone = apt['client']['phoneNumber'] ?? '';
            final aptDate = apt['appointmentDate'];
            final aptTime = apt['startTime'];
            final status = apt['status'];

            final dateFormatted = aptDate != null
                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(aptDate))
                : '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          clientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textDark,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: status == 'PENDING'
                                ? Colors.orange.withOpacity(0.1)
                                : status == 'CONFIRMED'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: status == 'PENDING'
                                  ? Colors.orange
                                  : status == 'CONFIRMED'
                                  ? Colors.green
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (clientPhone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Tél: $clientPhone",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dateFormatted,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          aptTime ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if (status == 'PENDING') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                try {
                                  await AppointmentService.updateStatus(
                                    appointmentId: apt['id'],
                                    status: 'DECLINED',
                                  );
                                  setState(() {}); // refresh FutureBuilder
                                } catch (e) {
                                  toastification.show(
                                    context: context,
                                    type: ToastificationType.error,
                                    title: const Text('Erreur'),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Refuser",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await AppointmentService.updateStatus(
                                    appointmentId: apt['id'],
                                    status: 'CONFIRMED',
                                  );
                                  setState(() {}); // refresh FutureBuilder
                                } catch (e) {
                                  toastification.show(
                                    context: context,
                                    type: ToastificationType.error,
                                    title: const Text('Erreur'),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.successGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Accepter",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSpecialistesTab() {
    final employees = (_salonData?['employees'] as List<dynamic>?) ?? [];

    return Column(
      children: [
        if (widget.isPatron)
          // Add button at top
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SalonScreenUnifiee(
                        initialTabIndex: 2, // 2 is Equipe tab for Patron
                        openAddForm: true,
                      ),
                    ),
                  ).then((_) => _fetchSalonData());
                },
                icon: const Icon(
                  Icons.person_add_alt_1,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  "+ Zid Specialiste fereger",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        if (employees.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                "Ma famma hatta specialiste tawa.",
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final emp = employees[index] as Map<String, dynamic>;
                final name = (emp['name'] ?? 'Specialiste') as String;
                final role = (emp['role'] ?? 'Spécialiste') as String;
                final bio = emp['bio'] as String?;
                final imageUrl = emp['imageUrl'] as String?;

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                        backgroundImage: imageUrl != null
                            ? NetworkImage(
                                CloudinaryUtils.getOptimizedUrl(
                                      imageUrl,
                                      width: 200,
                                    ) ??
                                    '',
                              )
                            : null,
                        child: imageUrl == null
                            ? Text(
                                name.isNotEmpty
                                    ? name.substring(0, 1).toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                role,
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (bio != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                bio,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAvisTab() {
    return const Center(
      child: Text(
        "Ma famma hatta avis mtaa client tawa.",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
