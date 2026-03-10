import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/core/widgets/shared_calendar_view.dart';
import 'package:hjamty/features/client_space/appointments/data/appointment_service.dart';

class EmployeeCalendarPage extends StatefulWidget {
  const EmployeeCalendarPage({super.key});

  @override
  State<EmployeeCalendarPage> createState() => _EmployeeCalendarPageState();
}

class _EmployeeCalendarPageState extends State<EmployeeCalendarPage> {
  bool _isLoading = true;
  List<dynamic> _appointments = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      final data = await AppointmentService.getEmployeeAppointments();
      if (mounted) {
        setState(() {
          _appointments = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(tr(context, 'my_calendar')),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : SharedCalendarView(
              appointments: _appointments,
              isEmployeeView: true,
              onRefresh: _fetchAppointments,
            ),
    );
  }
}
