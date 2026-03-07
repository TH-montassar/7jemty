import 'package:hjamty/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/features/admin_space/data/admin_service.dart';
import 'package:hjamty/features/patron_space/salon_dashboard_screen.dart';

class ManageSalonsPage extends StatefulWidget {
  const ManageSalonsPage({super.key});

  @override
  State<ManageSalonsPage> createState() => _ManageSalonsPageState();
}

class _ManageSalonsPageState extends State<ManageSalonsPage> {
  bool _isLoading = true;
  List<dynamic> _salons = [];

  @override
  void initState() {
    super.initState();
    _fetchSalons();
  }

  Future<void> _fetchSalons() async {
    try {
      final salons = await AdminService.getAllSalons();
      if (mounted) {
        setState(() {
          _salons = salons;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    try {
      await AdminService.updateSalonStatus(id, status);
      _fetchSalons();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteSalon(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(context, 'delete_salon_confirm')),
        content: Text(tr(context, 'delete_salon_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              tr(context, 'delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.deleteSalon(id);
        _fetchSalons();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'manage_salons')),
        backgroundColor: Colors.indigo.shade900,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _salons.length,
              itemBuilder: (ctx, index) {
                final salon = _salons[index];
                final status = salon['approvalStatus'] ?? 'PENDING';
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              (salon['coverImageUrl'] != null &&
                                  salon['coverImageUrl'].isNotEmpty)
                              ? NetworkImage(salon['coverImageUrl'])
                              : null,
                          child:
                              (salon['coverImageUrl'] == null ||
                                  salon['coverImageUrl'].isEmpty)
                              ? const Icon(Icons.store)
                              : null,
                        ),
                        title: Text(salon['name'] ?? 'Unknown'),
                        subtitle: Text(salon['address'] ?? 'No address'),
                        trailing: _getStatusBadge(status),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SalonDashboardScreen(
                                isPatron:
                                    true, // Allow admin to peek with full permissions
                                salonId: salon['id'],
                              ),
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Peek button removed, it's now accessible by tapping the card
                            IconButton(
                              icon: const Icon(
                                Icons.bar_chart,
                                color: Colors.purple,
                              ),
                              onPressed: () =>
                                  _showStatsDialog(salon['id'], salon['name']),
                              tooltip: 'Statistiques',
                            ),

                            const Spacer(),
                            if (status == 'PENDING')
                              ElevatedButton(
                                onPressed: () =>
                                    _updateStatus(salon['id'], 'APPROVED'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: Text(tr(context, 'approve')),
                              ),
                            if (status == 'APPROVED')
                              OutlinedButton(
                                onPressed: () =>
                                    _updateStatus(salon['id'], 'SUSPENDED'),
                                child: Text(
                                  tr(context, 'suspend'),
                                  style: const TextStyle(color: Colors.orange),
                                ),
                              ),
                            if (status == 'SUSPENDED')
                              ElevatedButton(
                                onPressed: () =>
                                    _updateStatus(salon['id'], 'APPROVED'),
                                child: Text(tr(context, 'reactivate')),
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteSalon(salon['id']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _getStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'APPROVED') color = Colors.green;
    if (status == 'PENDING') color = Colors.orange;
    if (status == 'SUSPENDED') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showStatsDialog(int salonId, String salonName) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>>(
          future: AdminService.getSalonStats(salonId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 300,
                child: Center(
                  child: Text(
                    'Erreur: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            final stats = snapshot.data!;
            final specialists = stats['specialistStats'] as List<dynamic>;

            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Statistiques: $salonName',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Coupes',
                        '${stats['totalAppointments']}',
                        Icons.content_cut,
                        AppColors.primaryBlue,
                      ),
                      _buildStatCard(
                        'Revenus',
                        '${stats['totalRevenue']} TND',
                        Icons.attach_money,
                        AppColors.actionRed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Par Spécialiste',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  specialists.isEmpty
                      ? Text(tr(context, 'no_data_available'))
                      : Expanded(
                          child: ListView.builder(
                            itemCount: specialists.length,
                            itemBuilder: (context, i) {
                              final spec = specialists[i];
                              return ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                title: Text(spec['name']),
                                subtitle: Text(
                                  tr(
                                    context,
                                    'coupes_count',
                                    args: [spec['count'].toString()],
                                  ),
                                ),
                                trailing: Text(
                                  '${spec['revenue']} TND',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.actionRed,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
