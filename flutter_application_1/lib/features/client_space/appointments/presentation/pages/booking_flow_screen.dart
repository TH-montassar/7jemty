import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/translation_service.dart';
import '../../../../../services/salon_service.dart';
import '../../../../../services/appointment_service.dart';
import '../../../../../services/auth_service.dart';
import '../../../main_layout/presentation/pages/client_main_layout.dart';

class BookingFlowScreen extends StatefulWidget {
  final int salonId;

  const BookingFlowScreen({super.key, required this.salonId});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  bool _isLoading = true;
  bool _isCheckingAvailability = false;
  bool _isSubmitting = false;
  String _salonName = "";
  Map<String, dynamic>? _currentUser;

  // Data from API
  List<dynamic> _services = [];
  List<dynamic> _professionals = [];
  List<Map<String, dynamic>> _availableSlots = [];

  // User Selections
  List<int> _selectedServiceIds = [];
  int? _selectedBarberId;
  int _selectedDateIndex = 0;
  String? _selectedTime;

  // Date management
  late List<DateTime> _dates;
  late DateTime _startDate;
  late ScrollController _dateScrollController;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null).then((_) {
      if (mounted) setState(() {});
    });

    _startDate = DateTime.now();
    _dates = List.generate(
      30,
      (index) => _startDate.add(Duration(days: index)),
    );
    _dateScrollController = ScrollController();

    _checkCurrentUser();
    _fetchSalonDetails();
  }

  Future<void> _checkCurrentUser() async {
    try {
      final userData = await AuthService.getMe();
      if (mounted) {
        setState(() {
          _currentUser = userData;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentUser = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchSalonDetails() async {
    try {
      final salonData = await SalonService.getSalonById(widget.salonId);

      // Extract services and employees if available, else empty lists
      setState(() {
        _services = salonData['services'] ?? [];
        _professionals =
            (salonData['employees'] as List?)?.map((e) {
              return {...e as Map<String, dynamic>, 'isPatron': false};
            }).toList() ??
            [];

        // Add Patron to professional list if present in data
        if (salonData['patron'] != null) {
          _professionals.insert(0, {
            'id': salonData['patron']['id'] ?? salonData['patronId'],
            'name': (salonData['patron']['name'] ?? 'Patron') + ' (Patron)',
            'imageUrl': salonData['patron']['imageUrl'] ?? '',
            'isPatron': true,
          });
        }
        _isLoading = false;
      });

      _fetchAvailability(); // Fetch initial availability for the current day
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text('Erreur'),
          description: const Text(
            "Impossible de charger les détails du salon.",
          ),
        );
      }
    }
  }

  Future<void> _fetchAvailability() async {
    if (_selectedServiceIds.isEmpty && _services.isNotEmpty) {
      // It's better to fetch availability without serviceIds strictly blocking,
      // since the backend only strictly needs salonId and date.
    }

    setState(() {
      _isCheckingAvailability = true;
      _selectedTime = null; // Reset time when date or barber changes
    });

    try {
      final formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(_dates[_selectedDateIndex]);
      final slots = await AppointmentService.getAvailability(
        salonId: widget.salonId,
        date: formattedDate,
        barberId: _selectedBarberId,
        serviceIds: _selectedServiceIds,
      );

      setState(() {
        _availableSlots = slots;
        _isCheckingAvailability = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingAvailability = false;
          _availableSlots = [];
        });
      }
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner au moins un service."),
        ),
      );
      return;
    }
    if (_selectedBarberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner un coiffeur.")),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez choisir une heure de rendez-vous."),
        ),
      );
      return;
    }

    if (_currentUser == null) {
      _showGuestAuthDialog();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(_dates[_selectedDateIndex]);

      final matchingProfessionals = _professionals.where(
        (p) => p['id'] == _selectedBarberId,
      );
      final selectedProfessional = matchingProfessionals.isNotEmpty
          ? matchingProfessionals.first
          : null;
      final String targetType =
          (selectedProfessional != null &&
              selectedProfessional['isPatron'] == true)
          ? 'PATRON'
          : 'EMPLOYEE';

      await AppointmentService.createAppointment(
        salonId: widget.salonId,
        barberId: _selectedBarberId!,
        date: formattedDate,
        time: _selectedTime!,
        serviceIds: _selectedServiceIds,
        targetType: targetType,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: const Text('Rendez-vous confirmé! ✅'),
          description: const Text("Votre réservation a été créée avec succès."),
          autoCloseDuration: const Duration(seconds: 4),
        );

        // Navigate to the Appointments tab (index 1)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const ClientMainLayout(initialIndex: 1),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text('Erreur de réservation'),
          description: Text(e.toString()),
          autoCloseDuration: const Duration(seconds: 5),
        );
      }
    }
  }

  void _showGuestAuthDialog() {
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    bool isPhoneChecked = false;
    bool phoneExists = false;
    bool dialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(tr(context, 'login_to_book')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                enabled: !isPhoneChecked || !phoneExists,
                decoration: InputDecoration(
                  labelText: tr(context, 'phone_number'),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
              if (isPhoneChecked && phoneExists) ...[
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: tr(context, 'password'),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: dialogLoading ? null : () => Navigator.pop(context),
              child: Text(tr(context, 'cancel')),
            ),
            ElevatedButton(
              onPressed: dialogLoading
                  ? null
                  : () async {
                      if (phoneController.text.trim().length != 8) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Le numéro doit comporter 8 chiffres",
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (!isPhoneChecked || !phoneExists) {
                        // Étape 1 : Vérifier si le numéro existe
                        setDialogState(() => dialogLoading = true);
                        try {
                          final exists = await AuthService.checkPhone(
                            phoneController.text,
                          );

                          if (exists) {
                            // Demander le mot de passe
                            setDialogState(() {
                              isPhoneChecked = true;
                              phoneExists = true;
                              dialogLoading = false;
                            });
                          } else {
                            // Création automatique si le numéro n'existe pas
                            final phone = phoneController.text;
                            final generatedName =
                                "Client ${phone.substring(phone.length > 4 ? phone.length - 4 : 0)}";

                            await AuthService.registerUser(
                              fullName: generatedName,
                              phoneNumber: phone,
                              password:
                                  phone, // Mot de passe = numéro par défaut
                            );

                            final result = await AuthService.loginUser(
                              phoneNumber: phone,
                              password: phone,
                            );

                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString(
                              'jwt_token',
                              result['data']['token'],
                            );

                            await _checkCurrentUser();
                            if (mounted) {
                              Navigator.pop(context);
                              _submitBooking();
                            }
                          }
                        } catch (e) {
                          setDialogState(() => dialogLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceAll('Exception: ', ''),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        // Étape 2 : L'utilisateur existe, on tente de se connecter
                        if (passwordController.text.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Le mot de passe doit comporter au moins 6 caractères",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => dialogLoading = true);
                        try {
                          final result = await AuthService.loginUser(
                            phoneNumber: phoneController.text,
                            password: passwordController.text,
                          );

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                            'jwt_token',
                            result['data']['token'],
                          );

                          await _checkCurrentUser();
                          if (mounted) {
                            Navigator.pop(context);
                            _submitBooking();
                          }
                        } catch (e) {
                          setDialogState(() => dialogLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceAll('Exception: ', ''),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: dialogLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      (isPhoneChecked && phoneExists)
                          ? tr(context, 'login')
                          : tr(context, 'next'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double get _totalPrice {
    double total = 0.0;
    for (var svc in _services) {
      if (_selectedServiceIds.contains(svc['id'])) {
        total += (svc['price'] ?? 0).toDouble();
      }
    }
    return total;
  }

  int get _totalDuration {
    int total = 0;
    for (var svc in _services) {
      if (_selectedServiceIds.contains(svc['id'])) {
        total += (svc['durationMinutes'] ?? 30) as int;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Prendre RDV - $_salonName",
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Services Section ---
                  _buildSectionTitle("1. Choisissez vos services"),
                  if (_services.isEmpty)
                    const Text(
                      "Aucun service disponible",
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ..._services.map(
                      (svc) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          svc['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("${svc['durationMinutes'] ?? 30} min"),
                        secondary: Text(
                          "${svc['price'] ?? 0} TND",
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: _selectedServiceIds.contains(svc['id']),
                        activeColor: AppColors.primaryBlue,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedServiceIds.add(svc['id']);
                            } else {
                              _selectedServiceIds.remove(svc['id']);
                            }
                          });
                          _fetchAvailability(); // Re-fetch to apply duration limits
                        },
                      ),
                    ),
                  const SizedBox(height: 25),

                  // --- Professional Section ---
                  _buildSectionTitle("2. Choisissez le professionnel"),
                  _buildBarberSelection(),
                  const SizedBox(height: 25),

                  // --- Date Section ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle("3. Date & Heure"),
                      IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.calendar_month,
                          color: AppColors.primaryBlue,
                        ),
                        onPressed: _openCalendarPicker,
                      ),
                    ],
                  ),
                  _buildDateSelection(),
                  const SizedBox(height: 15),

                  // --- Time Slots Section ---
                  if (_isCheckingAvailability)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    )
                  else if (_availableSlots.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          "Aucun horaire disponible pour cette date.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    _buildTimeSlots(),

                  const SizedBox(
                    height: 120,
                  ), // Bottom padding for checkout bar
                ],
              ),
            ),
      bottomNavigationBar: _isLoading ? null : _buildCheckoutBar(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildBarberSelection() {
    if (_professionals.isEmpty) {
      return const Text(
        "Aucun professionnel trouvé. Mettez à jour le salon.",
        style: TextStyle(color: Colors.grey),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _professionals.length,
        itemBuilder: (context, index) {
          final p = _professionals[index];
          final isSelected = _selectedBarberId == p['id'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedBarberId = p['id']);
              _fetchAvailability(); // Re-fetch availability for the specific barber
            },
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          (p['imageUrl'] != null &&
                              p['imageUrl'].toString().isNotEmpty)
                          ? NetworkImage(p['imageUrl'])
                          : null,
                      child:
                          (p['imageUrl'] == null ||
                              p['imageUrl'].toString().isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p['name'] ?? 'Inconnu',
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? AppColors.primaryBlue : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateSelection() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        controller: _dateScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = _selectedDateIndex == index;

          String dayName = DateFormat('EEE', 'fr_FR').format(date);
          String dayNumber = date.day.toString();

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDateIndex = index);
              _fetchAvailability();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 70,
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : Colors.grey.shade200,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${dayName[0].toUpperCase()}${dayName.substring(1)}",
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    dayNumber,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlots() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(_availableSlots.length, (index) {
        final slotData = _availableSlots[index];
        final String slot = slotData['time'];
        final bool isAvailable = slotData['available'] ?? false;
        final isSelected = _selectedTime == slot;

        return GestureDetector(
          onTap: isAvailable
              ? () => setState(() => _selectedTime = slot)
              : null,
          child: Opacity(
            opacity: isAvailable ? 1.0 : 0.4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue
                    : (isAvailable ? Colors.white : Colors.grey[200]),
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                slot,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isAvailable ? AppColors.textDark : Colors.grey[600]),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  decoration: isAvailable
                      ? TextDecoration.none
                      : TextDecoration.lineThrough,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _openCalendarPicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dates[_selectedDateIndex],
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        int foundIndex = _dates.indexWhere(
          (d) =>
              d.year == pickedDate.year &&
              d.month == pickedDate.month &&
              d.day == pickedDate.day,
        );

        if (foundIndex != -1) {
          _selectedDateIndex = foundIndex;
          _dateScrollController.animateTo(
            foundIndex * 80.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          _startDate = pickedDate;
          _dates = List.generate(
            30,
            (index) => _startDate.add(Duration(days: index)),
          );
          _selectedDateIndex = 0;
          _dateScrollController.jumpTo(0);
        }
      });
      _fetchAvailability();
    }
  }

  Widget _buildCheckoutBar() {
    bool canConfirm =
        _selectedServiceIds.isNotEmpty &&
        _selectedBarberId != null &&
        _selectedTime != null &&
        !_isSubmitting;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  "$_totalPrice TND",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  "$_totalDuration min",
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: canConfirm ? _submitBooking : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canConfirm
                    ? AppColors.primaryBlue
                    : Colors.grey[300],
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: canConfirm ? 5 : 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Réserver",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
