import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';

class AnimatedQuickAccessButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const AnimatedQuickAccessButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<AnimatedQuickAccessButton> createState() =>
      _AnimatedQuickAccessButtonState();
}

class _AnimatedQuickAccessButtonState extends State<AnimatedQuickAccessButton> {
  bool _isPressed = false;

  void _handleTap() async {
    setState(() {
      _isPressed = true; // 1. وقت النزلة: يولي أزرق
    });

    // نستناو نص ثانية (وقت الـ Animation)
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isPressed = false; // 2. يرجع للون الأصلي (الروز)
      });
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- هوني قلبنا الألوان ---

    // 1. الحدود (Border):
    // كان نازل (_isPressed) -> أزرق (Blue)
    // كان مرتاح -> روز (PinkAccent)
    final borderColor = _isPressed ? Colors.blue : AppColors.actionRed;

    // 2. الأيقونة (Icon):
    // كان نازل -> أزرق
    // كان مرتاح -> روز
    final iconColor = _isPressed ? Colors.blue : AppColors.actionRed;

    // 3. الكتيبة (Text):
    // كان نازل -> أزرق
    // كان مرتاح -> أكحل (أو روز كان تحب تبدلها colors.pinkAccent)
    final textColor = _isPressed ? Colors.blue : Colors.black;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // عرض الخط: كي تنزل يولي خشين شوية (2)
          border: Border.all(color: borderColor, width: _isPressed ? 2 : 1),

          // --- الـ Gradient (الأنيميشن) ---
          gradient: RadialGradient(
            center: Alignment.center,
            // كي تنزل (Blue Effect) يكبر الـ Radius
            radius: _isPressed ? 2.5 : 0.0,
            colors: [
              Colors.blue.withOpacity(0.2), // لون الـ Effect (أزرق)
              AppColors.actionRed.withOpacity(
                0.05,
              ), // لون الخلفية العادية (روز فاتح)
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Column(
          children: [
            Icon(widget.icon, color: iconColor, size: 28),
            const SizedBox(height: 12),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
