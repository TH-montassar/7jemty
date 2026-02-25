import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/features/admin_space/presentation/pages/admin_home_page.dart';
import 'package:hjamty/features/client_space/main_layout/presentation/pages/client_main_layout.dart';
import 'package:hjamty/features/patron_space/employee/pages/presentation/employee_home_page.dart';
import 'package:hjamty/features/patron_space/main_page.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // 1. متغيرات التحكم في الأنيماسيون (État initial)
  double _opacity = 0.0; // الشفافية تبدا 0 (مخفي تماماً)
  double _scale = 0.5; // الحجم يبدا 50% (صغير)
  double _textOpacity = 0.0; // شفافية النص

  @override
  void initState() {
    super.initState();
    // نعيطو للفونكسيون اللي تنظم الوقت
    _startSplashSequence();
  }

  // فونكسيون async باش الكود يتقرى سطر بسطر (أنظف برشا)
  Future<void> _startSplashSequence() async {
    // 2. تريغر الأنيماسيون (Entrance Animation)
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() {
      _opacity = 1.0;
      _scale = 1.0;
    });

    // نظهروا النص "7jemty" بعد شوية
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _textOpacity = 1.0;
    });

    // 3. الأنيماسيون متع الخروج (Exit Animation - Shrink & Fade Out)
    await Future.delayed(const Duration(milliseconds: 1700));
    if (!mounted) return;
    setState(() {
      _opacity = 0.0;
      _scale = 0.0; // يصغار
      _textOpacity = 0.0;
    });

    // 4. المؤقت للانتقال للصفحة التالية (Navigation Logic)
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final userRole = prefs.getString('user_role');

    Widget nextPage;

    if (token == null || userRole == null) {
      // mouch connecte -> Home Client
      nextPage = const ClientMainLayout();
    // ignore: dead_code
    } else {
      if (userRole == 'PATRON') {
        // connecte w 7ajem -> Espace 7ajem
        nextPage = const MainPage();
      } else if (userRole == 'ADMIN') {
        nextPage = const AdminHomePage();
      } else if (userRole == 'EMPLOYEE') {
        nextPage = const ClientMainLayout();
      } else {
        // connecte w client -> Home Client
        nextPage = const ClientMainLayout();
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor, // استعملنا لون الخلفية متع المشروع
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // اللوغو مع الأنيماسيون
            AnimatedOpacity(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              opacity: _opacity,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                scale: _scale,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 180,
                ), // اللوغو متاعك رجع لبلاصتو
              ),
            ),
            const SizedBox(height: 20),
            // النص "7jemty"
            AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _textOpacity,
              child: const Text(
                "7jemty", // صلحتلك الـ d الزايدة برك
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
