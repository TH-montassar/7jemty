import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../client_space/profile/presentation/pages/profile_page.dart';
import '../../../../../core/widgets/notification_bell.dart';
import 'employee_agenda_page.dart';

class EmployeeMainLayout extends StatefulWidget {
  const EmployeeMainLayout({super.key});

  @override
  State<EmployeeMainLayout> createState() => _EmployeeMainLayoutState();
}

class _EmployeeMainLayoutState extends State<EmployeeMainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [const EmployeeAgendaPage(), const ProfilePage()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.cut, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 8),
            const Text(
              "7jemty",
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
              radius: 15,
              child: const NotificationBell(
                iconColor: AppColors.primaryBlue,
                badgeColor: AppColors.actionRed,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
