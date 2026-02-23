import 'package:flutter/material.dart';

class SalonPage extends StatelessWidget {
  const SalonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront, size: 80, color: Colors.blue),
          SizedBox(height: 20),
          Text(
            "Mon Salon",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            "Houni tji l page mta3 ssalon yess maama",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
