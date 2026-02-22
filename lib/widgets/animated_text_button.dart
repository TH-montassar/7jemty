import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AnimatedTextButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final double borderRadius; // بش نتحكمو في التدويرة
  final double? width; // بش نتحكمو في العرض (kima Voir tout)

  const AnimatedTextButton({
    super.key,
    required this.text,
    required this.onTap,
    this.borderRadius = 8.0, // القيمة الافتراضية (للـ Voir RDV)
    this.width,
  });

  @override
  State<AnimatedTextButton> createState() => _AnimatedTextButtonState();
}

class _AnimatedTextButtonState extends State<AnimatedTextButton> {
  bool _isPressed = false;

  void _handleTap() async {
    setState(() {
      _isPressed = true; // 1. يولي أزرق
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isPressed = false; // 2. يرجع روز
      });
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    // الألوان: روز في العادي، وأزرق كي تنزل
    final color = _isPressed ? Colors.blue : AppColors.actionRed;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        width: widget.width, // كان عطيناه عرض يستعملو
        // Padding داخلي بش الكتيبة تتنفس
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: color, width: _isPressed ? 2 : 1),

          // نفس الـ Gradient متاع البوتونات لخرين
          gradient: RadialGradient(
            center: Alignment.center,
            radius: _isPressed ? 2.5 : 0.0,
            colors: [
              Colors.blue.withOpacity(0.2),
              AppColors.actionRed.withOpacity(0.05),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Text(
          widget.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
