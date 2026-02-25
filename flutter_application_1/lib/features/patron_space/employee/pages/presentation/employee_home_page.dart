import 'package:flutter/material.dart';

class EmployeeHomePage extends StatelessWidget {
  const EmployeeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Employé'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: const Center(
        child: Text(
          'Bienvenue Employé!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
