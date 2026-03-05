import 'dart:io';

void main() {
  var keysTn = {
    'congrats': 'Mabrouk! 🎉',
    'save_success': 'Sauvegarde réussie',
    'image_uploaded': 'Tsawra tplodet!',
    'save_changes_instruction': 'Tawa a3mel "Sajjel el cambiamenti"',
    'upload_error_service': 'Erreur upload service',
    'upload_error_employee': 'Erreur upload employé',
    'missing_info': 'Maaloumet ne9sa',
    'name_price_time_required': 'Lesm, soum wel wa9t lezmin',
    'service_added': 'Zadna Service 🎉',
    'no_salon': 'Ma famma hatta salon.',
    'create_your_salon': 'Aamel salon mte3ek',
    'refresh': 'Tijdid',
    'team': 'Equipe',
    'working_hours': 'Horaires',
    'gallery': 'Galerie',
    'appointments': 'Rendez-vous',
    'coming_soon': '{0} (Coming soon)',
    'save_all': 'Sajjel kol chay',
    'my_salon_default': 'Mon Salon',
    'salon_cover_image': 'Taswira mta3 salon (cover)',
    'add_salon_image': 'Zid taswira mta3 el salon',
    'saving': 'Sajjel...',
    'uploaded_percent': '{0}% uploaded...',
    'upload_from_gallery': 'Plodi mel galerie',
    'or_put_image_url': 'aw 7ott URL mte3 taswira...',
    'identity': 'Identité',
    'salon_name': 'Esm e-salon',
    'salon_desc_hint': 'Chneya les services w el jaw fel salon?',
    'speciality_hint': 'ex: Coiffure, Barbershop...',
    'contact': 'Contact',
    'contact_number': 'Numéro de contact',
    'phone_hint': 'ex: 50 123 456',
    'location': 'Localisation',
    'full_address': 'Adresse complète',
    'social_networks': 'Réseaux sociaux',
    'close_btn': 'Saker',
    'add_service': 'Zid service',
    'new_service': 'SERVICE JDID',
    'put_image_url': 'Hott lien mtaa taswira...',
    'service_name': 'Esm el service',
    'service_name_hint': 'Esm service',
    'price_tnd': 'Soum (TND)',
    'price_hint': 'Soum',
    'time_min': 'Wa9t (bl minute)',
    'time_hint': 'Wa9t (min)',
    'service_desc_hint': 'Detail 3el service...',
    'save_service': 'Sajjel el service',
    'no_services_yet': 'Ma famma 7atta service ltawa.',
    'add_specialist': '+ Zid Spécialiste',
    'new_specialist': 'SPÉCIALISTE JDID',
    'specialist_name': 'Esm el spécialiste *',
    'name_lastname_hint': 'Esm w Lqeb',
    'phone_number_required': 'Noumro Téléphone *',
    'password_required': 'Kelmet essir *',
    'account_password_hint': 'Kelmet essir mte3 el compte',
  };

  var keysEn = {
    'congrats': 'Congratulations! 🎉',
    'save_success': 'Save successful',
    'image_uploaded': 'Image uploaded!',
    'save_changes_instruction': 'Now click "Save changes"',
    'upload_error_service': 'Service upload error',
    'upload_error_employee': 'Employee upload error',
    'missing_info': 'Missing information',
    'name_price_time_required': 'Name, price and time are required',
    'service_added': 'Service added 🎉',
    'no_salon': 'No salon found.',
    'create_your_salon': 'Create your salon',
    'refresh': 'Refresh',
    'team': 'Team',
    'working_hours': 'Working Hours',
    'gallery': 'Gallery',
    'appointments': 'Appointments',
    'coming_soon': '{0} (Coming soon)',
    'save_all': 'Save everything',
    'my_salon_default': 'My Salon',
    'salon_cover_image': 'Salon cover image',
    'add_salon_image': 'Add salon image',
    'saving': 'Saving...',
    'uploaded_percent': '{0}% uploaded...',
    'upload_from_gallery': 'Upload from gallery',
    'or_put_image_url': 'or put image URL...',
    'identity': 'Identity',
    'salon_name': 'Salon name',
    'salon_desc_hint': 'What are the services and atmosphere like?',
    'speciality_hint': 'ex: Hairdresser, Barbershop...',
    'contact': 'Contact',
    'contact_number': 'Contact number',
    'phone_hint': 'ex: 50 123 456',
    'location': 'Location',
    'full_address': 'Full address',
    'social_networks': 'Social networks',
    'close_btn': 'Close',
    'add_service': 'Add service',
    'new_service': 'NEW SERVICE',
    'put_image_url': 'Put image link...',
    'service_name': 'Service name',
    'service_name_hint': 'Service name',
    'price_tnd': 'Price (TND)',
    'price_hint': 'Price',
    'time_min': 'Time (in minutes)',
    'time_hint': 'Time (min)',
    'service_desc_hint': 'Details about the service...',
    'save_service': 'Save service',
    'no_services_yet': 'No services yet.',
    'add_specialist': '+ Add Specialist',
    'new_specialist': 'NEW SPECIALIST',
    'specialist_name': 'Specialist name *',
    'name_lastname_hint': 'First and Last name',
    'phone_number_required': 'Phone Number *',
    'password_required': 'Password *',
    'account_password_hint': 'Account password',
  };

  void injectToFile(String path, String pattern, Map<String, String> items) {
    var file = File(path);
    if (!file.existsSync()) return;
    var content = file.readAsStringSync();
    int idx = content.indexOf(pattern);
    if (idx != -1) {
      int insertIdx = content.lastIndexOf('}');
      if (insertIdx == -1) return;
      String newKeys = '';
      for (var k in items.keys) {
        if (!content.substring(idx, insertIdx).contains("'$k':")) {
          newKeys += "  '$k': '${items[k]!.replaceAll("'", "\\'")}',\n";
        }
      }
      content =
          content.substring(0, insertIdx) +
          newKeys +
          content.substring(insertIdx);
      file.writeAsStringSync(content);
    }
  }

  injectToFile(
    'lib/core/localization/langs/tn.dart',
    "const Map<String, String> tn = {",
    keysTn,
  );
  injectToFile(
    'lib/core/localization/langs/en.dart',
    "const Map<String, String> en = {",
    keysEn,
  );
}
