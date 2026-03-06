import 'package:hjamty/core/localization/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'signUp.dart';
import 'package:hjamty/features/auth/data/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hjamty/features/patron_space/main_page.dart';
import 'package:hjamty/features/client_space/main_layout/presentation/pages/client_main_layout.dart';
import 'package:hjamty/features/admin_space/presentation/pages/admin_main_screen.dart';
import 'package:hjamty/features/patron_space/employee/pages/presentation/employee_main_layout.dart';
import 'package:hjamty/features/patron_space/create_salon_screen.dart';

class SignInScreen extends StatefulWidget {
  final String? prefilledPhone;
  final String? prefilledPassword;
  const SignInScreen({super.key, this.prefilledPhone, this.prefilledPassword});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;

  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    // Houni nsobou l valeurs eli jewna mel register (ken famma)
    _phoneController = TextEditingController(text: widget.prefilledPhone ?? '');
    _passwordController = TextEditingController(
      text: widget.prefilledPassword ?? '',
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClientMainLayout(),
                ),
                (route) => false,
              );
            }
          },
        ),
      ),
      body: SafeArea(
        // ✅ 1. زدنا SelectionArea هوني باش تشد الباج الكل
        child: SelectionArea(
          child: SingleChildScrollView(
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
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 120, // Kif l'signUp
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Titre
                    const Text(
                      "Connecti",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Marhba bik marra okhra !",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 40),

                    // Numéro de téléphone
                    _buildTextField(
                      controller: _phoneController,
                      hintText: "Numrou Tlifoun",
                      icon: Icons.phone_android_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),

                    // Mot de passe
                    _buildTextField(
                      hintText: "Mot de passe",
                      controller: _passwordController,
                      icon: Icons.lock_outline,
                      keyboardType: TextInputType.visiblePassword,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onTogglePassword: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    // Mot de passe oublié ?
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Nsitt l'mot de passe ?",
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Bouton Connexion
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _isLoading = true;
                                });

                                try {
                                  final response = await AuthService.loginUser(
                                    phoneNumber: _phoneController.text.trim(),
                                    password: _passwordController.text,
                                  );

                                  // Backend yarja3 { success: true, data: { user: {...}, token: "..." } }
                                  final token = response['data']['token'];
                                  final userRole =
                                      response['data']['user']['role'];
                                  final hasSalon =
                                      response['data']['user']['hasSalon'] ??
                                      false;

                                  // Nsobba fi SharedPreferences
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setString('jwt_token', token);
                                  await prefs.setString('user_role', userRole);

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        tr(context, 'logged_in_successfully'),
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );

                                  // ken role PATRON yemchi ll CreateSalonScreen
                                  if (userRole == 'PATRON') {
                                    if (hasSalon == true) {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const MainPage(),
                                        ),
                                        (route) => false,
                                      );
                                    } else {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CreateSalonScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    }
                                  } else if (userRole == 'ADMIN') {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AdminMainScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  } else if (userRole == 'EMPLOYEE') {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const EmployeeMainLayout(),
                                      ),
                                      (route) => false,
                                    );
                                  } else {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ClientMainLayout(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceAll(
                                          'Exception: ',
                                          '',
                                        ),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
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
                          : const Text(
                              "Connecti",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                    const SizedBox(height: 30),

                    // Lien vers Inscription
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Ma aandekch compte ? ",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            // نمشيو لصفحة SignUp
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Aamel compte",
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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

  // نفس الـ Widget متاع الـ TextFields في l'SignUp
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required TextInputType keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(12), // equivalent l withOpacity(0.05)
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: AppColors.primaryBlue),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Hedha lezem taamrou';
          }
          return null;
        },
      ),
    );
  }
}
