import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/translation_service.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int quantity = 1; // الكونتيتي اللّي باش يشريها

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: CustomScrollView(
        slivers: [
          // 1. Header (التصويرة الكبيرة)
          SliverAppBar(
            expandedHeight: 350.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.product['name'], // 💡 باش التصويرة تطير طيران للصفحة هذي
                child: Image.network(
                  widget.product['image'],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 2. المحتوى (الاسم، السوم، والـ Description)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: AppColors.bgColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product['name'],
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 5),
                            Text(tr(context, 'brand_professional'), style: const TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      ),
                      Text(
                        widget.product['price'],
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Description
                  Text(tr(context, 'description'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 10),
                  Text(
                    tr(context, 'product_description_text'),
                    style: TextStyle(color: Colors.grey, height: 1.5),
                  ),
                  const SizedBox(height: 25),

                // Conseils d'utilisation
        Text(tr(context, 'usage_tips'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // 👈 هذي تريڨل الأيقونة
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.primaryBlue, size: 20),
            SizedBox(width: 10),
            Expanded( // 🚀 هذي اللّي باش تنحي الـ Overflow
              child: Text(
                tr(context, 'usage_tip_line'), 
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 100), // مساحة Bottom Bar
                ],
              ),
            ),
          ),
        ],
      ),

      // 3. Bottom Bar (الكونتيتي وبوتون الشراء)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Sélecteur de quantité
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: AppColors.textDark),
                      onPressed: () {
                        if (quantity > 1) setState(() => quantity--);
                      },
                    ),
                    Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppColors.textDark),
                      onPressed: () => setState(() => quantity++),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              
              // Bouton Ajouter
              Expanded(
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr(context, 'added_to_cart_success')), backgroundColor: Colors.green),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3366), // اللون الوردي اللّي استعملتو إنت
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: Text(tr(context, 'add_to_cart'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}