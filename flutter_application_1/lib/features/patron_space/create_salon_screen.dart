import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/features/client_space/salon_profile/data/salon_service.dart';
import 'main_page.dart';
import 'package:hjamty/core/localization/translation_service.dart';

class CreateSalonScreen extends StatefulWidget {
  const CreateSalonScreen({super.key});

  @override
  State<CreateSalonScreen> createState() => _CreateSalonScreenState();
}

class _CreateSalonScreenState extends State<CreateSalonScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Identité
  final _step1FormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _googleMapsController = TextEditingController(); // Optional
  final _specialityController = TextEditingController(); // Optional

  // Step 2: Présentation
  final _descController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();

  // Step 3: Photo de couverture
  bool _isUrlMode = false;
  final _coverUrlController = TextEditingController();
  String? _selectedImageBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _googleMapsController.dispose();
    _specialityController.dispose();
    _descController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBase64 = base64Encode(bytes);
          _isUrlMode = false;
        });
      }
    } catch (_) {}
  }

  void _nextStep() async {
    if (_currentStep == 0) {
      if (!_step1FormKey.currentState!.validate()) return;
      // create salon
      setState(() => _isLoading = true);
      try {
        await SalonService.createSalon(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          googleMapsUrl: _googleMapsController.text.trim(),
          speciality: _specialityController.text.trim(),
        );
        setState(() {
          _isLoading = false;
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } catch (error) {
        setState(() => _isLoading = false);
        _showError(error.toString());
      }
    } else if (_currentStep == 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      // Step 0 is creation, we don't let them go back to 0 once created
      if (_currentStep == 1) return;

      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isLoading = true);
    try {
      String? finalCoverUrl;
      if (_isUrlMode && _coverUrlController.text.isNotEmpty) {
        finalCoverUrl = _coverUrlController.text.trim();
      } else if (_selectedImageBase64 != null) {
        finalCoverUrl = 'data:image/jpeg;base64,$_selectedImageBase64';
      }

      await SalonService.updateSalonInfo(
        description: _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : null,
        contactPhone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        websiteUrl: _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
        coverImageUrl: finalCoverUrl,
      );

      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        title: Text(
          tr(context, 'salon_created_success_title'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        description: Text(
          tr(context, 'salon_created_success_desc'),
          style: const TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.successGreen,
        backgroundColor: AppColors.successGreen,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MainPage(initialIndex: 2),
          ),
          (route) => false,
        );
      }
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String text) {
    if (!mounted) return;
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      title: Text(
        tr(context, 'problem'),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      description: Text(text, style: const TextStyle(color: Colors.white)),
      primaryColor: AppColors.actionRed,
      backgroundColor: AppColors.actionRed,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: Text(
          tr(context, 'setup_salon'),
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        leading: _currentStep == 2
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _prevStep,
              )
            : const BackButton(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentStep == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentStep >= index
                          ? AppColors.primaryBlue
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // disable swipe
                children: [_buildStep1(), _buildStep2(), _buildStep3()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1: Identité
  // ---------------------------------------------------------------------------
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step1FormKey,
        child: Column(
          children: [
            const Icon(
              Icons.storefront,
              size: 70,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: 16),
            Text(
              tr(context, 'salon_identity'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(context, 'salon_identity_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            _buildInput(
              controller: _nameController,
              label: tr(context, 'salon_name_req'),
              hint: tr(context, 'salon_name_hint'),
              icon: Icons.title,
              validator: (v) => v == null || v.trim().isEmpty
                  ? tr(context, 'salon_name_validation')
                  : null,
            ),
            const SizedBox(height: 16),
            _buildInput(
              controller: _addressController,
              label: tr(context, 'address_req'),
              hint: tr(context, 'address_hint'),
              icon: Icons.location_on_outlined,
              validator: (v) => v == null || v.trim().length < 5
                  ? tr(context, 'address_validation')
                  : null,
            ),
            const SizedBox(height: 16),
            _buildInput(
              controller: _googleMapsController,
              label: tr(context, 'google_maps_optional'),
              hint: tr(context, 'google_maps_hint'),
              icon: Icons.map_outlined,
            ),
            const SizedBox(height: 16),
            _buildInput(
              controller: _specialityController,
              label: tr(context, 'speciality_optional'),
              hint: tr(context, 'speciality_hint'),
              icon: Icons.auto_awesome_outlined,
            ),
            const SizedBox(height: 32),

            _buildPrimaryButton(
              text: tr(context, 'next'),
              onPressed: _nextStep,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: Présentation
  // ---------------------------------------------------------------------------
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline,
            size: 70,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: 16),
          Text(
            tr(context, 'presentation_optional'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'presentation_desc'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),

          _buildInput(
            controller: _descController,
            label: tr(context, 'description_label'),
            hint: tr(context, 'description_hint'),
            icon: Icons.description_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildInput(
            controller: _phoneController,
            label: tr(context, 'contact_phone'),
            hint: tr(context, 'contact_phone_hint'),
            icon: Icons.phone_android_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildInput(
            controller: _websiteController,
            label: tr(context, 'website_label'),
            hint: tr(context, 'website_hint'),
            icon: Icons.language_outlined,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 32),

          _buildPrimaryButton(
            text: tr(context, 'next'),
            onPressed: () {
              FocusScope.of(context).unfocus();
              _nextStep();
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _nextStep,
            child: Text(
              tr(context, 'skip_step'),
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: Photo
  // ---------------------------------------------------------------------------
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.image_outlined,
            size: 70,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(height: 16),
          Text(
            tr(context, 'cover_photo'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'cover_photo_desc'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // Upload Box
          GestureDetector(
            onTap: () {
              if (!_isUrlMode) _pickImage();
            },
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
              ),
              child: _selectedImageBase64 != null && !_isUrlMode
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        base64Decode(_selectedImageBase64!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_a_photo_outlined,
                          size: 40,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tr(context, 'upload_photo_prompt'),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  tr(context, 'or_use_link'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),

          // URL input
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  controller: _coverUrlController,
                  hint: "https://...",
                  icon: Icons.link,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isUrlMode = true);
                  FocusScope.of(context).unfocus();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isUrlMode
                      ? AppColors.primaryBlue
                      : Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                child: Text(
                  tr(context, 'use_url'),
                  style: TextStyle(
                    color: _isUrlMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),

          _buildPrimaryButton(
            text: tr(context, 'finish'),
            onPressed: () {
              FocusScope.of(context).unfocus();
              _finishOnboarding();
            },
            isLoading: _isLoading,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _finishOnboarding,
            child: Text(
              tr(context, 'skip_step'),
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widgets helpers
  // ---------------------------------------------------------------------------

  Widget _buildInput({
    required TextEditingController controller,
    String? label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: maxLines == 1
                ? Icon(icon, color: AppColors.primaryBlue, size: 20)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Icon(icon, color: AppColors.primaryBlue, size: 20),
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            errorStyle: const TextStyle(color: Colors.red),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
