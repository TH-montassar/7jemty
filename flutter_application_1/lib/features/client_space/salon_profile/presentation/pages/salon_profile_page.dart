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

class SalonProfilePage extends StatefulWidget {
  final int salonId;

  const SalonProfilePage({super.key, required this.salonId});

  @override
  State<SalonProfilePage> createState() => _SalonProfilePageState();
}

class _SalonProfilePageState extends State<SalonProfilePage> {
  late Future<Map<String, dynamic>> _salonFuture;

  @override
  void initState() {
    super.initState();
    _salonFuture = SalonService.getSalonById(widget.salonId);
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
                    leading: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
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
                  ServicesTab(),
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
