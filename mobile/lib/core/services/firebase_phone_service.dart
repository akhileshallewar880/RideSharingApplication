import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service for Firebase phone authentication
class FirebasePhoneService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  ConfirmationResult? _webConfirmationResult; // For web-based verification

  /// Send OTP to phone number
  /// 
  /// Callbacks:
  /// - [onCodeSent]: Called when SMS is sent successfully with verificationId
  /// - [onVerificationFailed]: Called when verification fails
  /// - [onCodeAutoRetrievalTimeout]: Called when auto-retrieval times out
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException error) onVerificationFailed,
    Function(PhoneAuthCredential credential)? onAutoVerificationCompleted,
    Function(String verificationId)? onCodeAutoRetrievalTimeout,
    int timeoutDuration = 60,
  }) async {
    try {
      print('📱 Firebase: Sending OTP to $phoneNumber (Platform: ${kIsWeb ? "Web" : "Mobile"})');
      
      if (kIsWeb) {
        // Web-specific flow using reCAPTCHA
        print('🌐 Using web-based phone authentication with reCAPTCHA');
        try {
          _webConfirmationResult = await _auth.signInWithPhoneNumber(
            phoneNumber,
          );
          print('✅ Firebase: reCAPTCHA verified, OTP sent');
          // Use a dummy verificationId for web
          onCodeSent('web-verification', null);
        } catch (e) {
          print('🔴 Firebase Web: Error: $e');
          if (e is FirebaseAuthException) {
            onVerificationFailed(e);
          } else {
            onVerificationFailed(FirebaseAuthException(
              code: 'web-error',
              message: 'Failed to send OTP on web: $e',
            ));
          }
        }
      } else {
        // Mobile-specific flow
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: Duration(seconds: timeoutDuration),
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-verification on Android (instant verification or auto-retrieval)
            print('✅ Firebase: Auto-verification completed');
            if (onAutoVerificationCompleted != null) {
              onAutoVerificationCompleted(credential);
            }
          },
          verificationFailed: (FirebaseAuthException error) {
            print('🔴 Firebase: Verification failed: ${error.message}');
            print('🔴 Error Code: ${error.code}');
            onVerificationFailed(error);
          },
          codeSent: (String verificationId, int? resendToken) {
            print('✅ Firebase: OTP sent successfully');
            print('   Verification ID: ${verificationId.substring(0, 20)}...');
            onCodeSent(verificationId, resendToken);
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            print('⏱️ Firebase: Auto-retrieval timeout');
            if (onCodeAutoRetrievalTimeout != null) {
              onCodeAutoRetrievalTimeout(verificationId);
            }
          },
        );
      }
    } catch (e) {
      print('🔴 Firebase: Error sending OTP: $e');
      rethrow;
    }
  }

  /// Verify OTP code
  /// 
  /// Returns UserCredential on success
  /// Throws FirebaseAuthException on failure
  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      print('🔐 Firebase: Verifying OTP... (Platform: ${kIsWeb ? "Web" : "Mobile"})');
      
      UserCredential userCredential;
      
      if (kIsWeb) {
        // Web-specific verification using confirmation result
        if (_webConfirmationResult == null) {
          throw FirebaseAuthException(
            code: 'no-confirmation',
            message: 'No confirmation result available. Please request OTP again.',
          );
        }
        print('🌐 Verifying OTP using web confirmation result');
        userCredential = await _webConfirmationResult!.confirm(otp);
      } else {
        // Mobile-specific verification
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: otp,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }
      
      print('✅ Firebase: OTP verification successful');
      print('   User ID: ${userCredential.user?.uid}');
      print('   Phone: ${userCredential.user?.phoneNumber}');
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('🔴 Firebase: OTP verification failed');
      print('🔴 Error Code: ${e.code}');
      print('🔴 Error Message: ${e.message}');
      
      // Provide user-friendly error messages
      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP code. Please check and try again.';
          break;
        case 'session-expired':
          errorMessage = 'OTP has expired. Please request a new one.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later.';
          break;
        case 'quota-exceeded':
          errorMessage = 'SMS quota exceeded. Please try again later.';
          break;
        default:
          errorMessage = e.message ?? 'Verification failed. Please try again.';
      }
      
      throw FirebaseAuthException(
        code: e.code,
        message: errorMessage,
      );
    } catch (e) {
      print('🔴 Firebase: Unexpected error: $e');
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Resend OTP with resend token
  Future<void> resendOtp({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException error) onVerificationFailed,
  }) async {
    await sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
    );
  }

  /// Sign out from Firebase
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('✅ Firebase: Signed out successfully');
    } catch (e) {
      print('⚠️ Firebase: Sign out error: $e');
    }
  }

  /// Get current Firebase user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Check if user is signed in with Firebase
  bool isSignedIn() {
    return _auth.currentUser != null;
  }

  /// Get Firebase ID token for backend authentication
  Future<String?> getIdToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        return token;
      }
      return null;
    } catch (e) {
      print('⚠️ Firebase: Error getting ID token: $e');
      return null;
    }
  }
}
