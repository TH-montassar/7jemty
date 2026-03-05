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
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
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
                              icon: const Icon(Icons.remove_red_eye),
                              label: Text(tr(context, 'peek_view')),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editSalon(salon),
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

  Future<void> _editSalon(Map<String, dynamic> salon) async {
    final nameController = TextEditingController(text: salon['name']);
    final addressController = TextEditingController(text: salon['address']);
    final phoneController = TextEditingController(text: salon['contactPhone']);
    final descController = TextEditingController(text: salon['description']);
    final specialityController = TextEditingController(
      text: salon['speciality'],
    );

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Salon Info'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Salon Name'),
              ),
              TextField(
                controller: specialityController,
                decoration: const InputDecoration(labelText: 'Speciality'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Contact Phone'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(context, 'save_btn')),
          ),
        ],
      ),
    );

    if (updated == true) {
      try {
        await AdminService.updateSalon(salon['id'], {
          'name': nameController.text,
          'speciality': specialityController.text,
          'contactPhone': phoneController.text,
          'address': addressController.text,
          'description': descController.text,
        });
        _fetchSalons();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Widget _getStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'APPROVED') color = Colors.green;
    if (status == 'PENDING') color = Colors.orange;
    if (status == 'SUSPENDED') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
}
