import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/core/widgets/shared_calendar_view.dart';
import 'package:hjamty/features/client_space/appointments/data/appointment_service.dart';
import 'package:hjamty/features/client_space/salon_profile/data/salon_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  bool _isLoading = true;
  List<dynamic> _allAppointments = [];
  List<dynamic> _filteredAppointments = [];
  List<dynamic> _specialists = [];
  int? _selectedSpecialistId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch both appointments and salon details concurrently
      final responses = await Future.wait([
        AppointmentService.getSalonAppointments(),
        SalonService.getMySalon(),
      ]);

      final List<dynamic> appointments = responses[0] as List<dynamic>;
      final Map<String, dynamic> salonData = responses[1] as Map<String, dynamic>;
      
      final employees = List<dynamic>.from((salonData['employees'] as List<dynamic>?) ?? []);
      final patron = salonData['patron'];

      // Add Patron to the beginning of the list if available
      if (patron != null) {
        final Map<String, dynamic> patronMap = Map<String, dynamic>.from(patron);
        patronMap['isPatron'] = true;
        employees.insert(0, patronMap);
      }

      if (mounted) {
        setState(() {
          _allAppointments = appointments;
          _specialists = employees;
          _isLoading = false;
          _filterAppointments();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterAppointments() {
    if (_selectedSpecialistId == null) {
      _filteredAppointments = _allAppointments;
    } else {
      _filteredAppointments = _allAppointments.where((apt) {
        final barberId = apt['barberId'];
        
        // Handling checking if the appointment belongs to the Patron
        if (barberId == _selectedSpecialistId) {
            return true;
        }
        
        // Fallback for patron specifically if the targetType is PATRON and the selected ID represents the patron. 
        // In the payload the patron's actual ID is the selectedSpecialistId. If the barberId is null but the target type is PATRON,
        // it may mean the appointment is for the patron's salon level. 
        // Let's rely primarily on barberId matching the selectedSpecialistId.
        return barberId == _selectedSpecialistId;
      }).toList();
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
          : Column(
              children: [
                if (_specialists.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          isExpanded: true,
                          value: _selectedSpecialistId,
                          hint: Text(tr(context, 'all_specialists')),
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(tr(context, 'all_specialists')),
                            ),
                            ..._specialists.map((specialist) {
                              final name = specialist['name'] ?? specialist['user']?['name'] ?? 'Spécialiste';
                              final String displayName = specialist['isPatron'] == true 
                                  ? tr(context, 'moi_patron') // custom key we will add
                                  : name.toString();
                              return DropdownMenuItem<int?>(
                                value: specialist['id'] as int?,
                                child: Text(displayName),
                              );
                            }),
                          ],
                          onChanged: (int? newValue) {
                            setState(() {
                              _selectedSpecialistId = newValue;
                              _filterAppointments();
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: SharedCalendarView(
                    appointments: _filteredAppointments,
                    isEmployeeView: false,
                    onRefresh: _fetchData,
                  ),
                ),
              ],
            ),
    );
  }
}
