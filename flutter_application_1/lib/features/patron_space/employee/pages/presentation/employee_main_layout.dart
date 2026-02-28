import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../client_space/profile/presentation/pages/profile_page.dart';
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
