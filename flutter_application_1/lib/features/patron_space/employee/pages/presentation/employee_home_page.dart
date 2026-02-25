import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../services/appointment_service.dart';
import '../../../../../features/auth/signIn.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeHomePage extends StatefulWidget {
  const EmployeeHomePage({super.key});

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  // Mock data for appointments
  final List<Map<String, dynamic>> _appointments = [
    {
      "id":
          1, // We use small IDs to mock backend failure naturally if not exist
      "clientName": "Ahmed",
      "service": "Coupe + Barbe",
      "time": "14:30",
      "status": "PENDING",
    },
    {
      "id": 2,
      "clientName": "Yassine",
      "service": "Dégradé Américain",
      "time": "15:45",
      "status": "CONFIRMED",
    },
    {
      "id": 3,
      "clientName": "Karim",
      "service": "Coloration",
      "time": "17:00",
      "status": "COMPLETED",
    },
  ];

  Future<void> _updateStatus(
    int appointmentId,
    String newStatus,
    int index,
  ) async {
    try {
      toastification.show(
        context: context,
        type: ToastificationType.info,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 2),
        title: const Text(
          'Kaad ybadal...',
          style: TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.primaryBlue,
        backgroundColor: AppColors.primaryBlue,
      );

      // Call Backend API
      await AppointmentService.updateStatus(
        appointmentId: appointmentId,
        status: newStatus,
      );

      // On Success, Update UI Local State
      if (!mounted) return;
      setState(() {
        _appointments[index]['status'] = newStatus;
      });

      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        title: const Text(
          'Badalna l\'statut! 🎉',
          style: TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.successGreen,
        backgroundColor: AppColors.successGreen,
      );
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        title: const Text('Mochkla', style: TextStyle(color: Colors.white)),
        description: Text(
          e.toString(),
          style: const TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.actionRed,
        backgroundColor: AppColors.actionRed,
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Agenda mte3i",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.actionRed),
            onPressed: _logout,
          ),
        ],
      ),
      body: _appointments.isEmpty
          ? const Center(
              child: Text(
                "Ma famma hatta rendez-vous lyoum.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                final apt = _appointments[index];
                return _buildAppointmentCard(apt, index);
              },
            ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> apt, int index) {
    final isPending = apt['status'] == 'PENDING';
    final isConfirmed = apt['status'] == 'CONFIRMED';
    final isCompleted = apt['status'] == 'COMPLETED';
    final isDeclined = apt['status'] == 'DECLINED';

    Color statusColor = Colors.grey;
    String statusText = apt['status'];

    if (isPending) {
      statusColor = Colors.orange;
      statusText = "Yestanna";
    } else if (isConfirmed) {
      statusColor = AppColors.primaryBlue;
      statusText = "M'akd";
    } else if (isCompleted) {
      statusColor = AppColors.successGreen;
      statusText = "Kmal";
    } else if (isDeclined) {
      statusColor = AppColors.actionRed;
      statusText = "Morfodh";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                apt['time'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            apt['clientName'],
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            apt['service'],
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),

          if (isPending || isConfirmed) const SizedBox(height: 16),

          if (isPending) // Accept or Decline buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _updateStatus(apt['id'], 'DECLINED', index),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.actionRed,
                      side: const BorderSide(color: AppColors.actionRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Orfodh"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _updateStatus(apt['id'], 'CONFIRMED', index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Ikbel",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

          if (isConfirmed) // Has ended?
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus(apt['id'], 'COMPLETED', index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                  "Kmalt l'hjema ?",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
