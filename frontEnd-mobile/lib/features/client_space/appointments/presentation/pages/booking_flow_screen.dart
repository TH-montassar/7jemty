import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/features/client_space/salon_profile/data/salon_service.dart';
import 'package:hjamty/features/client_space/appointments/data/appointment_service.dart';
import 'package:hjamty/features/auth/data/auth_service.dart';
import 'package:hjamty/features/client_space/appointments/presentation/pages/booking_success_screen.dart';
import 'package:hjamty/core/services/fcm_service.dart';
import 'package:hjamty/core/services/notification_service.dart';
import 'dart:async';

class BookingFlowScreen extends StatefulWidget {
  final int salonId;
  final List<int>? initialServiceIds;
  final int? initialBarberId;
  final bool lockInitialSelections;

  const BookingFlowScreen({
    super.key,
    required this.salonId,
    this.initialServiceIds,
    this.initialBarberId,
    this.lockInitialSelections = false,
  });

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  bool _isLoading = true;
  bool _isCheckingAvailability = false;
  bool _isSubmitting = false;
  String _salonName = "";
  String _salonAddress = "";
  Map<String, dynamic>? _currentUser;

  // Data from API
  List<dynamic> _services = [];
  List<dynamic> _professionals = [];
  List<Map<String, dynamic>> _availableSlots = [];

  // User Selections
  List<int> _selectedServiceIds = [];
  int? _selectedBarberId;
  bool _lockServicesForRebook = false;
  bool _lockBarberForRebook = false;
  int _selectedDateIndex = 0;
  String? _selectedTime;

  // Date management
  List<DateTime> _dates = [];
  late ScrollController _dateScrollController;
  bool _isFetchingDates = true;
  StreamSubscription<Map<String, dynamic>>? _fcmSubscription;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null).then((_) {
      if (mounted) setState(() {});
    });

    _dateScrollController = ScrollController();

    if (widget.initialServiceIds != null) {
      _selectedServiceIds = widget.initialServiceIds!.toSet().toList();
    }
    _lockServicesForRebook =
        widget.lockInitialSelections && _selectedServiceIds.isNotEmpty;

    _checkCurrentUser();
    _fetchSalonDetails();
    _setupFcmListener();
    NotificationService.listenToNotificationsStream();
  }

  void _setupFcmListener() {
    _fcmSubscription = FcmService.messageStream.listen((data) {
      if (data['type'] == 'AVAILABILITY_CHANGED' &&
          data['salonId']?.toString() == widget.salonId.toString()) {
        if (mounted) {
          _fetchAvailability();
        }
      }
    });
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
    _fcmSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchSalonDetails() async {
    try {
      final salonData = await SalonService.getSalonById(widget.salonId);

      // Extract services and employees if available, else empty lists
      setState(() {
        _salonName = salonData['name'] ?? "";
        _salonAddress = salonData['address'] ?? "";
        _services = salonData['services'] ?? [];
        _professionals =
            (salonData['employees'] as List?)?.map((e) {
              return {...e as Map<String, dynamic>, 'isPatron': false};
            }).toList() ??
            [];

        final availableServiceIds = _services
            .map<int?>((svc) {
              if (svc is! Map) return null;
              final rawId = svc['id'];
              if (rawId is int) return rawId;
              if (rawId is num) return rawId.toInt();
              return int.tryParse(rawId?.toString() ?? '');
            })
            .whereType<int>()
            .toSet();
        _selectedServiceIds = _selectedServiceIds
            .where(availableServiceIds.contains)
            .toList();

        if (_lockServicesForRebook && _selectedServiceIds.isEmpty) {
          _lockServicesForRebook = false;
        }

        // Add Patron to professional list if present in data
        if (salonData['patron'] != null) {
          _professionals.insert(0, {
            'id': salonData['patron']['id'] ?? salonData['patronId'],
            'name': (salonData['patron']['name'] ?? 'Patron') + ' (Patron)',
            'imageUrl': salonData['patron']['imageUrl'] ?? '',
            'isPatron': true,
          });
        }

        // Keep the same barber when coming from rebook (if still available)
        if (_professionals.isNotEmpty) {
          final hasInitialBarber =
              widget.initialBarberId != null &&
              _professionals.any((p) => p['id'] == widget.initialBarberId);

          _selectedBarberId = hasInitialBarber
              ? widget.initialBarberId
              : _professionals.first['id'];
          _lockBarberForRebook =
              widget.lockInitialSelections && hasInitialBarber;
        } else {
          _lockBarberForRebook = false;
        }
        _isLoading = false;
      });

      _fetchAvailableDates(); // Fetch available dates
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: Text(tr(context, 'error_title')),
          description: Text(tr(context, 'error_loading_salon_details')),
        );
      }
    }
  }

  Future<void> _fetchAvailableDates() async {
    setState(() => _isFetchingDates = true);

    try {
      final startDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final endDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().add(const Duration(days: 30)));

      final availableDateStrings = await AppointmentService.getAvailableDates(
        salonId: widget.salonId,
        startDate: startDate,
        endDate: endDate,
        barberId: _selectedBarberId,
        serviceIds: _selectedServiceIds,
      );

      final newDates = availableDateStrings
          .map((d) => DateTime.parse(d))
          .toList();

      if (mounted) {
        setState(() {
          DateTime? previouslySelectedDate;
          if (_dates.isNotEmpty &&
              _selectedDateIndex >= 0 &&
              _selectedDateIndex < _dates.length) {
            previouslySelectedDate = _dates[_selectedDateIndex];
          }

          _dates = newDates;
          _isFetchingDates = false;

          if (_dates.isEmpty) {
            _selectedDateIndex = -1;
            _availableSlots = [];
          } else {
            int newIndex = 0;
            if (previouslySelectedDate != null) {
              final p = previouslySelectedDate;
              final foundIndex = _dates.indexWhere(
                (d) => d.year == p.year && d.month == p.month && d.day == p.day,
              );
              if (foundIndex != -1) newIndex = foundIndex;
            }
            _selectedDateIndex = newIndex;
            _fetchAvailability();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingDates = false;
          _dates = [];
          _availableSlots = [];
        });
      }
    }
  }

  Future<void> _fetchAvailability() async {
    if (_dates.isEmpty ||
        _selectedDateIndex < 0 ||
        _selectedDateIndex >= _dates.length) {
      setState(() {
        _isCheckingAvailability = false;
        _availableSlots = [];
        _selectedTime = null; // Important: Clear selection if no dates/slots
      });
      return;
    }

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
        SnackBar(content: Text(tr(context, 'select_at_least_one_service'))),
      );
      return;
    }
    if (_selectedBarberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'select_barber_validation'))),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'select_time_validation'))),
      );
      return;
    }

    if (_currentUser == null) {
      _showGuestAuthDialog();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Safety check for date index
      if (_selectedDateIndex < 0 || _selectedDateIndex >= _dates.length) {
        throw Exception(tr(context, 'please_select_date_validation'));
      }

      final formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(_dates[_selectedDateIndex]);

      final matchingProfessionals = _professionals.where(
        (p) => p['id'] == _selectedBarberId,
      );
      final selectedProfessional = matchingProfessionals.isNotEmpty
          ? matchingProfessionals.first
          : null;

      // Store locally to prevent async race conditions with real-time FCM events
      final barberId = _selectedBarberId;
      final time = _selectedTime;

      if (barberId == null || time == null) {
        throw Exception(tr(context, 'missing_selection_error'));
      }

      final String targetType =
          (selectedProfessional != null &&
              selectedProfessional['isPatron'] == true)
          ? 'PATRON'
          : 'EMPLOYEE';

      await AppointmentService.createAppointment(
        salonId: widget.salonId,
        barberId: barberId,
        date: formattedDate,
        time: time,
        serviceIds: _selectedServiceIds,
        targetType: targetType,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: Text(tr(context, 'appointment_confirmed')),
          description: Text(tr(context, 'booking_created_success')),
          autoCloseDuration: const Duration(seconds: 4),
        );

        final List<Map<String, dynamic>> selectedServices = _services
            .where((s) => _selectedServiceIds.contains(s['id']))
            .map((s) => Map<String, dynamic>.from(s))
            .toList();

        // Capture current state values BEFORE executing the builder callback
        // This prevents race conditions where FCM callbacks reset variables like _selectedTime
        final String pushedSalonName = _salonName;
        final String pushedSalonAddress = _salonAddress;
        final DateTime pushedDate = _dates[_selectedDateIndex];
        final String pushedTime = time; // IMPORTANT: use local captured `time`
        final int pushedDuration = _totalDuration;
        final double pushedPrice = _totalPrice;
        final String pushedBarberName = selectedProfessional?['name'] ?? '';

        // Navigate to the Success Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingSuccessScreen(
              salonName: pushedSalonName,
              salonAddress: pushedSalonAddress,
              date: pushedDate,
              time: pushedTime,
              durationMinutes: pushedDuration,
              services: selectedServices,
              totalPrice: pushedPrice,
              barberName: pushedBarberName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: Text(tr(context, 'booking_error_title')),
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
    int timeLeft = 60;
    Timer? countdownTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          
          Future<void> submitGuestFlow() async {
            if (phoneController.text.trim().length != 8) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr(context, 'phone_must_be_8_digits')),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            if (!isPhoneChecked) {
              setDialogState(() => dialogLoading = true);
              try {
                final result = await AuthService.checkPhone(phoneController.text);
                final exists = result['exists'] == true;
                final role = result['role'];

                if (exists) {
                  if (role != null && role != 'CLIENT') {
                    setDialogState(() => dialogLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Ce numéro est réservé . Veuillez utiliser un autre numéro client."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setDialogState(() {
                    isPhoneChecked = true;
                    phoneExists = true;
                    dialogLoading = false;
                  });
                } else {
                  await AuthService.requestOtp(phoneController.text);

                  setDialogState(() {
                    isPhoneChecked = true;
                    phoneExists = false;
                    dialogLoading = false;
                    timeLeft = 60;
                  });
                  
                  countdownTimer?.cancel();
                  countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                    if (timeLeft > 0) {
                      setDialogState(() => timeLeft--);
                    } else {
                      timer.cancel();
                    }
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tr(context, 'sms_code_sent')),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                setDialogState(() => dialogLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } else {
              setDialogState(() => dialogLoading = true);
              try {
                if (phoneExists) {
                  if (passwordController.text.length < 6) {
                    setDialogState(() => dialogLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tr(context, 'password_must_be_6_chars')),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final result = await AuthService.loginUser(
                    phoneNumber: phoneController.text,
                    password: passwordController.text,
                  );

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('jwt_token', result['data']['token']);

                  await _checkCurrentUser();
                  if (mounted) {
                    countdownTimer?.cancel();
                    Navigator.pop(context);
                    await _fetchAvailability();
                    _submitBooking();
                  }
                } else {
                  if (passwordController.text.length != 6) {
                    setDialogState(() => dialogLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tr(context, 'code_must_be_6_digits')),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  await AuthService.verifyOtp(phoneController.text, passwordController.text);

                  final phone = phoneController.text;
                  final code = passwordController.text;
                  final generatedName = "Client ${phone.substring(phone.length > 4 ? phone.length - 4 : 0)}";

                  await AuthService.registerUser(
                    fullName: generatedName,
                    phoneNumber: phone,
                    password: code,
                  );

                  final result = await AuthService.loginUser(phoneNumber: phone, password: code);

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('jwt_token', result['data']['token']);

                  await _checkCurrentUser();
                  if (mounted) {
                    toastification.show(
                      context: context,
                      type: ToastificationType.success,
                      title: Text(tr(context, 'welcome_exclamation')),
                      description: Text(tr(context, 'account_verified_success')),
                      autoCloseDuration: const Duration(seconds: 4),
                    );
                    countdownTimer?.cancel();
                    Navigator.pop(context);
                    await _fetchAvailability();
                    _submitBooking();
                  }
                }
              } catch (e) {
                setDialogState(() => dialogLoading = false);
                passwordController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                if (isPhoneChecked) ...[
                  const SizedBox(height: 15),
                  TextField(
                    controller: passwordController,
                    obscureText: phoneExists,
                    keyboardType: phoneExists ? TextInputType.text : TextInputType.number,
                    maxLength: phoneExists ? null : 6,
                    onChanged: (value) {
                      if (!phoneExists && value.length == 6 && !dialogLoading) {
                        submitGuestFlow();
                      }
                    },
                    decoration: InputDecoration(
                      counterText: phoneExists ? null : "",
                      labelText: phoneExists ? tr(context, 'password') : 'Code SMS',
                      prefixIcon: phoneExists ? const Icon(Icons.lock) : const Icon(Icons.sms),
                    ),
                  ),
                  if (!phoneExists) ...[
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: timeLeft == 0 && !dialogLoading
                          ? () async {
                              setDialogState(() => dialogLoading = true);
                              try {
                                await AuthService.requestOtp(phoneController.text);
                                setDialogState(() {
                                  timeLeft = 60;
                                  dialogLoading = false;
                                });
                                countdownTimer?.cancel();
                                countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                                  if (timeLeft > 0) {
                                    setDialogState(() => timeLeft--);
                                  } else {
                                    timer.cancel();
                                  }
                                });
                              } catch (e) {
                                setDialogState(() => dialogLoading = false);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().replaceAll('Exception: ', '')),
                                    backgroundColor: AppColors.actionRed,
                                  ),
                                );
                              }
                            }
                          : null,
                      child: Text(
                        timeLeft > 0
                            ? tr(context, 'wait_before_resend', args: [timeLeft.toString()])
                            : tr(context, 'resend_code'),
                        style: TextStyle(
                          color: timeLeft > 0 ? Colors.grey : AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: dialogLoading ? null : () {
                  countdownTimer?.cancel();
                  Navigator.pop(context);
                },
                child: Text(tr(context, 'cancel')),
              ),
              ElevatedButton(
                onPressed: dialogLoading ? null : submitGuestFlow,
                child: dialogLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text((isPhoneChecked && phoneExists) ? tr(context, 'login') : tr(context, 'next')),
              ),
            ],
          );
        },
      ),
    );
  }

  double get _totalPrice {
    double total = 0.0;
    for (var svc in _services) {
      if (_selectedServiceIds.contains(svc['id'])) {
        final price = svc['price'];
        if (price is num) {
          total += price.toDouble();
        } else if (price is String) {
          total += double.tryParse(price) ?? 0.0;
        }
      }
    }
    return total;
  }

  int get _totalDuration {
    int total = 0;
    for (var svc in _services) {
      if (_selectedServiceIds.contains(svc['id'])) {
        final duration = svc['durationMinutes'];
        if (duration is num) {
          total += duration.toInt();
        } else if (duration is String) {
          total += int.tryParse(duration) ?? 30;
        } else {
          total += 30;
        }
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
          tr(context, 'book_appointment_for', args: [_salonName]),
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
                  _buildSectionTitle(tr(context, 'choose_your_services')),
                  if (_services.isEmpty)
                    Text(
                      tr(context, 'no_service_available'),
                      style: const TextStyle(color: Colors.grey),
                    )
                  else
                    ..._services.map(
                      (svc) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          svc['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          tr(
                            context,
                            'duration_min',
                            args: [(svc['durationMinutes'] ?? 30).toString()],
                          ),
                        ),
                        secondary: Text(
                          "${svc['price'] ?? 0} TND",
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: _selectedServiceIds.contains(svc['id']),
                        activeColor: AppColors.primaryBlue,
                        onChanged: _lockServicesForRebook
                            ? null
                            : (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedServiceIds.add(svc['id']);
                                  } else {
                                    _selectedServiceIds.remove(svc['id']);
                                  }
                                });
                                _fetchAvailableDates(); // Re-fetch to apply duration limits
                              },
                      ),
                    ),
                  const SizedBox(height: 25),

                  // --- Professional Section ---
                  _buildSectionTitle(tr(context, 'choose_professional_title')),
                  _buildBarberSelection(),
                  const SizedBox(height: 25),

                  // --- Date Section ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(tr(context, 'date_and_time_step')),
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
                  _isFetchingDates
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        )
                      : (_dates.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: Center(
                                  child: Text(
                                    tr(context, 'no_slots_available'),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : _buildDateSelection()),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          tr(context, 'no_slots_available'),
                          style: const TextStyle(color: Colors.grey),
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
      return Text(
        tr(context, 'no_professional_found_update'),
        style: const TextStyle(color: Colors.grey),
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
            onTap: _lockBarberForRebook
                ? null
                : () {
                    setState(() => _selectedBarberId = p['id']);
                    _fetchAvailableDates(); // Re-fetch availability for the specific barber
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
                    p['name'] ?? tr(context, 'unknown'),
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
    if (_dates.isEmpty) return;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dates[_selectedDateIndex >= 0 ? _selectedDateIndex : 0],
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      selectableDayPredicate: (DateTime day) {
        return _dates.any(
          (d) => d.year == day.year && d.month == day.month && d.day == day.day,
        );
      },
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
                Text(
                  tr(context, 'total'),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
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
                  : Text(
                      tr(context, 'reserve_btn'),
                      style: const TextStyle(
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
