import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../core/constants/app_colors.dart';
import '../../services/salon_service.dart';
import 'main_page.dart'; // Bech Nhezzou lil MainPage

class AddSalonInfoScreen extends StatefulWidget {
  const AddSalonInfoScreen({super.key});

  @override
  State<AddSalonInfoScreen> createState() => _AddSalonInfoScreenState();
}

class _AddSalonInfoScreenState extends State<AddSalonInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();

  bool _isLoading = false;

  Future<void> _handleSaveInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Nkalmou l'API bech nbadlou l'Salon
      await SalonService.updateSalonInfo(
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        contactPhone: _contactPhoneController.text.trim().isNotEmpty
            ? _contactPhoneController.text.trim()
            : null,
      );

      if (!mounted) return;

      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        title: const Text(
          'Succès 🎉',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        description: const Text(
          'Informations ajoutées avec succès',
          style: TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.successGreen,
        backgroundColor: AppColors.successGreen,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        showProgressBar: false,
      );

      // 2. Nhezzouh lel MainPage (elli fiha e-SalonPage s7i7a)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        title: const Text(
          'Erreur',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        description: Text(
          error.toString(),
          style: const TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.actionRed,
        backgroundColor: AppColors.actionRed,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        showProgressBar: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _skip() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainPage()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: const Text(
          "Détails Supplémentaires",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text(
              "Plus tard",
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 80,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Encore quelques détails",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Ajoutez une description et un contact pour attirer plus de clients (Optionnel).",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // Description
                _buildTextField(
                  controller: _descriptionController,
                  hintText: "Description du salon",
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Contact Phone
                _buildTextField(
                  controller: _contactPhoneController,
                  hintText: "Numéro de contact du salon",
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleSaveInfo(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Enregistrer les infos",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 15),
                OutlinedButton(
                  onPressed: _skip,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Passer cette étape",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Icon(icon, color: AppColors.primaryBlue),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}
