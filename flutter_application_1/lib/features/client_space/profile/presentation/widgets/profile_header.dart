import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hjamty/services/auth_service.dart';
import 'package:toastification/toastification.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';

class ProfileHeader extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback? onUpdate;

  const ProfileHeader({super.key, this.userData, this.onUpdate});

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  void _showEditProfileModal(BuildContext context) {
    final String fullName = widget.userData?['fullName'] ?? '';
    final List<String> nameParts = fullName.split(' ');
    final String firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final String lastName = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : '';

    final TextEditingController firstNameController = TextEditingController(
      text: firstName,
    );
    final TextEditingController lastNameController = TextEditingController(
      text: lastName,
    );
    final TextEditingController phoneController = TextEditingController(
      text: widget.userData?['phoneNumber'] ?? '',
    );
    final TextEditingController emailController = TextEditingController(
      text: widget.userData?['profile']?['email'] ?? '',
    );
    final TextEditingController urlController = TextEditingController(
      text: widget.userData?['profile']?['avatarUrl'] ?? '',
    );

    final ImagePicker picker = ImagePicker();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: animation,
            child: Dialog(
              insetPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: AppColors.primaryBlue
                                    .withValues(alpha: 0.1),
                                backgroundImage: urlController.text.isNotEmpty
                                    ? NetworkImage(urlController.text)
                                    : const NetworkImage(
                                        'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName.isNotEmpty
                                          ? fullName
                                          : 'Utilisateur',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      emailController.text.isNotEmpty
                                          ? emailController.text
                                          : 'pas d\'email',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Input Fields
                          const Text(
                            'Informations personnelles',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: firstNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Prénom',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: lastNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Nom',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Numéro de téléphone',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: 'Adresse Email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'Photo de profil',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (_isUploading)
                            Column(
                              children: [
                                LinearProgressIndicator(
                                  value: _uploadProgress,
                                  backgroundColor: Colors.grey[200],
                                  color: AppColors.primaryBlue,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _uploadProgress >= 1.0
                                      ? 'Traitement en cours...'
                                      : 'Envoi en cours: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final XFile? image = await picker
                                          .pickImage(
                                            source: ImageSource.gallery,
                                            imageQuality: 70, // Optimize
                                          );
                                      if (image != null) {
                                        setModalState(() {
                                          _isUploading = true;
                                          _uploadProgress = 0.0;
                                        });

                                        try {
                                          final Uint8List bytes = await image
                                              .readAsBytes();
                                          final String uploadedUrl =
                                              await AuthService.uploadImage(
                                                bytes: bytes,
                                                filename: image.name,
                                                onProgress: (p) {
                                                  setModalState(() {
                                                    _uploadProgress = p;
                                                  });
                                                },
                                              );

                                          setModalState(() {
                                            urlController.text = uploadedUrl;
                                            _isUploading = false;
                                          });

                                          toastification.show(
                                            context: context,
                                            type: ToastificationType.success,
                                            title: const Text('Succès'),
                                            description: const Text(
                                              'Image uploadée avec succès !',
                                            ),
                                          );
                                        } catch (e) {
                                          setModalState(() {
                                            _isUploading = false;
                                          });
                                          toastification.show(
                                            context: context,
                                            type: ToastificationType.error,
                                            title: const Text('Erreur upload'),
                                            description: Text(e.toString()),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text('Choisir une image'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: urlController,
                            decoration: InputDecoration(
                              labelText: 'Ou coller un URL',
                              prefixIcon: const Icon(Icons.link),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (val) {
                              setModalState(() {});
                            },
                          ),
                          const SizedBox(height: 32),

                          // Footer Actions
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  toastification.show(
                                    context: context,
                                    type: ToastificationType.error,
                                    title: const Text('Attention'),
                                    description: const Text(
                                      'Fonctionnalité bientôt disponible',
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Supprimer',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annuler'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isUploading
                                    ? null
                                    : () async {
                                        try {
                                          final String newFullName =
                                              '${firstNameController.text.trim()} ${lastNameController.text.trim()}'
                                                  .trim();
                                          await AuthService.updateProfile(
                                            fullName: newFullName,
                                            phoneNumber: phoneController.text
                                                .trim(),
                                            email: emailController.text.trim(),
                                            avatarUrl: urlController.text
                                                .trim(),
                                          );
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            widget.onUpdate?.call();
                                            toastification.show(
                                              context: context,
                                              type: ToastificationType.success,
                                              title: const Text('Succès'),
                                              description: const Text(
                                                'Profil mis à jour !',
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            toastification.show(
                                              context: context,
                                              type: ToastificationType.error,
                                              title: const Text('Erreur'),
                                              description: Text(e.toString()),
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Enregistrer'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // If userData is provided (fetched from database), priority is given to it
    final name = widget.userData?['fullName'] ?? 'Utilisateur';
    final role = widget.userData?['role'] ?? 'Client';
    final phone = widget.userData?['phoneNumber'] ?? '';
    final avatarUrl = widget.userData?['profile']?['avatarUrl'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : const NetworkImage(
                    'https://cdn-icons-png.flaticon.com/512/149/149071.png', // Generic avatar
                  ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role == 'EMPLOYEE'
                      ? phone
                      : (phone.isNotEmpty ? phone : role),
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.bgColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.edit,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              onPressed: () => _showEditProfileModal(context),
            ),
          ),
        ],
      ),
    );
  }
}
