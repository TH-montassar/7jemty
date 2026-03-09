import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'signIn.dart';
import 'package:hjamty/features/auth/data/auth_service.dart';
import 'package:toastification/toastification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hjamty/features/patron_space/main_page.dart';
import 'package:hjamty/features/patron_space/create_salon_screen.dart';
import 'package:hjamty/features/admin_space/presentation/pages/admin_main_screen.dart';
import 'package:hjamty/features/patron_space/employee/pages/presentation/employee_main_layout.dart';
import 'package:hjamty/features/client_space/main_layout/presentation/pages/client_main_layout.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isPatron = false;

  Future<void> _handleRegister() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(context, 'passwords_do_not_match'),
            style: const TextStyle(color: AppColors.bgColor),
          ),
          backgroundColor: AppColors.actionRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.registerUser(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        role: _isPatron ? 'PATRON' : 'CLIENT',
      );

      // Ba3d l'inscription, na5dhou l'token w l'user ml base de donnees
      final token = result['data']['token'];
      final userRole = result['data']['user']['role'];
      final hasSalon = result['data']['user']['hasSalon'] ?? false;

      // Nsobba fi SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      await prefs.setString('user_role', userRole);

      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter, // تطلع من الفوق
        autoCloseDuration: const Duration(seconds: 4),
        title: const Text(
          'Jawwek mriguel 🎉',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        description: Text(
          _isPatron
              ? tr(context, 'welcome_patron')
              : tr(
                  context,
                  'welcome_client',
                  args: [_nameController.text.trim()],
                ),
          style: const TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.successGreen, // لونك المزيان
        backgroundColor: AppColors.successGreen,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        showProgressBar: false,
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;

        // Kif l'Login bedhabt, thezzou lil page mte3ou
        if (userRole == 'PATRON') {
          if (hasSalon == true) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainPage()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateSalonScreen(),
              ),
              (route) => false,
            );
          }
        } else if (userRole == 'ADMIN') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminMainScreen()),
            (route) => false,
          );
        } else if (userRole == 'EMPLOYEE') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const EmployeeMainLayout()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const ClientMainLayout(),
            ), // Na77it ClientHomePage, 7attit ClientMainLayout li fih l'BottomNav
            (route) => false,
          );
        }
      });
    } catch (error) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter, // تطلع من الفوق
        autoCloseDuration: const Duration(seconds: 4),
        title: const Text(
          'Mochkla',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        description: Text(
          error.toString(),
          style: const TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.actionRed, // لونك المزيان
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

  // ما تنساش تفسخ الـ Controllers كي تخرج من الشاشة باش ما تاكلش الميموار
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF5F7FA), // The cooler pro background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SignInScreen()),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SelectionArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40), // Increased to avoid overlap
                    // Logo
                    Center(
                      child: Image.asset('assets/images/logo.png', height: 120),
                    ),
                    const SizedBox(height: 30),

                    // Titre
                    Text(
                      tr(context, 'sign_up_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr(context, 'join_7jemty_enjoy_services'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Nom Complet
                    _buildTextField(
                      controller: _nameController, // ربطنا الـ Controller
                      hintText: tr(context, 'full_name'),
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 20),

                    // Numéro de téléphone
                    _buildTextField(
                      controller: _phoneController, // ربطنا الـ Controller
                      hintText: tr(context, 'phone_number_label'),
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return tr(context, 'field_required');
                        }
                        if (value.trim().length != 8 ||
                            int.tryParse(value.trim()) == null) {
                          return tr(context, 'phone_must_be_8_digits');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Mot de passe
                    _buildTextField(
                      controller: _passwordController, // ربطنا الـ Controller
                      hintText: tr(context, 'password_short'),
                      icon: Icons.lock_outline_rounded,
                      keyboardType: TextInputType.visiblePassword,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onTogglePassword: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr(context, 'field_required');
                        }
                        if (value.length < 6) {
                          return tr(context, 'password_must_be_6_chars');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Confirmer Mot de passe
                    _buildTextField(
                      controller:
                          _confirmPasswordController, // ربطنا الـ Controller
                      hintText: tr(context, 'confirm_password_hint'),
                      icon: Icons.lock_outline_rounded,
                      keyboardType: TextInputType.visiblePassword,
                      isPassword: true,
                      obscureText: _obscureConfirmPassword,
                      onTogglePassword: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr(context, 'field_required');
                        }
                        if (value.length < 6) {
                          return tr(context, 'password_must_be_6_chars');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // 👇 Checkbox متع الحجام (PATRON)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isPatron
                              ? AppColors.primaryBlue
                              : Colors.transparent,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04), // Soft pro shadow
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          tr(context, 'i_am_salon_owner'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textDark,
                          ),
                        ),
                        subtitle: Text(
                          tr(context, 'check_this_to_add_salon'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: _isPatron,
                        activeColor: AppColors.primaryBlue,
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        onChanged: (bool? value) {
                          setState(() {
                            _isPatron = value ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Bouton Inscription
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: _isLoading ? [] : [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _handleRegister(); // 👈 نعيطو للفانكشن هوني
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          disabledBackgroundColor: Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                tr(context, 'create_account'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Lien vers Connexion
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${tr(context, 'already_have_account')} ",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignInScreen(),
                              ),
                            );
                          },
                          child: Text(
                            tr(context, 'connect_action'),
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
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
    required TextInputType keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Soft pro shadow
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller, // 👈 ربطناه هوني
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.black38, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: AppColors.primaryBlue, size: 22),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.black38,
                    size: 22,
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
        validator:
            validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return tr(context, 'field_required');
              }
              return null;
            },
      ),
    );
  }
}
