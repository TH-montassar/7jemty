import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';
import 'package:hjamty/core/localization/translation_service.dart';
import 'package:hjamty/core/services/fcm_service.dart';
import 'package:hjamty/features/auth/data/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

Future<bool?> showGuestAuthDialog(BuildContext context) {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool isPhoneChecked = false;
  bool phoneExists = false;
  bool dialogLoading = false;
  int timeLeft = 60;
  Timer? countdownTimer;

  void showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString().replaceAll('Exception: ', '')),
        backgroundColor: AppColors.actionRed,
      ),
    );
  }

  void startCountdown(StateSetter setDialogState) {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setDialogState(() => timeLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> resendOtp(StateSetter setDialogState) async {
    setDialogState(() => dialogLoading = true);
    try {
      await AuthService.requestOtp(phoneController.text);
      setDialogState(() {
        timeLeft = 60;
        dialogLoading = false;
      });
      startCountdown(setDialogState);
    } catch (error) {
      setDialogState(() => dialogLoading = false);
      if (!context.mounted) return;
      showError(error);
    }
  }

  Future<void> persistLogin(Map<String, dynamic> result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', result['data']['token']);
    await FcmService.syncCurrentTokenWithBackend();
  }

  Future<void> verifyOtpAndCreateAccount() async {
    final verifyResult = await AuthService.verifyOtp(
      phoneController.text,
      passwordController.text,
    );

    final phone = phoneController.text;
    final code = passwordController.text;
    final verificationToken =
        verifyResult['phoneVerificationToken']?.toString();
    if (verificationToken == null || verificationToken.isEmpty) {
      throw Exception('Verification du numero invalide.');
    }

    final generatedName =
        'Client ${phone.substring(phone.length > 4 ? phone.length - 4 : 0)}';

    await AuthService.registerUser(
      fullName: generatedName,
      phoneNumber: phone,
      password: code,
      phoneVerificationToken: verificationToken,
    );

    final loginResult = await AuthService.loginUser(
      phoneNumber: phone,
      password: code,
    );
    await persistLogin(loginResult);
  }

  // Shared guest auth flow for booking screens.
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        Future<void> submitGuestFlow() async {
          if (phoneController.text.trim().length != 8) {
            showError(tr(context, 'phone_must_be_8_digits'));
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
                  showError(
                    'Ce numero est reserve. Veuillez utiliser un autre numero client.',
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
                startCountdown(setDialogState);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr(context, 'sms_code_sent')),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            } catch (error) {
              setDialogState(() => dialogLoading = false);
              showError(error);
            }
            return;
          }

          setDialogState(() => dialogLoading = true);
          try {
            if (phoneExists) {
              if (passwordController.text.length < 6) {
                setDialogState(() => dialogLoading = false);
                showError(tr(context, 'password_must_be_6_chars'));
                return;
              }

              final loginResult = await AuthService.loginUser(
                phoneNumber: phoneController.text,
                password: passwordController.text,
              );
              await persistLogin(loginResult);
              countdownTimer?.cancel();
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              }
              return;
            }

            if (passwordController.text.length != 6) {
              setDialogState(() => dialogLoading = false);
              showError(tr(context, 'code_must_be_6_digits'));
              return;
            }

            await verifyOtpAndCreateAccount();
            if (context.mounted) {
              toastification.show(
                context: context,
                type: ToastificationType.success,
                title: Text(tr(context, 'welcome_exclamation')),
                description: Text(tr(context, 'account_verified_success')),
                autoCloseDuration: const Duration(seconds: 4),
              );
            }

            countdownTimer?.cancel();
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext, true);
            }
          } catch (error) {
            setDialogState(() => dialogLoading = false);
            passwordController.clear();
            showError(error);
          }
        }

        final isOtpStep = isPhoneChecked && !phoneExists;
        final isLoginStep = isPhoneChecked && phoneExists;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isOtpStep ? tr(context, 'verify_phone') : tr(context, 'login_to_book'),
            textAlign: TextAlign.center,
          ),
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
              if (isOtpStep) ...[
                const SizedBox(height: 16),
                Text(
                  '${tr(context, 'otp_sent_to')} ${phoneController.text.trim()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  onChanged: (value) {
                    if (value.length == 6 && !dialogLoading) {
                      submitGuestFlow();
                    }
                  },
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    hintStyle: TextStyle(color: Colors.grey.shade300),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: timeLeft == 0 && !dialogLoading
                      ? () => resendOtp(setDialogState)
                      : null,
                  child: Text(
                    timeLeft > 0
                        ? tr(
                            context,
                            'wait_before_resend',
                            args: [timeLeft.toString()],
                          )
                        : tr(context, 'resend_code'),
                    style: TextStyle(
                      color: timeLeft > 0 ? Colors.grey : AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              if (isLoginStep) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  keyboardType: TextInputType.text,
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
              onPressed: dialogLoading
                  ? null
                  : () {
                      countdownTimer?.cancel();
                      Navigator.pop(dialogContext, false);
                    },
              child: Text(tr(context, 'cancel')),
            ),
            ElevatedButton(
              onPressed: dialogLoading ? null : submitGuestFlow,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
                      !isPhoneChecked
                          ? tr(context, 'next')
                          : (phoneExists
                                ? tr(context, 'login')
                                : tr(context, 'verify')),
                    ),
            ),
          ],
        );
      },
    ),
  );
}
