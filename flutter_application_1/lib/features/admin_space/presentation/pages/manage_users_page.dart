import 'package:flutter/material.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/features/admin_space/data/admin_service.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  bool _isLoading = true;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await AdminService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(context, 'delete_user_q')),
        content: Text(tr(context, 'delete_user_desc')),
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
        await AdminService.deleteUser(id);
        _fetchUsers();
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
        title: Text(tr(context, 'manage_users')),
        backgroundColor: Colors.indigo.shade900,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (ctx, index) {
                final user = _users[index];
                final profile = user['profile'];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profile?['avatarUrl'] != null
                          ? NetworkImage(profile['avatarUrl'])
                          : null,
                      child: profile?['avatarUrl'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(user['fullName'] ?? 'Unknown'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['phoneNumber']),
                        Text(
                          "Role: ${user['role']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    trailing: user['role'] == 'ADMIN'
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _editUser(user),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteUser(user['id']),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final nameController = TextEditingController(text: user['fullName']);
    final phoneController = TextEditingController(text: user['phoneNumber']);
    final emailController = TextEditingController(
      text: user['profile']?['email'] ?? '',
    );
    final bioController = TextEditingController(
      text: user['profile']?['bio'] ?? '',
    );
    final specialityController = TextEditingController(
      text: user['profile']?['specialityTitle'] ?? '',
    );

    String selectedRole = user['role'];
    bool isVerified = user['isVerified'] ?? false;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit User & Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: specialityController,
                  decoration: const InputDecoration(
                    labelText: 'Speciality Title',
                  ),
                ),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(labelText: 'Bio'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: selectedRole,
                  isExpanded: true,
                  items: ['CLIENT', 'PATRON', 'EMPLOYEE', 'ADMIN']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedRole = val);
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text('Verified'),
                  value: isVerified,
                  onChanged: (val) {
                    setDialogState(() => isVerified = val);
                  },
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
      ),
    );

    if (updated == true) {
      try {
        await AdminService.updateUser(
          user['id'],
          fullName: nameController.text,
          phoneNumber: phoneController.text,
          role: selectedRole,
          isVerified: isVerified,
          profile: {
            'email': emailController.text,
            'bio': bioController.text,
            'specialityTitle': specialityController.text,
          },
        );
        _fetchUsers();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
