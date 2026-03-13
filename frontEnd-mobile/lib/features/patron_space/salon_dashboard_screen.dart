import 'package:hjamty/core/localization/translation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hjamty/core/utils/cloudinary_utils.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/features/client_space/salon_profile/data/salon_service.dart';
import 'package:hjamty/features/client_space/appointments/data/appointment_service.dart';
import 'package:hjamty/core/services/notification_service.dart';
import 'package:hjamty/core/services/location_service.dart';
import 'package:hjamty/features/client_space/appointments/presentation/widgets/appointment_details_bottom_sheet.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'package:hjamty/core/services/fcm_service.dart';
import 'package:hjamty/features/patron_space/appointments/presentation/widgets/no_show_flow.dart';

import 'package:hjamty/features/client_space/salon_profile/presentation/pages/salon_setting_screen.dart';
import 'package:hjamty/features/client_space/appointments/presentation/pages/booking_flow_screen.dart';
import 'create_salon_screen.dart';
import 'package:hjamty/features/client_space/salon_profile/presentation/widgets/sticky_tab_bar_delegate.dart';
import 'package:toastification/toastification.dart';
import '../../features/client_space/salon_profile/presentation/widgets/salon_info_section.dart';
import '../../features/client_space/salon_profile/presentation/widgets/about_tab.dart';
import 'package:hjamty/features/client_space/salon_profile/presentation/widgets/reviews_tab.dart';
import 'package:hjamty/features/client_space/salon_profile/presentation/widgets/portfolio_tab.dart';
import 'package:hjamty/core/widgets/notification_bell.dart';
import 'package:hjamty/features/auth/data/auth_service.dart';
import 'package:hjamty/features/auth/signIn.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalonDashboardScreen extends StatefulWidget {
  final bool isPatron;
  final int?
  salonId; // Optional: Only provided if a client views a specific salon
  final bool showBackButton;
  final bool isAdminPeek;
  final int initialTabIndex;
  final int? focusAppointmentId;

  const SalonDashboardScreen({
    super.key,
    this.isPatron = false,
    this.salonId,
    this.showBackButton = false,
    this.isAdminPeek = false,
    this.initialTabIndex = 0,
    this.focusAppointmentId,
  });

  @override
  State<SalonDashboardScreen> createState() => _SalonDashboardScreenState();
}

class _SalonDashboardScreenState extends State<SalonDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _salonData;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;
  StreamSubscription<Map<String, dynamic>>? _fcmSubscription;
  bool _hasShownInactiveSalonPopup = false;
  String _reservationStatusFilter = 'ALL';
  String _reservationSortField = 'APPOINTMENT_DATE';
  bool _reservationSortAscending = true;
  bool _hasOpenedFocusedAppointment = false;

  @override
  void initState() {
    super.initState();
    _fetchSalonData();
    if (kIsWeb) {
      NotificationService.listenToNotificationsStream();
    }
    _setupFcmListener();
  }

  @override
  void didUpdateWidget(covariant SalonDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusAppointmentId != widget.focusAppointmentId) {
      _hasOpenedFocusedAppointment = false;
    }
  }

  void _setupFcmListener() {
    _fcmSubscription = FcmService.messageStream.listen((data) {
      if (data['type'] == 'APPOINTMENT_UPDATED') {
        if (mounted) {
          // Re-trigger FutureBuilder by calling setState
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    super.dispose();
  }

  void _maybeShowInactiveSalonPopup(Map<String, dynamic> salonData) {
    if (!mounted || _hasShownInactiveSalonPopup) return;
    if (!widget.isPatron || widget.salonId != null) return;

    final status =
        (salonData['approvalStatus'] ?? 'PENDING').toString().toUpperCase();
    if (status == 'APPROVED') return;

    _hasShownInactiveSalonPopup = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(tr(context, 'information_title')),
          content: Text(tr(context, 'salon_not_active_popup_desc')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr(context, 'ok_btn')),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _fetchSalonData() async {
    try {
      final locationService = AppLocationService.instance;
      await locationService.initialize();

      final response = (widget.isPatron && widget.salonId == null)
          ? await SalonService.getMySalon()
          : await SalonService.getSalonById(
              widget.salonId!,
              lat: locationService.latitude,
              lng: locationService.longitude,
            );
      if (!mounted) return;

      bool isFav = false;
      if (response['id'] != null && !widget.isPatron) {
        isFav = await SalonService.checkFavoriteStatus(response['id']);
      }

      if (!mounted) return;

      setState(() {
        _salonData = response;
        _isFavorite = isFav;
        _isLoading = false;
      });

      _maybeShowInactiveSalonPopup(response);
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

  Future<void> _shareSalon() async {
    if (_salonData == null) return;
    final name = _salonData!['name'] ?? 'Salon';
    final address = _salonData!['address'] ?? '';
    final rating = _salonData!['rating']?.toString() ?? '?';
    final message =
        '\u{1F3EA} $name\n\u{2B50} $rating / 5\n\u{1F4CD} $address\n\nD\u{00E9}couvre ce salon sur Hjamty!';
    try {
      await Share.share(message);
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_salonData == null || _salonData!['id'] == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
      return;
    }

    // Optimistic UI update
    setState(() {
      _isFavorite = !_isFavorite;
      _isLoadingFavorite = true;
    });

    try {
      final isNowFavorite = await SalonService.toggleFavoriteSalon(
        _salonData!['id'],
      );
      if (!mounted) return;

      setState(() {
        _isFavorite = isNowFavorite;
        _isLoadingFavorite = false;
      });
    } catch (e) {
      // Revert on error
      if (!mounted) return;
      setState(() {
        _isFavorite = !_isFavorite;
        _isLoadingFavorite = false;
      });

      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        title: const Text(
          'Mochkla',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        description: Text(
          e.toString(),
          style: const TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.actionRed,
        backgroundColor: AppColors.actionRed,
      );
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
      Tab(text: tr(context, 'tab_details')),
      Tab(text: tr(context, 'services_tab_val')),
      Tab(text: tr(context, 'tab_specialist')),
    ];
    if (widget.isPatron) {
      tabs.add(Tab(text: tr(context, 'tab_appointments')));
    }
    if (widget.isPatron || widget.isAdminPeek) {
      tabs.add(Tab(text: tr(context, 'working_hours')));
    }
    tabs.add(Tab(text: tr(context, 'portfolio')));
    tabs.add(Tab(text: tr(context, 'tab_reviews')));

    final resolvedInitialTabIndex = widget.initialTabIndex
        .clamp(0, tabs.length - 1)
        .toInt();

    return DefaultTabController(
      length: tabs.length,
      initialIndex: resolvedInitialTabIndex,
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
                label: Text(
                  tr(context, 'reserve_btn'),
                  style: const TextStyle(
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
                automaticallyImplyLeading: false,
                leading: (widget.isPatron && !widget.showBackButton)
                    ? const SizedBox.shrink()
                    : Container(
                        margin: const EdgeInsets.all(8.0),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                            size: 20,
                          ),
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                actions: [
                  if (!widget.isPatron) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      width: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.share_outlined,
                          color: Colors.black,
                          size: 20,
                        ),
                        onPressed: _shareSalon,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      width: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _isLoadingFavorite
                          ? const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isFavorite
                                    ? AppColors.actionRed
                                    : Colors.black,
                                size: 20,
                              ),
                              onPressed: () {
                                // Only clients can favorite
                                if (!widget.isPatron) {
                                  _toggleFavorite();
                                }
                              },
                            ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Show for patron or admin
                  FutureBuilder<Map<String, dynamic>>(
                    future: AuthService.getMe(),
                    builder: (context, snapshot) {
                      final bool isAdmin =
                          snapshot.hasData &&
                          snapshot.data?['data']?['role'] == 'ADMIN';
                      if (widget.isPatron || isAdmin) {
                        return Row(
                          children: [
                            const NotificationBell(),
                            IconButton(
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SalonScreenUnifiee(
                                      salonId: widget.salonId,
                                      isAdminPeek: widget.isAdminPeek,
                                    ),
                                  ),
                                ).then((_) => _fetchSalonData());
                              },
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
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

              // 2. Infos Salon (Premium Info Section)
              SliverToBoxAdapter(
                child: SalonInfoSection(salonData: _salonData!),
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

          body: TabBarView(
            children: [
              AboutTab(salonData: _salonData!),
              _buildServicesTab(),
              _buildSpecialistesTab(),
              if (widget.isPatron) _buildReservationsTab(),
              if (widget.isPatron || widget.isAdminPeek)
                _buildWorkingTimesTab(),
              PortfolioTab(salonData: _salonData!),
              _buildAvisTab(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateAptStatus(int id, String status) async {
    await updateAppointmentStatusFlow(
      context: context,
      appointmentId: id,
      status: status,
      successMessage: tr(context, 'status_updated', args: [status]),
      errorMessage: tr(context, 'error_updating_status'),
      onUpdated: () async {
        if (!mounted) return;
        setState(() {});
      },
    );
  }

  Future<void> _showNoShowDialog(int appointmentId) async {
    await showNoShowDecisionDialog(
      context: context,
      appointmentId: appointmentId,
      onConfirmNoShow: (id) => _updateAptStatus(id, 'CANCELLED'),
      onPostpone15: (id) => postponeNoShowWithCascadeFlow(
        context: context,
        appointmentId: id,
        onRefresh: () async {
          if (!mounted) return;
          setState(() {});
        },
      ),
    );
  }

  DateTime? _safeDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  DateTime? _reservationCreatedDate(dynamic appointment) {
    return _safeDate(appointment['createdAt']) ??
        _safeDate(appointment['created_at']) ??
        _safeDate(appointment['createdDate']);
  }

  String _reservationStatusLabel(String status) {
    if (status == 'ALL') {
      final statusLabel = tr(context, 'status');
      return statusLabel == 'status' ? 'Status' : statusLabel;
    }
    if (status == 'ARRIVED') return 'Arrived';
    final key = 'status_${status.toLowerCase()}';
    final translated = tr(context, key);
    if (translated == key) {
      return status.replaceAll('_', ' ');
    }
    return translated;
  }

  void _clearReservationFilters() {
    setState(() {
      _reservationStatusFilter = 'ALL';
      _reservationSortField = 'APPOINTMENT_DATE';
      _reservationSortAscending = true;
    });
  }

  List<dynamic> _applyReservationFiltersAndSort(List<dynamic> source) {
    final filtered = source.where((appointment) {
      final status = (appointment['status'] ?? '').toString().toUpperCase();
      if (_reservationStatusFilter != 'ALL' &&
          status != _reservationStatusFilter) {
        return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      DateTime getSortDate(dynamic appointment) {
        if (_reservationSortField == 'CREATED_AT') {
          return _reservationCreatedDate(appointment) ??
              _safeDate(appointment['appointmentDate']) ??
              DateTime.fromMillisecondsSinceEpoch(0);
        }
        return _safeDate(appointment['appointmentDate']) ??
            _reservationCreatedDate(appointment) ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }

      final compare = getSortDate(a).compareTo(getSortDate(b));
      if (compare != 0) {
        return _reservationSortAscending ? compare : -compare;
      }
      final statusA = (a['status'] ?? '').toString();
      final statusB = (b['status'] ?? '').toString();
      return statusA.compareTo(statusB);
    });

    return filtered;
  }

  int? _appointmentId(dynamic appointment) {
    final raw = appointment is Map ? appointment['id'] : null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  void _maybeOpenFocusedAppointment(List<dynamic> appointments) {
    if (_hasOpenedFocusedAppointment || !mounted) return;
    final focusId = widget.focusAppointmentId;
    if (focusId == null) return;

    dynamic target;
    for (final apt in appointments) {
      if (_appointmentId(apt) == focusId) {
        target = apt;
        break;
      }
    }
    if (target == null) return;

    _hasOpenedFocusedAppointment = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showAppointmentDetailsBottomSheet(
        context: context,
        appointment: Map<String, dynamic>.from(target as Map),
      );
    });
  }

  Widget _buildReservationsFilters({
    required int totalCount,
    required int shownCount,
  }) {
    final hasActiveFilters = _reservationStatusFilter != 'ALL' ||
        _reservationSortField != 'APPOINTMENT_DATE' ||
        !_reservationSortAscending;

    Widget chip({
      required Widget child,
      bool active = false,
      EdgeInsetsGeometry padding =
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    }) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: active ? AppColors.primaryBlue.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primaryBlue : Colors.grey.shade300,
            width: active ? 1.5 : 1,
          ),
        ),
        child: child,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      setState(() => _reservationStatusFilter = value),
                  itemBuilder: (context) => [
                    'ALL',
                    'PENDING',
                    'CONFIRMED',
                    'IN_PROGRESS',
                    'ARRIVED',
                    'COMPLETED',
                    'CANCELLED',
                    'DECLINED',
                  ]
                      .map(
                        (status) => PopupMenuItem<String>(
                          value: status,
                          child: Text(_reservationStatusLabel(status)),
                        ),
                      )
                      .toList(),
                  child: chip(
                    active: _reservationStatusFilter != 'ALL',
                    child: Row(
                      children: [
                        Text(
                          _reservationStatusLabel(_reservationStatusFilter),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      setState(() => _reservationSortField = value),
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'APPOINTMENT_DATE',
                      child: Text('Date RDV'),
                    ),
                    PopupMenuItem<String>(
                      value: 'CREATED_AT',
                      child: Text('Date creation'),
                    ),
                  ],
                  child: chip(
                    active: _reservationSortField != 'APPOINTMENT_DATE',
                    child: Row(
                      children: [
                        Text(
                          _reservationSortField == 'CREATED_AT'
                              ? 'Date creation'
                              : 'Date RDV',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(
                    () => _reservationSortAscending = !_reservationSortAscending,
                  ),
                  child: chip(
                    active: !_reservationSortAscending,
                    child: Row(
                      children: [
                        Icon(
                          _reservationSortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 14,
                          color: AppColors.textDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _reservationSortAscending ? 'Asc' : 'Desc',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _clearReservationFilters,
                    child: chip(
                      child: const Row(
                        children: [
                          Icon(Icons.close, size: 14, color: Colors.red),
                          SizedBox(width: 4),
                          Text(
                            'Clear',
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Affichage: $shownCount / $totalCount',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // TABS BUILDERS
  // ============================================

  Widget _buildServicesTab() {
    final services = (_salonData?['services'] as List<dynamic>?) ?? [];

    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cut_outlined, size: 70, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              tr(context, 'no_service_yet'),
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
            if (widget.isPatron) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to Settings and select the active tab automatically
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SalonScreenUnifiee(
                        initialTabIndex: 1, // Services tab
                        openAddForm: true,
                        salonId: widget.salonId,
                        isAdminPeek: widget.isAdminPeek,
                      ),
                    ),
                  ).then((_) => _fetchSalonData());
                },
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: Text(
                  tr(context, 'add_new_service'),
                  style: const TextStyle(
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

        return GestureDetector(
          onTap: () => _showServiceDialog(context, service),
          child: Container(
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
                          CloudinaryUtils.getOptimizedUrl(
                                imageUrl,
                                width: 300,
                              ) ??
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
      future: (widget.isAdminPeek && widget.salonId != null)
          ? AppointmentService.getAppointmentsForSalonId(widget.salonId!)
          : AppointmentService.getSalonAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              tr(context, 'error_msg', args: [snapshot.error.toString()]),
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final allAppointments = List<dynamic>.from(snapshot.data ?? []);
        final appointments = _applyReservationFiltersAndSort(allAppointments);
        _maybeOpenFocusedAppointment(allAppointments);

        if (allAppointments.isEmpty) {
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
                Text(
                  tr(context, 'no_appointments_today'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildReservationsFilters(
              totalCount: allAppointments.length,
              shownCount: appointments.length,
            ),
            if (appointments.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_alt_off,
                        size: 56,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Ma fama hata resultat bel filtres',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
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
                ? DateFormat(
                    'dd/MM/yyyy - HH:mm',
                  ).format(DateTime.parse(aptDate).toLocal())
                : '';

            String countdownText = "";
            bool isTimeReached = false;
            if (aptDate != null &&
                (status == 'CONFIRMED' ||
                    status == 'PENDING' ||
                    status == 'IN_PROGRESS')) {
              DateTime targetDate;
              if (status == 'IN_PROGRESS' && apt['estimatedEndTime'] != null) {
                targetDate = DateTime.parse(apt['estimatedEndTime']).toLocal();
              } else {
                targetDate = DateTime.parse(aptDate).toLocal();
              }

              final now = DateTime.now();
              final difference = targetDate.difference(now);

              if (difference.isNegative || difference.inSeconds <= 0) {
                isTimeReached = true;
                countdownText = status == 'IN_PROGRESS'
                    ? tr(context, 'time_up')
                    : tr(context, 'time_passed');
              } else if (difference.inHours == 1 &&
                  difference.inMinutes % 60 == 0 &&
                  status != 'IN_PROGRESS') {
                countdownText = tr(context, '1h_remaining');
              } else if (difference.inMinutes == 15 &&
                  status != 'IN_PROGRESS') {
                countdownText = tr(context, '15m_remaining');
              } else if (difference.inHours > 0) {
                countdownText = tr(
                  context,
                  'time_remaining_hours_min',
                  args: [
                    difference.inHours.toString(),
                    (difference.inMinutes % 60).toString(),
                  ],
                );
              } else if (difference.inMinutes > 0) {
                countdownText = tr(
                  context,
                  'time_remaining_min',
                  args: [difference.inMinutes.toString()],
                );
              } else {
                countdownText = tr(
                  context,
                  'time_remaining_sec',
                  args: [difference.inSeconds.toString()],
                );
              }
            }

            return GestureDetector(
              onTap: () {
                showAppointmentDetailsBottomSheet(
                  context: context,
                  appointment: apt,
                );
              },
              child: Card(
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: status == 'PENDING'
                                      ? Colors.orange.withValues(alpha: 0.1)
                                      : status == 'CONFIRMED'
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : status == 'IN_PROGRESS'
                                      ? AppColors.primaryBlue.withValues(
                                          alpha: 0.1,
                                        )
                                      : status == 'COMPLETED'
                                      ? Colors.blueGrey.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tr(context, 'status_${status.toLowerCase()}'),
                                  style: TextStyle(
                                    color: status == 'PENDING'
                                        ? Colors.orange
                                        : status == 'CONFIRMED'
                                        ? Colors.green
                                        : status == 'IN_PROGRESS'
                                        ? AppColors.primaryBlue
                                        : status == 'COMPLETED'
                                        ? Colors.blueGrey
                                        : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (countdownText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    countdownText,
                                    style: const TextStyle(
                                      color: AppColors.actionRed,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (clientPhone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          "T\u{00E9}l: $clientPhone",
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
                                onPressed: () =>
                                    _updateAptStatus(apt['id'], 'DECLINED'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  tr(context, 'decline_btn'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _updateAptStatus(apt['id'], 'CONFIRMED'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.successGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  tr(context, 'accept_btn'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (status == 'CONFIRMED' && isTimeReached) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showNoShowDialog(apt['id']),
                                icon: const Icon(Icons.person_off, size: 18),
                                label: Text(
                                  tr(context, 'no_show_btn'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _updateAptStatus(apt['id'], 'IN_PROGRESS'),
                                icon: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: Text(
                                  tr(context, 'start_service_btn'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (status == 'IN_PROGRESS' && isTimeReached) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Logic for "Mezel 15 min" could be a separate status or just a local reminder
                                  toastification.show(
                                    context: context,
                                    type: ToastificationType.info,
                                    title: Text(
                                      tr(context, 'reminder_15m_set'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.timer, size: 18),
                                label: Text(tr(context, '15m_remaining')),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _updateAptStatus(apt['id'], 'COMPLETED'),
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  tr(context, 'completed_btn'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.successGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
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
              ),
            );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSpecialistesTab() {
    final employees = (_salonData?['employees'] as List<dynamic>?) ?? [];
    final patron = _salonData?['patron'] as Map<String, dynamic>?;

    final specialists = employees
        .whereType<Map<String, dynamic>>()
        .map((emp) => Map<String, dynamic>.from(emp))
        .toList();

    final patronId = (patron?['id'] as num?)?.toInt();
    final patronAlreadyInList =
        patronId != null &&
        specialists.any((emp) => (emp['id'] as num?)?.toInt() == patronId);

    if (patron != null && !patronAlreadyInList) {
      specialists.insert(0, {
        'id': patronId,
        'name': (patron['name'] ?? 'Patron').toString(),
        'role': 'Patron',
        'bio': null,
        'imageUrl': patron['imageUrl'],
      });
    }

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
                      builder: (context) => SalonScreenUnifiee(
                        initialTabIndex: 2, // 2 is Equipe tab for Patron
                        openAddForm: true,
                        salonId: widget.salonId,
                        isAdminPeek: widget.isAdminPeek,
                      ),
                    ),
                  ).then((_) => _fetchSalonData());
                },
                icon: const Icon(
                  Icons.person_add_alt_1,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  tr(context, 'add_new_specialist'),
                  style: const TextStyle(
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
        if (specialists.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                tr(context, 'no_specialist_yet'),
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: specialists.length,
              itemBuilder: (context, index) {
                final emp = specialists[index];
                final name =
                    (emp['name'] ?? tr(context, 'specialist_role')) as String;
                final imageUrl = emp['imageUrl'] as String?;

                return GestureDetector(
                  onTap: () => _showSpecialistDialog(context, emp),
                  child: Container(
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
                          backgroundColor: AppColors.primaryBlue.withOpacity(
                            0.1,
                          ),
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
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAvisTab() {
    if (_salonData == null) {
      return Center(
        child: Text(
          tr(context, 'no_reviews_yet'),
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ReviewsTab(salonData: _salonData!);
  }

  Widget _buildWorkingTimesTab() {
    final List<dynamic>? workingHoursList = _salonData?['workingHours'];

    // Sort logic to match Lundi-Dimanche order based on integer dayOfWeek (1=Lundi, 7=Dimanche)
    final workingHours = workingHoursList != null
        ? List<dynamic>.from(workingHoursList)
        : [];
    workingHours.sort((a, b) {
      final dayA = a['dayOfWeek'] as int? ?? 0;
      final dayB = b['dayOfWeek'] as int? ?? 0;
      return dayA.compareTo(dayB);
    });

    return Column(
      children: [
        if (widget.isPatron)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SalonScreenUnifiee(
                        initialTabIndex: 3, // Working Hours tab
                        openAddForm: true,
                        salonId: widget.salonId,
                        isAdminPeek: widget.isAdminPeek,
                      ),
                    ),
                  ).then((_) => _fetchSalonData());
                },
                icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                label: Text(
                  tr(context, 'edit'),
                  style: const TextStyle(
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
        if (workingHours.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                '${tr(context, 'coming_soon', args: ['Working Hours'])}...',
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: workingHours.length,
              itemBuilder: (context, index) {
                final dayData = workingHours[index];
                final isDayOff = dayData['isDayOff'] ?? false;
                final isOpen = !isDayOff;
                final openTime = dayData['openTime'] ?? '09:00';
                final closeTime = dayData['closeTime'] ?? '18:00';

                // Map day number to localized string or fixed string
                final dayNumber = dayData['dayOfWeek'] as int? ?? 1;
                final days = [
                  'Lundi',
                  'Mardi',
                  'Mercredi',
                  'Jeudi',
                  'Vendredi',
                  'Samedi',
                  'Dimanche',
                ];
                final dayName = (dayNumber >= 1 && dayNumber <= 7)
                    ? days[dayNumber - 1]
                    : 'Inconnu';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOpen ? 'Ouvert' : 'Ferm\u{00E9}',
                              style: TextStyle(
                                color: isOpen ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isOpen) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      openTime,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.access_time,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '\u{00E0}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      closeTime,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.access_time,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
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
          ),
      ],
    );
  }

  void _showServiceDialog(BuildContext context, Map<String, dynamic> service) {
    final String name = service['name'] ?? 'Service';
    final double price = (service['price'] as num?)?.toDouble() ?? 0.0;
    final int duration = (service['durationMinutes'] as num?)?.toInt() ?? 0;
    final String? description = service['description'];
    final String? imageUrl = service['imageUrl'];

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    CloudinaryUtils.getOptimizedUrl(imageUrl, width: 400) ?? '',
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        SizedBox(height: 120, child: _servicePlaceholder()),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: SizedBox(height: 120, child: _servicePlaceholder()),
                ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
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
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 18,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "$duration min",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (widget.isPatron || widget.isAdminPeek)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SalonScreenUnifiee(
                                  initialTabIndex: 1, // Services tab
                                  salonId: widget.salonId,
                                  isAdminPeek: widget.isAdminPeek,
                                  initialEditService: service,
                                ),
                              ),
                            ).then((_) => _fetchSalonData());
                          },
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: Text(
                            tr(context, 'edit'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Fermer'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSpecialistDialog(BuildContext context, Map<String, dynamic> emp) {
    final String name =
        (emp['name'] ?? tr(context, 'specialist_role')) as String;
    final String role =
        (emp['role'] ?? tr(context, 'specialist_role')) as String;
    final String? bio = emp['bio'] as String?;
    final String? imageUrl = emp['imageUrl'] as String?;
    final String? phone = emp['phoneNumber'] as String?;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              role,
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (phone != null && phone.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withOpacity(
                                      0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.phone,
                                    color: AppColors.primaryBlue,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    phone,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (bio != null && bio.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              bio,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                      backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                          ? NetworkImage(
                              CloudinaryUtils.getOptimizedUrl(
                                    imageUrl,
                                    width: 300,
                                  ) ??
                                  '',
                            )
                          : null,
                      child: (imageUrl == null || imageUrl.isEmpty)
                          ? Text(
                              name.isNotEmpty
                                  ? name.substring(0, 1).toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (widget.isPatron || widget.isAdminPeek)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SalonScreenUnifiee(
                              initialTabIndex: 2, // Equipe tab
                              salonId: widget.salonId,
                              isAdminPeek: widget.isAdminPeek,
                              initialEditEmployee: emp,
                            ),
                          ),
                        ).then((_) => _fetchSalonData());
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: Text(
                        tr(context, 'edit'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Fermer'),
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


