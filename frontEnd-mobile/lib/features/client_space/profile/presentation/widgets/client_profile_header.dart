import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hjamty/features/auth/data/auth_service.dart';
import 'package:toastification/toastification.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';

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
    final TextEditingController addressController = TextEditingController(
      text: widget.userData?['profile']?['address'] ?? '',
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
                      padding: EdgeInsets.only(
                        left: 24.0,
                        right: 24.0,
                        top: 24.0,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
                      ),
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
                                          : tr(context, 'default_user'),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      emailController.text.isNotEmpty
                                          ? emailController.text
                                          : tr(context, 'no_email'),
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
                          Text(
                            tr(context, 'personal_info'),
                            style: const TextStyle(
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
                                    labelText: tr(context, 'first_name'),
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
                                    labelText: tr(context, 'last_name'),
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
                              labelText: tr(context, 'phone_number'),
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
                              labelText: tr(context, 'email_address'),
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: addressController,
                            decoration: InputDecoration(
                              labelText: tr(context, 'address'),
                              prefixIcon: const Icon(
                                Icons.location_on_outlined,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Text(
                            tr(context, 'profile_photo'),
                            style: const TextStyle(
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
                                      ? tr(context, 'processing')
                                      : tr(
                                          context,
                                          'uploading_progress',
                                          args: [
                                            (_uploadProgress * 100)
                                                .toStringAsFixed(0),
                                          ],
                                        ),
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
                                            title: Text(tr(context, 'success')),
                                            description: Text(
                                              tr(
                                                context,
                                                'image_uploaded_success',
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          setModalState(() {
                                            _isUploading = false;
                                          });
                                          toastification.show(
                                            context: context,
                                            type: ToastificationType.error,
                                            title: Text(
                                              tr(context, 'upload_error'),
                                            ),
                                            description: Text(e.toString()),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.upload_file),
                                    label: Text(tr(context, 'choose_image')),
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
                              labelText: tr(context, 'or_paste_url'),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  toastification.show(
                                    context: context,
                                    type: ToastificationType.error,
                                    title: Text(tr(context, 'attention')),
                                    description: Text(
                                      tr(context, 'feature_soon'),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                label: Text(
                                  tr(context, 'delete'),
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      tr(context, 'cancel'),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
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
                                                phoneNumber: phoneController
                                                    .text
                                                    .trim(),
                                                email: emailController.text
                                                    .trim(),
                                                address: addressController.text
                                                    .trim(),
                                                avatarUrl: urlController.text
                                                    .trim(),
                                              );
                                              if (context.mounted) {
                                                Navigator.pop(context);
                                                widget.onUpdate?.call();
                                                toastification.show(
                                                  context: context,
                                                  type: ToastificationType
                                                      .success,
                                                  title: Text(
                                                    tr(context, 'success'),
                                                  ),
                                                  description: Text(
                                                    tr(
                                                      context,
                                                      'profile_updated',
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                toastification.show(
                                                  context: context,
                                                  type:
                                                      ToastificationType.error,
                                                  title: Text(
                                                    tr(context, 'error_title'),
                                                  ),
                                                  description: Text(
                                                    e.toString(),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      tr(context, 'save_btn'),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
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
    final name = widget.userData?['fullName'] ?? tr(context, 'default_user');
    final role = widget.userData?['role'] ?? tr(context, 'default_user');
    final phone = widget.userData?['phoneNumber'] ?? '';
    final avatarUrl = widget.userData?['profile']?['avatarUrl'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.15),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 42,
              backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : const NetworkImage(
                      'https://cdn-icons-png.flaticon.com/512/149/149071.png', // Generic avatar
                    ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role == 'EMPLOYEE'
                        ? phone
                        : (phone.isNotEmpty ? phone : role),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showEditProfileModal(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
