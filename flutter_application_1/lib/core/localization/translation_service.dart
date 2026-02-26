import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String translate(String key) {
    if (_dictionaries.containsKey(_currentLang) &&
        _dictionaries[_currentLang]!.containsKey(key)) {
      return _dictionaries[_currentLang]![key]!;
    }
    // Fallback if missing
    return _dictionaries['tn']![key] ?? key;
  }

  // --- DICTIONARIES ---
  static const Map<String, Map<String, String>> _dictionaries = {
    'tn': {
      // General
      'home': 'Accueil',
      'language': 'Lougha',
      'notifications': 'Notificatiounet',
      'help_support': 'Mo3awna',
      'terms': 'A7kem amma',
      'logout': 'Okhrej',
      'cancel': 'Batel',
      'confirm': 'Aked',

      // Client Home Page
      'search_placeholder': 'Lawej aala salon, service...',
      'greeting': 'Ahla 👋',
      'top_categories': 'Chnowa tawa?',
      'near_you': '9rab lik',
      'top_rated': 'A7sen les Salons 👑',

      // Appointments
      'my_appointments': 'Rendez-vous Mte3i',
      'upcoming': 'Jeyin',
      'history': 'Lqdom',
      'next_appointment': 'Rendez-vous jey',
      'see_on_map': 'Chouf fil map 🗺️',
      'in_time': 'Mazel',
      'status_confirmed': 'M\'akd',
      'status_completed': 'Kmal',
      'status_cancelled': 'Tbatel',

      // Booking
      'book_appointment': 'A7jez RDV',
      'choose_barber': '1. Ekhtar l\'hajem mte3ek',
      'date_time': '2. Nharetha wel wa9t',
      'haircut_model': '3. Modele mtaa hjema (Optionnel)',
      'add_photo_gallery': 'Zid taswira (mel galerie)',
      'photo_added_success': 'Taswira tzadit mriguel',
      'confirm_appointment': 'Confirmer le Rendez-vous',
      'pay_on_site': 'Khalles sur place',
      'appointment_confirmed': 'Rendez-vous t\'aked ✅',
      'any_barber': 'Ay wahed',

      // Profile
      'my_profile': 'Profil Mte3i',
      'loyalty_cards': 'Kwaret Fidélité 🎁',
      'my_activities': 'Activités Mte3i',
      'product_orders': 'Comandeti mtaa Produits',
      'favorite_salons': 'Salouneti l\'Favoris',
      'settings': 'Parametres',
    },
    'en': {
      // General
      'home': 'Home',
      'language': 'Language',
      'notifications': 'Notifications',
      'help_support': 'Help & Support',
      'terms': 'Terms & Conditions',
      'logout': 'Logout',
      'cancel': 'Cancel',
      'confirm': 'Confirm',

      // Client Home Page
      'search_placeholder': 'Search for salon, service...',
      'greeting': 'Hello 👋',
      'top_categories': 'Quick Categories',
      'near_you': 'Near You',
      'top_rated': 'Top Rated Salons 👑',

      // Appointments
      'my_appointments': 'My Appointments',
      'upcoming': 'Upcoming',
      'history': 'History',
      'next_appointment': 'Next Appointment',
      'see_on_map': 'See on Map 🗺️',
      'in_time': 'In',
      'status_confirmed': 'Confirmed',
      'status_completed': 'Completed',
      'status_cancelled': 'Cancelled',

      // Booking
      'book_appointment': 'Book Appointment',
      'choose_barber': '1. Choose your barber',
      'date_time': '2. Date & Time',
      'haircut_model': '3. Haircut Model (Optional)',
      'add_photo_gallery': 'Add photo (from gallery)',
      'photo_added_success': 'Photo added successfully',
      'confirm_appointment': 'Confirm Appointment',
      'pay_on_site': 'Pay on site',
      'appointment_confirmed': 'Appointment confirmed ✅',
      'any_barber': 'Any barber',

      // Profile
      'my_profile': 'My Profile',
      'loyalty_cards': 'Loyalty Cards 🎁',
      'my_activities': 'My Activities',
      'product_orders': 'Product Orders',
      'favorite_salons': 'Favorite Salons',
      'settings': 'Settings',
    },
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
String tr(BuildContext context, String key) {
  return TranslationProvider.of(context).translate(key);
}
