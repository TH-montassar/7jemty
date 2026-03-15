import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';

class FirebasePhoneVerificationSession {
  const FirebasePhoneVerificationSession({
    this.verificationId,
    this.resendToken,
    this.instantCredential,
  });

  final String? verificationId;
  final int? resendToken;
  final PhoneAuthCredential? instantCredential;

  bool get isInstantVerified => instantCredential != null;
}

class FirebasePhoneAuthService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static bool get shouldUseFirebasePhoneAuth => kReleaseMode && !kIsWeb;

  static String normalizePhoneNumber(String phoneNumber) {
    final normalized = phoneNumber.replaceAll(RegExp(r'\s+'), '').trim();
    if (normalized.startsWith('+')) return normalized;
    if (normalized.startsWith('216')) return '+$normalized';
    return '+216$normalized';
  }

  static Future<FirebasePhoneVerificationSession> startVerification(
    String phoneNumber, {
    int? forceResendingToken,
  }) async {
    final completer = Completer<FirebasePhoneVerificationSession>();

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: normalizePhoneNumber(phoneNumber),
      forceResendingToken: forceResendingToken,
      verificationCompleted: (credential) {
        if (!completer.isCompleted) {
          completer.complete(
            FirebasePhoneVerificationSession(instantCredential: credential),
          );
        }
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) {
          completer.completeError(
            Exception(error.message ?? 'Echec de verification du numero'),
          );
        }
      },
      codeSent: (verificationId, resendToken) {
        if (!completer.isCompleted) {
          completer.complete(
            FirebasePhoneVerificationSession(
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) {
          completer.complete(
            FirebasePhoneVerificationSession(verificationId: verificationId),
          );
        }
      },
    );

    return completer.future;
  }

  static Future<String> exchangeCredentialForBackendToken({
    required FirebasePhoneVerificationSession session,
    String? smsCode,
  }) async {
    final PhoneAuthCredential credential;

    if (session.instantCredential != null) {
      credential = session.instantCredential!;
    } else {
      if (session.verificationId == null || smsCode == null || smsCode.isEmpty) {
        throw Exception('Code SMS manquant.');
      }

      credential = PhoneAuthProvider.credential(
        verificationId: session.verificationId!,
        smsCode: smsCode,
      );
    }

    UserCredential? userCredential;
    try {
      userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseToken = await userCredential.user?.getIdToken(true);

      if (firebaseToken == null) {
        throw Exception('Firebase ID token introuvable.');
      }

      final backendResult = await AuthService.verifyFirebaseToken(firebaseToken);
      return backendResult['phoneVerificationToken'] as String;
    } on FirebaseAuthException catch (error) {
      throw Exception(error.message ?? 'Code SMS invalide');
    } finally {
      if (userCredential?.user != null) {
        await _firebaseAuth.signOut();
      }
    }
  }
}
