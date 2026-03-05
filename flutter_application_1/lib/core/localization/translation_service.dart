import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'langs/tn.dart';
import 'langs/en.dart';

class TranslationService extends ChangeNotifier {
  static const String keyLang = "app_lang";
  String _currentLang = 'tn'; // Default language

  String get currentLang => _currentLang;

  TranslationService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLang = prefs.getString(keyLang) ?? 'tn';
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyLang, langCode);
    _currentLang = langCode;
    notifyListeners();
  }

  String translate(String key, {List<String>? args}) {
    String text = key;
    if (_dictionaries.containsKey(_currentLang) &&
        _dictionaries[_currentLang]!.containsKey(key)) {
      text = _dictionaries[_currentLang]![key]!;
    } else {
      // Fallback if missing
      text = _dictionaries['tn']![key] ?? key;
    }

    if (args != null && args.isNotEmpty) {
      for (int i = 0; i < args.length; i++) {
        text = text.replaceAll('{$i}', args[i]);
      }
    }
    return text;
  }

  // --- DICTIONARIES ---
  static const Map<String, Map<String, String>> _dictionaries = {
    'tn': tn,
    'en': en,
  };
}

// -------------------------------------------------------------
// Provider global bch l'application lkol ta3ref l'changement mta3 lougha
// -------------------------------------------------------------
class TranslationProvider extends InheritedNotifier<TranslationService> {
  const TranslationProvider({
    super.key,
    required TranslationService notifier,
    required super.child,
  }) : super(notifier: notifier);

  static TranslationService of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TranslationProvider>()!
        .notifier!;
  }
}

// Helper function bech nsahel 3lik l'khedma: tr(context, 'key')
String tr(BuildContext context, String key, {List<String>? args}) {
  return TranslationProvider.of(context).translate(key, args: args);
}
