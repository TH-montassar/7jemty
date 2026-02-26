import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/translation_service.dart';
// 1. 🚀 عملنا Import لصفحة تفاصيل المنتج وصفحة السلة
import 'product_details_page.dart';
import 'cart_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  int _selectedCategoryIndex = 0;
  
  final List<Map<String, dynamic>> _products = [
    {'name': 'Cire Coiffante Matte', 'brand': 'Barber King', 'price': '25 DT', 'image': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=500&q=80'},
    {'name': 'Huile à Barbe Bio', 'brand': 'The Classic', 'price': '35 DT', 'image': 'https://images.unsplash.com/photo-1621607512214-68297480165e?auto=format&fit=crop&w=500&q=80'},
    {'name': 'Shampooing Anti-Chute', 'brand': 'Salon El Baze', 'price': '40 DT', 'image': 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?auto=format&fit=crop&w=500&q=80'},
    {'name': 'Peigne en Bois', 'brand': 'Barber Shop', 'price': '15 DT', 'image': 'https://images.unsplash.com/photo-1622288432450-277d0fce5b15?auto=format&fit=crop&w=500&q=80'},
  ];

  @override
  Widget build(BuildContext context) {
    final categories = [
      tr(context, 'category_all'),
      tr(context, 'category_hair'),
      tr(context, 'category_beard'),
      tr(context, 'category_face'),
      tr(context, 'category_accessories'),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, 
        title: Text(tr(context, 'shop'), style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('2'),
              child: Icon(Icons.shopping_cart_outlined, color: AppColors.textDark),
            ),
            onPressed: () {
              // 🚀 تهزك للسلة (Panier)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // 1. Barre de recherche
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: tr(context, 'search_product'),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // 2. Catégories
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                bool isSelected = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryBlue : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppColors.primaryBlue : Colors.grey.withValues(alpha: 0.2)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      categories[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // 3. Grille des produits
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.72,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(_products[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Karta mta3 Produit wa7ed ---
  Widget _buildProductCard(Map<String, dynamic> product) {
    // 🚀 2. حطينا الكارطة كاملة في GestureDetector باش تهزك للتفاصيل
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailsPage(product: product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                // 🚀 3. زدنا الـ Hero باش التصويرة تتأنما وقتلي تدخل للصفحة
                child: Hero(
                  tag: product['name'], 
                  child: Image.network(
                    product['image'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['brand'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    product['name'], 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(product['price'], style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                      // 🚀 4. حطينا الفلسة (+) في GestureDetector باش تزيد للسلة
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${product['name']} ${tr(context, 'added_to_cart')}"), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Color(0xFFFF3366), shape: BoxShape.circle), // اللون الوردي باش تخطف العين
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}