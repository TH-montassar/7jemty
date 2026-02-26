import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/translation_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // 💡 Mock Data: البرودويات اللّي في السلة
  final List<Map<String, dynamic>> _cartItems = [
    {
      'name': 'Cire Coiffante Matte',
      'brand': 'Barber King',
      'price': 25,
      'quantity': 2,
      'image': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=500&q=80',
    },
    {
      'name': 'Huile à Barbe Bio',
      'brand': 'The Classic',
      'price': 35,
      'quantity': 1,
      'image': 'https://images.unsplash.com/photo-1621607512214-68297480165e?auto=format&fit=crop&w=500&q=80',
    }
  ];

  // دالة تحسب المجموع (Total)
  double get _totalPrice {
    return _cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(tr(context, 'cart_title'), style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
      ),
      body: _cartItems.isEmpty 
          ? _buildEmptyCart() 
          : _buildCartList(),
          
      // Bottom Bar متاع الخلاص (تظهر كان كي يبدا فما برودويات)
      bottomNavigationBar: _cartItems.isEmpty ? null : _buildCheckoutBar(),
    );
  }

  // ==========================================
  // 🧩 WIDGETS COMPONENTS
  // ==========================================

  // --- 1. ليستة البرودويات ---
  Widget _buildCartList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        final item = _cartItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Row(
            children: [
              // التصويرة
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(item['image'], width: 80, height: 80, fit: BoxFit.cover),
              ),
              const SizedBox(width: 15),
              
              // المعلومات
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'], 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(item['brand'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text("${item['price']} DT", style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              
              // التحكم في الكمية (+ / -) والفسخان
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => _cartItems.removeAt(index)); // فسخ البرودوي
                    },
                    child: const Icon(Icons.delete_outline, color: AppColors.actionRed, size: 22),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _buildQuantityBtn(Icons.remove, () {
                          if (item['quantity'] > 1) setState(() => item['quantity']--);
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        _buildQuantityBtn(Icons.add, () => setState(() => item['quantity']++)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- فلسة الكمية (+ / -) ---
  Widget _buildQuantityBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: AppColors.textDark),
      ),
    );
  }

  // --- 2. البار متاع الخلاص اللوطانية ---
  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tr(context, 'total_to_pay'), style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600)),
                Text("${_totalPrice.toInt()} DT", style: const TextStyle(color: AppColors.primaryBlue, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: تعدية الكوموند
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr(context, 'order_success')), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.actionRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: Text(tr(context, 'confirm_order'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. كي تبدا السلة فارغة ---
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 20),
          Text(tr(context, 'empty_cart'), style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              foregroundColor: AppColors.primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(tr(context, 'back_to_shop')),
          ),
        ],
      ),
    );
  }
}