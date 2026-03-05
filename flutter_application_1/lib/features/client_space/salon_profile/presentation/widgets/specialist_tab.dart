import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';

class SpecialistTab extends StatelessWidget {
  const SpecialistTab({super.key});

  @override
  Widget build(BuildContext context) {
    final specialists = [
      {
        'name': 'Malek Ben Ali',
        'role': 'Coiffeur Senior',
        'bio': 'Spécialiste en dégradé et coupe moderne. 8 ans d\'expérience.',
        'imageUrl': null,
      },
      {
        'name': 'Yassine Trabelsi',
        'role': 'Barbier',
        'bio': 'Expert en taille de barbe et soins du visage.',
        'imageUrl': null,
      },
      {
        'name': 'Khalil Mansour',
        'role': 'Coiffeur',
        'bio': 'Passionné par les coupes classiques et les styles rétro.',
        'imageUrl': null,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: specialists.length,
      itemBuilder: (context, index) {
        final s = specialists[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
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
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                backgroundImage: s['imageUrl'] != null
                    ? NetworkImage(s['imageUrl']!)
                    : null,
                child: s['imageUrl'] == null
                    ? Text(
                        s['name']!.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 15),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['name']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s['role']!,
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s['bio']!,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
