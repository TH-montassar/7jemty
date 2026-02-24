import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  int _selectedCategoryIndex = 0;
  
  final List<String> _categories = ["Tous", "Cheveux", "Barbe", "Visage", "Accessoires"];

  // Mock Data mta3 les produits
  final List<Map<String, dynamic>> _products = [
    {
      'name': 'Cire Coiffante Matte',
      'brand': 'Barber King',
      'price': '25 DT',
      'image': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=500&q=80',
    },
    {
      'name': 'Huile à Barbe Bio',
      'brand': 'The Classic',
      'price': '35 DT',
      'image': 'https://images.unsplash.com/photo-1621607512214-68297480165e?auto=format&fit=crop&w=500&q=80',
    },
    {
      'name': 'Shampooing Anti-Chute',
      'brand': 'Salon El Baze',
      'price': '40 DT',
      'image': 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?auto=format&fit=crop&w=500&q=80',
    },
    {
      'name': 'Peigne en Bois',
      'brand': 'Barber Shop',
      'price': '15 DT',
      'image': 'https://images.unsplash.com/photo-1622288432450-277d0fce5b15?auto=format&fit=crop&w=500&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Na7iwha 5aterha fel BottomNav
        title: const Text("Boutique", style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('2'),
              child: Icon(Icons.shopping_cart_outlined, color: AppColors.textDark),
            ),
            onPressed: () {
              // TODO: Aller au Panier
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
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Chercher un produit...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // 2. Catégories (Horizontal List)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _categories.length,
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
                      _categories[index],
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

          // 3. Grille des produits (Grid View)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,           // Zouz produits fel ligne
                crossAxisSpacing: 15,        // Espace bel 3ardh
                mainAxisSpacing: 15,         // Espace bel toul
                childAspectRatio: 0.75,      // Formaat mta3 l'karta (Toul akber mel 3ardh)
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final p = _products[index];
                return _buildProductCard(p);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Karta mta3 Produit wa7ed ---
  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Taswira mta3 l'produit
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                product['image'],
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Les informations (Esem, Soum, Bouton +)
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
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}