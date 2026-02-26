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
      'shop': 'Boutique',
      'appointments_short': 'RDV Mte3i',
      'products': 'Produits',
      'profile': 'Profil',
      'search_product': 'Lawwej 3la produit...',
      'category_all': 'Kol',
      'category_hair': 'Cha3r',
      'category_beard': 'Le7ya',
      'category_face': 'Wajh',
      'category_accessories': 'Accessoires',
      'added_to_cart': 'tzed lel panier 🛒',
      'appointments_warning_title': 'Rod belek',
      'appointments_cancel_confirm_msg': "Met'aked theb tbatel e-rendez-vous?

⚠️ Kan tbatel 3 marrat wra baadhom comptek yetbloka.",
      'back': 'Rjou3',
      'yes_cancel': 'Ey, Batel',
      'appointment_cancelled': 'Rendez-vous tbatel',
      'direction': 'Thneya',
      'leave_review': '⭐ Khali avis',
      'book_again': '↻ Aawed Ahjez',
      'cart_title': 'Mon Panier',
      'total_to_pay': 'Total à payer',
      'confirm_order': 'Valider la commande',
      'order_success': 'Commande validée avec succès 🎉',
      'empty_cart': 'Votre panier est vide',
      'back_to_shop': 'Retourner à la boutique',
      'brand_professional': 'Marque / Salon Professionnel',
      'description': 'Description',
      'usage_tips': "Conseils d'utilisation",
      'product_description_text': 'Ce produit professionnel est spécialement conçu pour offrir une tenue parfaite tout au long de la journée. Idéal pour tous les types de cheveux, il ne laisse pas de résidus et se lave facilement.',
      'usage_tip_line': 'Appliquer sur cheveux secs ou légèrement humides.',
      'add_to_cart': 'Ajouter au panier',
      'added_to_cart_success': 'Ajouté au panier avec succès 🛒',
      'review_comment_hint': 'Khali commentaire (optionnel)...',
      'review_sent': 'Avis tbaath mriguel! Aaychek 🎉',
      'send_review': "Abaath l'avis",
      'skip': 'Fout',
      'map_opening': 'Kaaed yhel fel map 🗺️',
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
      'shop': 'Shop',
      'appointments_short': 'My Appointments',
      'products': 'Products',
      'profile': 'Profile',
      'search_product': 'Search a product...',
      'category_all': 'All',
      'category_hair': 'Hair',
      'category_beard': 'Beard',
      'category_face': 'Face',
      'category_accessories': 'Accessories',
      'added_to_cart': 'added to cart 🛒',
      'appointments_warning_title': 'Warning',
      'appointments_cancel_confirm_msg': 'Are you sure you want to cancel this appointment?

⚠️ If you cancel 3 times in a row, your account may be blocked.',
      'back': 'Back',
      'yes_cancel': 'Yes, Cancel',
      'appointment_cancelled': 'Appointment cancelled',
      'direction': 'Direction',
      'leave_review': '⭐ Leave a review',
      'book_again': '↻ Book Again',
      'cart_title': 'My Cart',
      'total_to_pay': 'Total to pay',
      'confirm_order': 'Confirm order',
      'order_success': 'Order confirmed successfully 🎉',
      'empty_cart': 'Your cart is empty',
      'back_to_shop': 'Back to shop',
      'brand_professional': 'Professional Brand / Salon',
      'description': 'Description',
      'usage_tips': 'Usage tips',
      'product_description_text': 'This professional product is specially designed to provide perfect hold throughout the day. Ideal for all hair types, it leaves no residue and washes out easily.',
      'usage_tip_line': 'Apply to dry or slightly damp hair.',
      'add_to_cart': 'Add to cart',
      'added_to_cart_success': 'Added to cart successfully 🛒',
      'review_comment_hint': 'Leave a comment (optional)...',
      'review_sent': 'Review sent successfully! Thank you 🎉',
      'send_review': 'Send review',
      'skip': 'Skip',
      'map_opening': 'Opening map 🗺️',
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
