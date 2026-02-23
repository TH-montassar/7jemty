import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../widgets/salon_info_section.dart';
import '../widgets/sticky_tab_bar_delegate.dart';
import '../widgets/services_tab.dart';
import '../widgets/products_tab.dart';
import '../widgets/portfolio_tab.dart';
import '../widgets/reviews_tab.dart';

class SalonProfilePage extends StatefulWidget {
  const SalonProfilePage({super.key});

  @override
  State<SalonProfilePage> createState() => _SalonProfilePageState();
}

class _SalonProfilePageState extends State<SalonProfilePage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.bgColor,
        body: NestedScrollView(
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
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
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
              const SliverToBoxAdapter(
                child: SalonInfoSection(),
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
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
      ),
    );
  }
}