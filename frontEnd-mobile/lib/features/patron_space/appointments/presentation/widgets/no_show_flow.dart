import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/features/client_space/appointments/data/appointment_service.dart';
import 'package:toastification/toastification.dart';

typedef AppointmentAction = Future<void> Function(int appointmentId);
typedef RefreshAction = Future<void> Function();
typedef OnStatusUpdatedAction = Future<void> Function();

Future<void> updateAppointmentStatusFlow({
  required BuildContext context,
  required int appointmentId,
  required String status,
  required OnStatusUpdatedAction onUpdated,
  required String successMessage,
  required String errorMessage,
  String? loadingMessage,
}) async {
  try {
    if (loadingMessage != null) {
      toastification.show(
        context: context,
        type: ToastificationType.info,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 2),
        title: Text(
          loadingMessage,
          style: const TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.primaryBlue,
        backgroundColor: AppColors.primaryBlue,
      );
    }

    await AppointmentService.updateStatus(
      appointmentId: appointmentId,
      status: status,
    );

    await onUpdated();
    if (!context.mounted) return;

    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      title: Text(
        successMessage,
        style: const TextStyle(color: Colors.white),
      ),
      primaryColor: AppColors.successGreen,
      backgroundColor: AppColors.successGreen,
    );
  } catch (e) {
    if (!context.mounted) return;

    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      title: Text(
        errorMessage,
        style: const TextStyle(color: Colors.white),
      ),
      description: Text(
        e.toString(),
        style: const TextStyle(color: Colors.white),
      ),
      primaryColor: AppColors.actionRed,
      backgroundColor: AppColors.actionRed,
    );
  }
}

Future<void> showNoShowDecisionDialog({
  required BuildContext context,
  required int appointmentId,
  required AppointmentAction onConfirmNoShow,
  required AppointmentAction onPostpone15,
}) async {
  final action = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(tr(context, 'no_show_dialog_title')),
        content: Text(tr(context, 'no_show_dialog_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr(context, 'cancel')),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'cancel_now'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.actionRed,
              side: const BorderSide(color: AppColors.actionRed),
            ),
            child: Text(tr(context, 'no_show_confirm_btn')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'postpone_15'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: Text(
              tr(context, 'postpone_15_btn'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );

  if (action == null) return;

  if (action == 'cancel_now') {
    await onConfirmNoShow(appointmentId);
    return;
  }

  if (action == 'postpone_15') {
    await onPostpone15(appointmentId);
  }
}

Future<void> postponeNoShowWithCascadeFlow({
  required BuildContext context,
  required int appointmentId,
  required RefreshAction onRefresh,
}) async {
  try {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 2),
      title: Text(
        tr(context, 'updating'),
        style: const TextStyle(color: Colors.white),
      ),
      primaryColor: AppColors.primaryBlue,
      backgroundColor: AppColors.primaryBlue,
    );

    await AppointmentService.postponeNoShowWithCascade(
      appointmentId: appointmentId,
      minutes: 15,
    );
    await onRefresh();
    if (!context.mounted) return;
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      title: Text(
        tr(context, 'postpone_15_success'),
        style: const TextStyle(color: Colors.white),
      ),
      primaryColor: AppColors.successGreen,
      backgroundColor: AppColors.successGreen,
    );
  } catch (e) {
    if (!context.mounted) return;
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      title: Text(
        tr(context, 'error_issue'),
        style: const TextStyle(color: Colors.white),
      ),
      description: Text(
        e.toString(),
        style: const TextStyle(color: Colors.white),
      ),
      primaryColor: AppColors.actionRed,
      backgroundColor: AppColors.actionRed,
    );
  }
}