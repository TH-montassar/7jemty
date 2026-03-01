import 'package:intl/intl.dart';

void main() {
  List<Map<String, dynamic>> slots = [];
  DateTime currentTime = DateTime(2023, 1, 1, 8, 0); // 08:00
  final endTime = DateTime(2023, 1, 1, 17, 0); // 17:00

  while (currentTime.compareTo(endTime) < 0) {
    final timeStr = DateFormat('HH:mm').format(currentTime);
    slots.add({'time': timeStr, 'available': true});
    currentTime = currentTime.add(const Duration(minutes: 30));
  }
  print(slots.map((s) => s['time']).toList());
}
