import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/features/client_space/appointments/presentation/widgets/appointment_details_bottom_sheet.dart';

class SharedCalendarView extends StatelessWidget {
  final List<dynamic> appointments;
  final bool isEmployeeView;
  final Function()? onRefresh;

  const SharedCalendarView({
    super.key,
    required this.appointments,
    this.isEmployeeView = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SfCalendar(
      view: CalendarView.week,
      firstDayOfWeek: 1, // Monday
      timeSlotViewSettings: const TimeSlotViewSettings(
        startHour: 7,
        endHour: 22,
        timeFormat: 'HH:mm',
        timeIntervalHeight: 60,
      ),
      dataSource: AppointmentDataSource(_getCalendarAppointments()),
      onTap: (CalendarTapDetails details) {
        if (details.targetElement == CalendarElement.appointment) {
          final CustomAppointment apt = details.appointments!.first;
          showAppointmentDetailsBottomSheet(
            context: context,
            appointment: apt.originalData,
            showBarberDetails: !isEmployeeView,
          ).then((_) {
            if (onRefresh != null) {
              onRefresh!();
            }
          });
        }
      },
      appointmentBuilder: (context, calendarAppointmentDetails) {
        final CustomAppointment appointment =
            calendarAppointmentDetails.appointments.first;
        return Container(
          decoration: BoxDecoration(
            color: appointment.color,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(4),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.subject,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (appointment.notes != null)
                  Text(
                    appointment.notes!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<CustomAppointment> _getCalendarAppointments() {
    final List<CustomAppointment> calendarAppointments = <CustomAppointment>[];

    for (var apt in appointments) {
      final dateStr = apt['appointmentDate'];
      if (dateStr == null) continue;

      final startTime = DateTime.parse(dateStr).toLocal();

      // Calculate duration and end time
      int totalMinutes = 0;
      final services = apt['services'] as List?;
      if (services != null) {
        for (var s in services) {
          final srv = s['service'];
          if (srv != null) {
            totalMinutes += (srv['durationMinutes'] as num?)?.toInt() ?? 0;
          }
        }
      }
      
      // Default to 30 mins if no services found or duration is 0
      if (totalMinutes == 0) totalMinutes = 30;

      DateTime endTime = startTime.add(Duration(minutes: totalMinutes));

      // Adjust end time if actual duration is longer (IN_PROGRESS or COMPLETED with extended time)
      if ((apt['status'] == 'IN_PROGRESS' || apt['status'] == 'COMPLETED') && apt['estimatedEndTime'] != null) {
         try {
           final estimatedEnd = DateTime.parse(apt['estimatedEndTime']).toLocal();
           if(estimatedEnd.isAfter(endTime)) {
             endTime = estimatedEnd;
           }
         } catch(e) {
             // ignore parse error here
         }
      }

      final status = (apt['status'] as String?)?.toUpperCase() ?? 'PENDING';
      Color color = Colors.grey;

      if (status == 'PENDING') {
        color = Colors.orange;
      } else if (status == 'CONFIRMED' || status == 'ACCEPTED') {
        color = AppColors.primaryBlue;
      } else if (status == 'IN_PROGRESS') {
        color = Colors.purple;
      } else if (status == 'COMPLETED' || status == 'DECLINED' || status == 'CANCELLED') {
         // Skip completed and cancelled ones
        continue; 
      }

      final clientName = apt['client']?['fullName'] ?? 'Client';
      final serviceName = services?.isNotEmpty == true
          ? services![0]['service']['name']
          : 'Service';
          
      String notes = isEmployeeView ? serviceName : "$clientName - $serviceName";    

      calendarAppointments.add(CustomAppointment(
        startTime: startTime,
        endTime: endTime,
        subject: isEmployeeView ? clientName : (apt['barber']?['fullName'] ?? apt['specialist']?['name'] ?? apt['specialist']?['user']?['name'] ?? 'Barber'),
        color: color,
        originalData: apt,
        notes: notes,
      ));
    }

    return calendarAppointments;
  }
}

class CustomAppointment extends Appointment {
  final dynamic originalData;

  CustomAppointment({
    required super.startTime,
    required super.endTime,
    required super.subject,
    required super.color,
    super.notes,
    required this.originalData,
  });
}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<CustomAppointment> source) {
    appointments = source;
  }
}
