import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hjamty/features/splash/presentation/pages/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter/services.dart';
import 'package:hjamty/core/localization/translation_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:hjamty/core/services/fcm_service.dart';

// Service de traduction global
final translationService = TranslationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FcmService.initialize();
    } else {
      debugPrint("Skipping FCM initialization on Web to prevent startup hang.");
    }
  } catch (e) {
    debugPrint("Failed to initialize Firebase: $e");
  }

  try {
    // Lock orientation to Portrait
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    debugPrint("Failed to set preferred orientations: $e");
  }

  try {
    await initializeDateFormatting('fr_FR', null);
  } catch (e) {
    debugPrint("Failed to initialize date formatting: $e");
  }

  runApp(
    TranslationProvider(notifier: translationService, child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '7jemty APPP .',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
