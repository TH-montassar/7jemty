import 'package:hjamty/core/localization/translation_service.dart';
import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'all_appointments_page.dart';
import 'today_appointments_page.dart';
import '../widgets/animated_button.dart';
import '../widgets/animated_text_button.dart'; // تأكد أنك صنعت الملف هذا
import '../widgets/appointment_card.dart';
import '../widgets/dashboard_stats.dart';
import '../widgets/info_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // الداتا (ما تنساش تبدل التواريخ حسب اليوم باش تجرب)
  final List<Map<String, String>> myAppointments = [
    {
      'name': 'Montassar',
      'service': 'Coupe',
      'time': '10:00 AM',
      'date': '2026-02-06',
    },
    {
      'name': 'Ali Ben Salah',
      'service': 'Barbe',
      'time': '11:30 AM',
      'date': '2026-02-20',
    },
    {
      'name': 'Karim Tounsi',
      'service': 'Coupe + Teinture',
      'time': '02:00 PM',
      'date': '2026-02-47',
    },
    {
      'name': 'Sami Feki',
      'service': 'Soins Visage',
      'time': '04:15 PM',
      'date': '2026-02-20',
    },
    {
      'name': 'Houssem',
      'service': 'Coupe',
      'time': '06:00 PM',
      'date': '2026-02-09',
    },
    {
      'name': 'Ahmed',
      'service': 'Barbe',
      'time': '07:30 PM',
      'date': '2026-02-10',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardStats(),
            const SizedBox(height: 16),

            // --- زر RDV Aujourd'hui (مصلح) ---
            InfoCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.calendar_month_outlined, color: Colors.blue),
                      SizedBox(width: 16),
                      Text(
                        'RDV Aujourd\'hui',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // استعمال AnimatedTextButton
                  AnimatedTextButton(
                    text: 'Voir RDV',
                    borderRadius: 8.0,
                    onTap: () {
                      DateTime now = DateTime.now();
                      String todayString =
                          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

                      final List<Map<String, String>> todayList = myAppointments
                          .where((item) {
                            return item['date'] == todayString;
                          })
                          .toList();

                      if (todayList.isEmpty) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(tr(context, 'information_title')),
                            content: const Text(
                              "Vous n'avez aucun rendez-vous pour aujourd'hui.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(tr(context, 'ok_btn')),
                              ),
                            ],
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TodayAppointmentsPage(
                              todayAppointments: todayList,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Quick Access ---
            const Text(
              'Quick Access',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedQuickAccessButton(
                  icon: Icons.calendar_view_month_outlined,
                  label: 'Gérer Mon\nCalendrier',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CalendarPage(),
                      ),
                    );
                  },
                ),
                AnimatedQuickAccessButton(
                  icon: Icons.list_alt_outlined,
                  label: 'Gérer Mes\nRendez-vous',
                  onTap: () {},
                ),
                AnimatedQuickAccessButton(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Gérer Mes\nCommandes',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Prochains Rendez-vous (مصلح) ---
            const Text(
              'Prochains Rendez-vous',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Column(
              children: myAppointments.take(2).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  // استعمال AppointmentCard (وليس _buildAppointmentCard)
                  child: AppointmentCard(
                    name: item['name']!,
                    service: item['service']!,
                    time: item['time']!,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),

            // --- زر Voir tout (مصلح) ---
            Center(
              child: AnimatedTextButton(
                text: 'Voir tout',
                width: 120,
                borderRadius: 20.0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AllAppointmentsPage(appointments: myAppointments),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
