import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../core/constants/app_colors.dart';
import '../../services/salon_service.dart'; // 👈 N3aytou lel service elli sna3neh
import 'add_salon_info_screen.dart'; // Nzidou l'import mta3 AddInfo

class CreateSalonScreen extends StatefulWidget {
  const CreateSalonScreen({super.key});

  @override
  State<CreateSalonScreen> createState() => _CreateSalonScreenState();
}

class _CreateSalonScreenState extends State<CreateSalonScreen> {
  final _formKey = GlobalKey<FormState>();

  // L'Controllers mta3 l'input
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;

  // 🚀 L'Fonction elli tkhaddem kol chay
  Future<void> _handleCreateSalon() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Nkalmou l'API njibou l'données mel TextFields
      await SalonService.createSalon(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (!mounted) return;

      // Toast l'Naje7
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        title: const Text(
          'Mabrouk! 🎉',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        description: const Text(
          'Salon créé avec succès',
          style: TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.successGreen,
        backgroundColor: AppColors.successGreen,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        showProgressBar: false,
      );

      // 🔄 Nhezzou lel ajout des infos e-thanya
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AddSalonInfoScreen()),
      );
    } catch (error) {
      if (!mounted) return;

      // Toast l'Ghalta
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

  // Tanthif l'memoire
  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: const Text(
          "Mon Salon",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
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
                  Icons.storefront,
                  size: 80,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Configurez votre Salon",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Donnez un nom et une adresse à votre espace.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // Esem e-Salon
                _buildTextField(
                  controller: _nameController,
                  hintText: "Nom du Salon (ex: Barbershop VIP)",
                  icon: Icons.title,
                ),
                const SizedBox(height: 20),

                // Adresse mta3 e-Salon
                _buildTextField(
                  controller: _addressController,
                  hintText: "Adresse complète",
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 40),

                // L'Bouton mta3 l'Creation
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _handleCreateSalon(); // 👈 N3aytou lel fonction houni
                          }
                        },
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
                          "Créer mon salon",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🧩 L'Widget mta3 TextFields
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
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
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: AppColors.primaryBlue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Ce champ est requis'
            : null,
      ),
    );
  }
}
