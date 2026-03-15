import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';

class AppointmentFilterOption {
  final String value;
  final String labelKey;

  const AppointmentFilterOption({
    required this.value,
    required this.labelKey,
  });
}

class AppointmentFilterBar extends StatelessWidget {
  final String selectedStatus;
  final String sortField;
  final bool sortAscending;
  final List<AppointmentFilterOption> statusOptions;
  final VoidCallback onReset;
  final ValueChanged<String> onStatusSelected;
  final ValueChanged<String> onSortFieldSelected;
  final VoidCallback onSortDirectionToggle;

  const AppointmentFilterBar({
    super.key,
    required this.selectedStatus,
    required this.sortField,
    required this.sortAscending,
    required this.statusOptions,
    required this.onReset,
    required this.onStatusSelected,
    required this.onSortFieldSelected,
    required this.onSortDirectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Shared filter chips for appointment list tabs.
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 15, bottom: 5),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          GestureDetector(
            onTap: onReset,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selectedStatus == 'All'
                      ? AppColors.primaryBlue
                      : Colors.grey.shade300,
                  width: selectedStatus == 'All' ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  tr(context, 'all'),
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: selectedStatus == 'All'
                        ? FontWeight.bold
                        : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: Colors.white,
            offset: const Offset(0, 45),
            onSelected: onStatusSelected,
            itemBuilder: (context) => statusOptions
                .map(
                  (option) => PopupMenuItem<String>(
                    value: option.value,
                    child: Text(
                      tr(context, option.labelKey),
                      style: TextStyle(
                        color: selectedStatus == option.value
                            ? AppColors.primaryBlue
                            : AppColors.textDark,
                        fontWeight: selectedStatus == option.value
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selectedStatus != 'All'
                      ? AppColors.primaryBlue
                      : Colors.grey.shade300,
                  width: selectedStatus != 'All' ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    selectedStatus != 'All'
                        ? tr(context, 'status_${selectedStatus.toLowerCase()}')
                        : tr(context, 'status'),
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: selectedStatus != 'All'
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.textDark,
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: Colors.white,
            offset: const Offset(0, 45),
            onSelected: onSortFieldSelected,
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'APPOINTMENT_DATE',
                child: Text(
                  'Date RDV',
                  style: TextStyle(
                    color: sortField == 'APPOINTMENT_DATE'
                        ? AppColors.primaryBlue
                        : AppColors.textDark,
                    fontWeight: sortField == 'APPOINTMENT_DATE'
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'CREATED_AT',
                child: Text(
                  'Date creation',
                  style: TextStyle(
                    color: sortField == 'CREATED_AT'
                        ? AppColors.primaryBlue
                        : AppColors.textDark,
                    fontWeight: sortField == 'CREATED_AT'
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sortField != 'APPOINTMENT_DATE'
                      ? AppColors.primaryBlue
                      : Colors.grey.shade300,
                  width: sortField != 'APPOINTMENT_DATE' ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    sortField == 'CREATED_AT' ? 'Date creation' : 'Date RDV',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: sortField != 'APPOINTMENT_DATE'
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.textDark,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onSortDirectionToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: !sortAscending
                      ? AppColors.primaryBlue
                      : Colors.grey.shade300,
                  width: !sortAscending ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: AppColors.textDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sortAscending ? 'Asc' : 'Desc',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: !sortAscending
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
