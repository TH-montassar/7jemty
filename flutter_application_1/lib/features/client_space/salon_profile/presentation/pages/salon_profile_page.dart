import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../widgets/salon_info_section.dart';
import '../widgets/sticky_tab_bar_delegate.dart';
import '../widgets/services_tab.dart';
import '../widgets/products_tab.dart';
import '../widgets/portfolio_tab.dart';
import '../widgets/reviews_tab.dart';
import '../../../../../services/salon_service.dart';
import '../../../appointments/presentation/pages/booking_flow_screen.dart';

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
                      "Erreur: ${snapshot.error}",
                      style: const TextStyle(color: AppColors.actionRed),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Retour"),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("Aucune donnée trouvée."));
          }

          final salonData = snapshot.data!;

          return DefaultTabController(
            length: 4,
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
                          Container(color: Colors.black.withOpacity(0.3)),
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
                        tabs: const [
                          Tab(text: "Services"),
                          Tab(text: "Produits"),
                          Tab(text: "Portfolio"),
                          Tab(text: "Avis"),
                        ],
                      ),
                    ),
                  ),
                ];
              },

              // 4. محتوى الـ Tabs
              body: const TabBarView(
                children: [
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
        label: const Text(
          "Prendre Rendez-vous",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
