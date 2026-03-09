import 'package:flutter/material.dart';
import 'main_page.dart';

/// NOTE: This screen is no longer used since the new CreateSalonScreen
/// handles all 3 steps of onboarding (Identity, Presentation, Photo).
/// If any old code still routes here, it will just skip to the Dashboard.
class AddSalonInfoScreen extends StatefulWidget {
  const AddSalonInfoScreen({super.key});

  @override
  State<AddSalonInfoScreen> createState() => _AddSalonInfoScreenState();
}

class _AddSalonInfoScreenState extends State<AddSalonInfoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MainPage(initialIndex: 2),
        ),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
