import 'package:flutter/material.dart';
import 'package:hjamty/core/localization/translation_service.dart';

DateTime? agendaSafeDate(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString())?.toLocal();
}

DateTime? agendaCreatedDate(dynamic appointment) {
  return agendaSafeDate(appointment['createdAt']) ??
      agendaSafeDate(appointment['created_at']) ??
      agendaSafeDate(appointment['createdDate']);
}

String agendaStatusLabel(BuildContext context, String status) {
  if (status == 'ALL') {
    final statusLabel = tr(context, 'status');
    return statusLabel == 'status' ? 'Status' : statusLabel;
  }
  if (status == 'ARRIVED') return 'Arrived';
  final key = 'status_${status.toLowerCase()}';
  final translated = tr(context, key);
  if (translated == key) {
    return status.replaceAll('_', ' ');
  }
  return translated;
}

List<dynamic> applyAgendaFiltersAndSort({
  required List<dynamic> source,
  required String statusFilter,
  required String sortField,
  required bool sortAscending,
}) {
  final filtered = source.where((appointment) {
    final status = (appointment['status'] ?? '').toString().toUpperCase();
    if (statusFilter != 'ALL' && status != statusFilter) {
      return false;
    }
    return true;
  }).toList();

  filtered.sort((a, b) {
    DateTime getSortDate(dynamic appointment) {
      if (sortField == 'CREATED_AT') {
        return agendaCreatedDate(appointment) ??
            agendaSafeDate(appointment['appointmentDate']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }
      return agendaSafeDate(appointment['appointmentDate']) ??
          agendaCreatedDate(appointment) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    final compare = getSortDate(a).compareTo(getSortDate(b));
    if (compare != 0) {
      return sortAscending ? compare : -compare;
    }
    final statusA = (a['status'] ?? '').toString();
    final statusB = (b['status'] ?? '').toString();
    return statusA.compareTo(statusB);
  });

  return filtered;
}
