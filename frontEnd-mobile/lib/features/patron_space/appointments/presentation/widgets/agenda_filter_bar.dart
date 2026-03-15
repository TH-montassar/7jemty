import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';

class AgendaFilterBar extends StatelessWidget {
  final String statusFilter;
  final String sortField;
  final bool sortAscending;
  final int totalCount;
  final int shownCount;
  final String Function(String status) statusLabel;
  final VoidCallback onClearFilters;
  final ValueChanged<String> onStatusSelected;
  final ValueChanged<String> onSortFieldSelected;
  final VoidCallback onToggleSortDirection;

  const AgendaFilterBar({
    super.key,
    required this.statusFilter,
    required this.sortField,
    required this.sortAscending,
    required this.totalCount,
    required this.shownCount,
    required this.statusLabel,
    required this.onClearFilters,
    required this.onStatusSelected,
    required this.onSortFieldSelected,
    required this.onToggleSortDirection,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters =
        statusFilter != 'ALL' ||
        sortField != 'APPOINTMENT_DATE' ||
        !sortAscending;

    // Shared filter shell for patron and employee agenda pages.
    Widget chip({
      required Widget child,
      bool active = false,
      EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
    }) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryBlue.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primaryBlue : Colors.grey.shade300,
            width: active ? 1.5 : 1,
          ),
        ),
        child: child,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                PopupMenuButton<String>(
                  onSelected: onStatusSelected,
                  itemBuilder: (context) => [
                    'ALL',
                    'PENDING',
                    'CONFIRMED',
                    'IN_PROGRESS',
                    'ARRIVED',
                    'COMPLETED',
                    'CANCELLED',
                    'DECLINED',
                  ]
                      .map(
                        (status) => PopupMenuItem<String>(
                          value: status,
                          child: Text(statusLabel(status)),
                        ),
                      )
                      .toList(),
                  child: chip(
                    active: statusFilter != 'ALL',
                    child: Row(
                      children: [
                        Text(
                          statusLabel(statusFilter),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: onSortFieldSelected,
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'APPOINTMENT_DATE',
                      child: Text('Date RDV'),
                    ),
                    PopupMenuItem<String>(
                      value: 'CREATED_AT',
                      child: Text('Date creation'),
                    ),
                  ],
                  child: chip(
                    active: sortField != 'APPOINTMENT_DATE',
                    child: Row(
                      children: [
                        Text(
                          sortField == 'CREATED_AT'
                              ? 'Date creation'
                              : 'Date RDV',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onToggleSortDirection,
                  child: chip(
                    active: !sortAscending,
                    child: Row(
                      children: [
                        Icon(
                          sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 14,
                          color: AppColors.textDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          sortAscending ? 'Asc' : 'Desc',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onClearFilters,
                    child: chip(
                      child: const Row(
                        children: [
                          Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: AppColors.textDark,
                          ),
                          SizedBox(width: 6),
                          Text('Reset', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$shownCount / $totalCount',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
