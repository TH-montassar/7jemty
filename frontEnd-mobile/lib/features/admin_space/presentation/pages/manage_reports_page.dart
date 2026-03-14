import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hjamty/core/services/fcm_service.dart';
import 'package:hjamty/core/services/notification_service.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/features/admin_space/data/admin_service.dart';

class ManageReportsPage extends StatefulWidget {
  const ManageReportsPage({super.key});

  @override
  State<ManageReportsPage> createState() => _ManageReportsPageState();
}

class _ManageReportsPageState extends State<ManageReportsPage> {
  bool _isLoading = true;
  List<dynamic> _reports = [];
  StreamSubscription<Map<String, dynamic>>? _reportsSubscription;

  @override
  void initState() {
    super.initState();
    NotificationService.listenToNotificationsStream();
    _reportsSubscription = FcmService.messageStream.listen(_handleRealtimeEvent);
    _fetchReports();
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    super.dispose();
  }

  void _handleRealtimeEvent(Map<String, dynamic> data) {
    final eventType = (data['eventType'] ?? data['type'] ?? '')
        .toString()
        .toUpperCase();

    if (eventType == 'REVIEW_REPORTED') {
      _fetchReports(showLoader: false);
      return;
    }

    if (eventType == 'REPORT_DISMISSED' || eventType == 'REPORT_ACTION_TAKEN') {
      final reportId = int.tryParse(data['reportId']?.toString() ?? '');
      if (reportId == null || !mounted) return;

      setState(() {
        _reports.removeWhere((report) => report['id'] == reportId);
      });
    }
  }

  Future<void> _fetchReports({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final reports = await AdminService.getReviewReports();
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resolveReport(int reportId, String action) async {
    final noteController = TextEditingController();
    bool warnUser = true;
    bool banUser = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tr(context, 'review_report_action_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: tr(context, 'review_report_admin_note'),
                  ),
                ),
                SwitchListTile(
                  value: warnUser,
                  onChanged: (v) => setDialogState(() => warnUser = v),
                  title: Text(tr(context, 'warn_user_label')),
                ),
                SwitchListTile(
                  value: banUser,
                  onChanged: (v) => setDialogState(() => banUser = v),
                  title: Text(tr(context, 'ban_user_label')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr(context, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr(context, 'save_btn')),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await AdminService.resolveReviewReport(
        reportId,
        action: action,
        adminNote: noteController.text.trim(),
        warnUser: warnUser,
        banUser: banUser,
      );
      if (!mounted) return;
      setState(() {
        _reports.removeWhere((report) => report['id'] == reportId);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'review_report_resolved'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'manage_review_reports')),
        backgroundColor: Colors.indigo.shade900,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
          ? Center(child: Text(tr(context, 'no_review_reports')))
          : ListView.builder(
              itemCount: _reports.length,
              padding: const EdgeInsets.only(bottom: 100),
              itemBuilder: (ctx, index) {
                final report = _reports[index] as Map<String, dynamic>;
                final review = (report['review'] as Map<String, dynamic>?) ?? {};
                final status = (report['status'] ?? 'PENDING').toString();

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${tr(context, 'report_from')}: ${report['reporter']?['fullName'] ?? '-'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${tr(context, 'review_owner')}: ${review['client']?['fullName'] ?? '-'}',
                        ),
                        Text(
                          '${tr(context, 'salon')}: ${review['salon']?['name'] ?? '-'}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${tr(context, 'report_message')}: ${report['message'] ?? ''}',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tr(context, 'report_reason_label')}: ${report['reason'] ?? '-'}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${tr(context, 'reported_review')}: ${review['comment'] ?? ''}',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(label: Text(status)),
                            const Spacer(),
                            if (status == 'PENDING') ...[
                              TextButton(
                                onPressed: () =>
                                    _resolveReport(report['id'], 'DISMISS'),
                                child: Text(tr(context, 'keep_review_btn')),
                              ),
                              ElevatedButton(
                                onPressed: () => _resolveReport(
                                  report['id'],
                                  'ACTION_TAKEN',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: Text(tr(context, 'delete_review_btn')),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
