import 'package:flutter/material.dart';
import 'package:hjamty/core/widgets/shared_widgets.dart'; // Import CircularStat

class SubscriptionCard extends StatelessWidget {
  final VoidCallback onPointsTap;

  const SubscriptionCard({super.key, required this.onPointsTap});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -45),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Statut Abonnement",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Text(
                            "PREMIUM",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Renouveler",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(height: 1, color: Color(0xFFEEEEEE)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CircularStat(
                    value: "1200",
                    label: "Points",
                    color: Colors.blue,
                    percent: 0.75,
                    onTap: onPointsTap,
                  ),
                  const CircularStat(
                    value: "350",
                    label: "RDV",
                    color: Colors.orange,
                    percent: 0.50,
                  ),
                  // Houni ken el ghalta (zedna color:)
                  const CircularStat(
                    value: "125",
                    label: "Avis",
                    color: Colors.teal,
                    percent: 0.90,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
