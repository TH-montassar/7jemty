import 'package:flutter/material.dart';

// 1. Circular Stat Widget
class CircularStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final double percent;
  final VoidCallback? onTap;

  const CircularStat({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    required this.percent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 6,
                  color: Colors.grey[100],
                ),
              ),
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 6,
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// 2. Settings Tile Widget
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool isDestructive;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap ?? () {},
    );
  }
}
