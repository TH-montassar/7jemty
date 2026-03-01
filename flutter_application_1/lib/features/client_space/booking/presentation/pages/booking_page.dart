import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../../../core/constants/app_colors.dart';
import '../widgets/booking_summary_card.dart';
import '../widgets/checkout_bottom_bar.dart';
import '../../../../../core/localization/translation_service.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../services/appointment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingPage extends StatefulWidget {
  final String serviceName;
  final String servicePrice;
  final String serviceDuration;

  // 👈 Sala7na l'constructeur houni (na7ina 'required String price' e-zzeyda)
  const BookingPage({
    super.key,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDuration,
    required String price,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  // --- State Variables ---
  int _selectedBarberIndex = 0;
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = -1;
  bool _isPhotoUploaded = false;
  bool _isLoading = false;
  Map<String, dynamic>? _currentUser;

  // Availability Slots State
  bool _isLoadingSlots = false;
  List<String> _availableSlotStrings = [];

  // Date variables
  late List<DateTime> _dates;
  late DateTime _startDate;
  late ScrollController _dateScrollController;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null).then((_) {
      setState(() {});
    });
    _startDate = DateTime.now();
    _dates = List.generate(
      30,
      (index) => _startDate.add(Duration(days: index)),
    );
    _dateScrollController = ScrollController();
    _checkCurrentUser();
    _fetchAvailableSlots();
  }

  Future<void> _fetchAvailableSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _selectedTimeIndex = -1; // Reset selected time when slots change
    });

    try {
      final selectedDate = _dates[_selectedDateIndex];
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

      // Calculate barberId (0 means 'Any Barber', so we pass null)
      final barberId = _selectedBarberIndex == 0 ? null : _selectedBarberIndex;

      final slots = await AppointmentService.getAvailability(
        salonId: 1, // Currently hardcoded to salon 1 based on previous logic
        date: dateStr,
        barberId: barberId,
        serviceIds: [
          1,
        ], // Assume service ID 1 for now (should ideally be passed dynamically if possible)
      );

      if (mounted) {
        setState(() {
          _availableSlotStrings = slots;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
        // Optional: Show error snackbar
      }
    }
  }

  Future<void> _checkCurrentUser() async {
    try {
      final userData = await AuthService.getMe();
      setState(() {
        _currentUser = userData['data'];
      });
    } catch (e) {
      // User not logged in, that's fine
    }
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  // --- Mock Data ---
  List<Map<String, String>> get _barbers {
    return [
      {'name': tr(context, 'any_barber'), 'img': ''},
      {
        'name': 'Sami',
        'img':
            'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=100&q=80',
      },
      {
        'name': 'Ahmed',
        'img':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=100&q=80',
      },
    ];
  }

  // Generate static daily intervals 08:00 - 17:00
  List<Map<String, dynamic>> get _dailySlots {
    const times = [
      '08:00',
      '08:30',
      '09:00',
      '09:30',
      '10:00',
      '10:30',
      '11:00',
      '11:30',
      '12:00',
      '12:30',
      '13:00',
      '13:30',
      '14:00',
      '14:30',
      '15:00',
      '15:30',
      '16:00',
      '16:30',
    ];

    return times
        .map(
          (timeStr) => {
            'time': timeStr,
            'available': _availableSlotStrings.contains(timeStr),
          },
        )
        .toList();
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
          tr(context, 'book_appointment'),
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Résumé du service (Karta mfar9a fi fichier wa7adha)
            BookingSummaryCard(
              serviceName: widget.serviceName,
              serviceDuration: widget.serviceDuration,
              servicePrice: widget.servicePrice,
            ),
            const SizedBox(height: 30),

            // Étape 1: Choix Coiffeur
            _buildSectionTitle(tr(context, 'choose_barber')),
            _buildBarberSelection(),
            const SizedBox(height: 30),

            // Étape 2: Date & Heure
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle(tr(context, 'date_time')),
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.calendar_month,
                    color: AppColors.primaryBlue,
                  ),
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _dates[_selectedDateIndex],
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors
                                  .primaryBlue, // header background color
                              onPrimary: Colors.white, // header text color
                              onSurface: AppColors.textDark, // body text color
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (pickedDate != null) {
                      setState(() {
                        // Check if the picked date is already in our generated 30 days list
                        int foundIndex = _dates.indexWhere(
                          (d) =>
                              d.year == pickedDate.year &&
                              d.month == pickedDate.month &&
                              d.day == pickedDate.day,
                        );

                        if (foundIndex != -1) {
                          _selectedDateIndex = foundIndex;
                          // Scroll to that index
                          _dateScrollController.animateTo(
                            foundIndex * 80.0, // approx item width + margin
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          // Regenerate list starting from that month/date if it's too far in
                          _startDate = pickedDate;
                          _dates = List.generate(
                            30,
                            (index) => _startDate.add(Duration(days: index)),
                          );
                          _selectedDateIndex = 0;
                          _dateScrollController.jumpTo(0);
                        }
                        _selectedTimeIndex = -1; // Reset time
                      });
                      _fetchAvailableSlots();
                    }
                  },
                ),
              ],
            ),
            _buildDateSelection(),
            const SizedBox(height: 15),
            _buildTimeSlots(),
            const SizedBox(height: 30),

            // Étape 3: Upload Photo
            _buildSectionTitle(tr(context, 'haircut_model')),
            _buildPhotoUpload(),
            const SizedBox(height: 100),
          ],
        ),
      ),

      // 4. Bottom Bar (Mfar9a fi fichier wa7adha)
      // Nesta3mlou bottomNavigationBar 5ir men bottomSheet bech to93ed dima fixe louta
      bottomNavigationBar: CheckoutBottomBar(
        serviceName: widget.serviceName,
        servicePrice: widget.servicePrice,
        isLoading: _isLoading,
        canConfirm: _selectedTimeIndex != -1 && !_isLoading,
        onConfirm: _handleBooking,
      ),
    );
  }

  Future<void> _handleBooking() async {
    if (_selectedTimeIndex == -1) return;

    if (_currentUser == null) {
      _showGuestAuthDialog();
      return;
    }

    _createAppointment();
  }

  void _showGuestAuthDialog() {
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLogin = true;
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
                decoration: InputDecoration(
                  labelText: tr(context, 'phone_number'),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: tr(context, 'password'),
                  helperText: !isLogin
                      ? tr(context, 'guest_password_hint')
                      : null,
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              if (!isLogin) ...[
                const SizedBox(height: 10),
                Text(
                  tr(context, 'auto_account_creation_info'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                      if (phoneController.text.isEmpty ||
                          passwordController.text.isEmpty)
                        return;

                      setDialogState(() => dialogLoading = true);
                      try {
                        Map<String, dynamic> result;
                        if (isLogin) {
                          try {
                            result = await AuthService.loginUser(
                              phoneNumber: phoneController.text,
                              password: passwordController.text,
                            );
                          } catch (e) {
                            // If login fails, check if we should try register (guest flow)
                            if (e.toString().contains('not found')) {
                              setDialogState(() {
                                isLogin = false;
                                dialogLoading = false;
                              });
                              return;
                            }
                            rethrow;
                          }
                        } else {
                          result = await AuthService.registerUser(
                            fullName:
                                "Client ${phoneController.text.substring(phoneController.text.length - 4)}",
                            phoneNumber: phoneController.text,
                            password: passwordController.text,
                          );
                          // Automatic login after register
                          result = await AuthService.loginUser(
                            phoneNumber: phoneController.text,
                            password: passwordController.text,
                          );
                        }

                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('jwt_token', result['token']);

                        await _checkCurrentUser();
                        if (mounted) {
                          Navigator.pop(context);
                          _createAppointment();
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setDialogState(() => dialogLoading = false);
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
                      isLogin
                          ? tr(context, 'login')
                          : tr(context, 'create_account'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAppointment() async {
    setState(() => _isLoading = true);
    try {
      final selectedDate = _dates[_selectedDateIndex];
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final dynamicSlots = _dailySlots;
      final timeStr = dynamicSlots[_selectedTimeIndex]['time'];

      await AppointmentService.createAppointment(
        salonId: 1, // Need to pass actual salonId
        barberId: _selectedBarberIndex, // Need actual barber ID
        date: dateStr,
        time: timeStr,
        serviceIds: [1], // Need actual service IDs
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${tr(context, 'appointment_confirmed')} ✅"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // 🧩 BUILDERS INTERNES
  // ==========================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 5,
      ), // reduced bottom padding since date row adjusts it
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
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _barbers.length,
        itemBuilder: (context, index) {
          final b = _barbers[index];
          final isSelected = _selectedBarberIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedBarberIndex = index);
              _fetchAvailableSlots();
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
                      backgroundColor: Colors.white,
                      backgroundImage: b['img']!.isNotEmpty
                          ? NetworkImage(b['img']!)
                          : null,
                      child: b['img']!.isEmpty
                          ? const Icon(
                              Icons.groups,
                              size: 30,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    b['name']!,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? AppColors.primaryBlue : Colors.grey,
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

          // Custom mapping for tunisian dart, or we can just use generic fr format
          String dayName = DateFormat(
            'EEE',
            'fr_FR',
          ).format(date); // e.g. "lun.", "mar."
          String dayNumber = date.day.toString();

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDateIndex = index;
                _selectedTimeIndex = -1; // Reset time ki ybaddel n'har
              });
              _fetchAvailableSlots();
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
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
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
                    dayName.capitalize(),
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
    if (_isLoadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    final slots = _dailySlots;
    if (slots.isEmpty) {
      return const Center(
        child: Text("Aucun créneau disponible pour ce jour."),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(slots.length, (index) {
        final t = slots[index];
        final isAvailable = t['available'];
        final isSelected = _selectedTimeIndex == index;

        return GestureDetector(
          onTap: isAvailable
              ? () => setState(() => _selectedTimeIndex = index)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryBlue
                  : (isAvailable ? Colors.white : Colors.grey[200]),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryBlue
                    : (isAvailable ? Colors.grey[300]! : Colors.transparent),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              t['time'],
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isAvailable ? AppColors.textDark : Colors.grey),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                decoration: isAvailable ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPhotoUpload() {
    return GestureDetector(
      onTap: () {
        setState(() => _isPhotoUploaded = !_isPhotoUploaded);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 25),
        decoration: BoxDecoration(
          color: _isPhotoUploaded
              ? Colors.green.withValues(alpha: 0.05)
              : AppColors.primaryBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _isPhotoUploaded
                ? Colors.green
                : AppColors.primaryBlue.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _isPhotoUploaded ? Icons.check_circle : Icons.add_a_photo,
              color: _isPhotoUploaded ? Colors.green : AppColors.primaryBlue,
              size: 35,
            ),
            const SizedBox(height: 10),
            Text(
              _isPhotoUploaded
                  ? tr(context, 'photo_added_success')
                  : tr(context, 'add_photo_gallery'),
              style: TextStyle(
                color: _isPhotoUploaded ? Colors.green : AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension pour le majuscule
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
