import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Phone Authentication Service
/// Handles phone number verification using Firebase Authentication
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int? _resendToken;
  
  /// Send OTP to phone number using Firebase
  /// Returns true if OTP sent successfully
  Future<bool> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    Function(PhoneAuthCredential credential)? onAutoVerify,
  }) async {
    try {
      print('📱 Firebase: Sending OTP to $phoneNumber');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        
        // Auto-verification (Android only)
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('✅ Firebase: Auto-verification completed');
          if (onAutoVerify != null) {
            onAutoVerify(credential);
          } else {
            // Sign in automatically
            try {
              await _auth.signInWithCredential(credential);
              print('✅ Firebase: Auto sign-in successful');
            } catch (e) {
              print('❌ Firebase: Auto sign-in failed: $e');
            }
          }
        },
        
        // Verification failed
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Firebase: Verification failed: ${e.code} - ${e.message}');
          
          String errorMessage = 'Verification failed';
          
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number format';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many requests. Please try again later';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Please try again later';
              break;
            default:
              errorMessage = e.message ?? 'Verification failed';
          }
          
          onError(errorMessage);
        },
        
        // Code sent successfully
        codeSent: (String verificationId, int? resendToken) {
          print('✅ Firebase: Code sent - Verification ID: $verificationId');
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        
        // Auto-retrieval timeout
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏱️ Firebase: Auto-retrieval timeout');
        },
        
        // Use resend token for resending OTP
        forceResendingToken: _resendToken,
      );
      
      return true;
    } catch (e) {
      print('❌ Firebase: Error sending OTP: $e');
      onError('Failed to send OTP: ${e.toString()}');
      return false;
    }
  }
  
  /// Verify OTP code
  /// Returns UserCredential if successful, null otherwise
  Future<UserCredential?> verifyOtp({
    required String verificationId,
    required String smsCode,
    required Function(String error) onError,
  }) async {
    try {
      print('🔐 Firebase: Verifying OTP code');
      
      // Create credential
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      print('✅ Firebase: OTP verified successfully');
      print('   User ID: ${userCredential.user?.uid}');
      print('   Phone: ${userCredential.user?.phoneNumber}');
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase: Verification failed: ${e.code} - ${e.message}');
      
      String errorMessage = 'Verification failed';
      
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP code. Please check and try again';
          break;
        case 'invalid-verification-id':
          errorMessage = 'Session expired. Please request a new OTP';
          break;
        case 'session-expired':
          errorMessage = 'OTP expired. Please request a new one';
          break;
        case 'code-expired':
          errorMessage = 'OTP code expired. Please request a new one';
          break;
        default:
          errorMessage = e.message ?? 'Verification failed';
      }
      
      onError(errorMessage);
      return null;
    } catch (e) {
      print('❌ Firebase: Error verifying OTP: $e');
      onError('Failed to verify OTP: ${e.toString()}');
      return null;
    }
  }
  
  /// Get current Firebase user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  /// Get Firebase ID token for backend authentication
  Future<String?> getIdToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      print('❌ Firebase: Error getting ID token: $e');
      return null;
    }
  }
  
  /// Sign out from Firebase
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('✅ Firebase: Signed out successfully');
    } catch (e) {
      print('❌ Firebase: Error signing out: $e');
    }
  }
  
  /// Resend OTP
  Future<bool> resendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    print('🔄 Firebase: Resending OTP');
    return await sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }
}
