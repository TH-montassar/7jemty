import 'package:flutter/material.dart';
import 'package:hjamty/core/localization/translation_service.dart';

class ManageUserAlertsPage extends StatelessWidget {
  const ManageUserAlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'manage_user_alerts')),
      ),
      body: Center(
        child: Text(
          tr(context, 'no_user_alerts'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
