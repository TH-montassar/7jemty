import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/features/client_space/salon_profile/presentation/widgets/salon_info_section.dart';
import 'package:hjamty/features/client_space/salon_profile/presentation/widgets/sticky_tab_bar_delegate.dart';
import 'package:hjamty/features/client_space/salon_profile/presentation/widgets/services_tab.dart';
import 'package:hjamty/features/client_space/salon_profile/presentation/widgets/products_tab.dart';
import 'package:hjamty/features/client_space/salon_profile/presentation/widgets/portfolio_tab.dart';
import 'package:hjamty/features/client_space/salon_profile/presentation/widgets/reviews_tab.dart';
import 'package:hjamty/features/client_space/salon_profile/data/salon_service.dart';
import 'package:hjamty/features/client_space/appointments/presentation/pages/booking_flow_screen.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/features/client_space/salon_profile/presentation/widgets/about_tab.dart';
import 'package:toastification/toastification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hjamty/features/auth/signIn.dart';

class SalonProfilePage extends StatefulWidget {
  final int salonId;

  const SalonProfilePage({super.key, required this.salonId});

  @override
  State<SalonProfilePage> createState() => _SalonProfilePageState();
}

class _SalonProfilePageState extends State<SalonProfilePage> {
  late Future<Map<String, dynamic>> _salonFuture;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;
  bool _isClient = true; // Default to true until checked

  @override
  void initState() {
    super.initState();
    _salonFuture = SalonService.getSalonById(widget.salonId);
    _checkFavorite();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    if (mounted) {
      setState(() {
        _isClient = role == 'CLIENT' || role == null;
      });
    }
  }

  Future<void> _checkFavorite() async {
    try {
      final isFav = await SalonService.checkFavoriteStatus(widget.salonId);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    } catch (e) {
      // Ignore initial error
    }
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
        );
      }
      return;
    }

    setState(() {
      _isFavorite = !_isFavorite;
      _isLoadingFavorite = true;
    });

    try {
      final isNowFavorite = await SalonService.toggleFavoriteSalon(
        widget.salonId,
      );
      if (!mounted) return;

      setState(() {
        _isFavorite = isNowFavorite;
        _isLoadingFavorite = false;
      });
    } catch (e) {
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
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _salonFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.actionRed,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr(
                        context,
                        'error_msg',
                        args: [snapshot.error.toString()],
                      ),
                      style: const TextStyle(color: AppColors.actionRed),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(tr(context, 'go_back')),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(child: Text(tr(context, 'no_data_found')));
          }

          final salonData = snapshot.data!;

          return DefaultTabController(
            length: 5,
            child: NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  // 1. Header Image & AppBar
                  SliverAppBar(
                    expandedHeight: 250.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.primaryBlue,
                    elevation: 0,
                    leading: Container(
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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    actions: [
                      if (_isClient) ...[
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
                            onPressed: () async {
                              final name = salonData['name'] ?? 'Salon';
                              final address = salonData['address'] ?? '';
                              final rating =
                                  salonData['rating']?.toString() ?? '?';
                              final message =
                                  '🏪 $name\n⭐ $rating / 5\n📍 $address\n\nDécouvre ce salon sur Hjamty!';
                              try {
                                await Share.share(message);
                              } catch (e) {
                                debugPrint('Share error: $e');
                              }
                            },
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
                                  onPressed: _toggleFavorite,
                                ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            salonData['image'] ??
                                'https://images.unsplash.com/photo-1503951914875-452162b7f30a?auto=format&fit=crop&w=800&q=80',
                            fit: BoxFit.cover,
                          ),
                          // Overlay أكحل خفيف
                          Container(color: Colors.black.withAlpha(77)),
                        ],
                      ),
                    ),
                  ),

                  // 2. Infos Salon (Nom, Adresse, Rating, Status)
                  SliverToBoxAdapter(
                    child: SalonInfoSection(salonData: salonData),
                  ),

                  // 3. Sticky Tabs
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: StickyTabBarDelegate(
                      TabBar(
                        labelColor: AppColors.primaryBlue,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppColors.primaryBlue,
                        indicatorWeight: 3,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        tabs: [
                          Tab(text: tr(context, 'about_tab')),
                          Tab(text: tr(context, 'tab_services')),
                          Tab(text: tr(context, 'products')),
                          Tab(text: tr(context, 'portfolio')),
                          Tab(text: tr(context, 'tab_reviews')),
                        ],
                      ),
                    ),
                  ),
                ];
              },

              // 4. محتوى الـ Tabs
              body: TabBarView(
                children: [
                  AboutTab(salonData: salonData),
                  ServicesTab(salonData: salonData),
                  ProductsTab(),
                  PortfolioTab(),
                  ReviewsTab(),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingFlowScreen(salonId: widget.salonId),
            ),
          );
        },
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.calendar_month, color: Colors.white),
        label: Text(
          tr(context, 'book_appointment'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
