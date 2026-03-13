import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';

class TafasilTab extends StatelessWidget {
  const TafasilTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // --- Aal Salon ---
        _sectionTitle("Aal Salon"),
        const SizedBox(height: 10),
        _infoCard(
          child: const Text(
            "Salon spécialisé dans les coupes modernes et classiques. "
            "Nous offrons une expérience unique avec des coiffeurs professionnels.",
            style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.6),
          ),
        ),
        const SizedBox(height: 20),

        // --- Contact ---
        _sectionTitle("Contact"),
        const SizedBox(height: 10),
        _infoCard(
          child: Column(
            children: [
              _contactRow(
                Icons.phone,
                "+216 XX XXX XXX",
                AppColors.primaryBlue,
              ),
              const Divider(height: 20),
              _contactRow(Icons.location_on, "Adresse disponible fil fiche", Colors.red),
              const Divider(height: 20),
              _contactRow(
                Icons.access_time,
                "Lun - Sam: 08:00 - 20:00",
                Colors.green,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- Spécialité ---
        _sectionTitle("Spécialité"),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _ChipItem(label: "Coupe Homme"),
            _ChipItem(label: "Barbe"),
            _ChipItem(label: "Dégradé"),
            _ChipItem(label: "Soin Visage"),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _infoCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _contactRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        ),
      ],
    );
  }
}

class _ChipItem extends StatelessWidget {
  final String label;
  const _ChipItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
