import 'package:hjamty/core/localization/translation_service.dart';
import 'package:flutter/material.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'admin_dashboard')),
        backgroundColor: Colors.redAccent,
      ),
      body: const Center(
        child: Text(
          'Bienvenue Admin!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
