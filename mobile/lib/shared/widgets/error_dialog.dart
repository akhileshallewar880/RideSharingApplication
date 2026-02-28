import 'package:flutter/material.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';

/// Maps common Firebase and server error codes to user-friendly messages.
class ErrorMessages {
  static String fromFirebaseCode(String? code, [String? fallback]) {
    switch (code) {
      case 'invalid-verification-code':
        return 'The OTP you entered is incorrect. Please check and try again.';
      case 'session-expired':
        return 'Your verification session has expired. Please request a new OTP.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a while before trying again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'missing-client-identifier':
        return 'App configuration error. Please reinstall or contact support.';
      case 'invalid-phone-number':
        return 'Please enter a valid phone number.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        return 'Phone sign-in is not enabled. Please contact support.';
      default:
        return fallback ?? 'Something went wrong. Please try again.';
    }
  }

  /// Interprets a raw error message (from server or catch block) into a
  /// user-friendly string.
  static String fromRawError(dynamic error) {
    final msg = error.toString().toLowerCase();

    if (msg.contains('socketexception') ||
        msg.contains('connection refused') ||
        msg.contains('network')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }
    if (msg.contains('timeout')) {
      return 'The request timed out. Please try again.';
    }
    if (msg.contains('500') || msg.contains('internal server error')) {
      return 'Server error. Our team has been notified. Please try again later.';
    }
    if (msg.contains('401') || msg.contains('unauthorized')) {
      return 'Authentication failed. Please log in again.';
    }
    if (msg.contains('403') || msg.contains('forbidden')) {
      return 'You don\'t have permission to perform this action.';
    }
    if (msg.contains('invalid') || msg.contains('wrong')) {
      return 'Invalid OTP. Please check and try again.';
    }
    if (msg.contains('expired')) {
      return 'Session expired. Please request a new OTP.';
    }
    return 'Something went wrong. Please try again.';
  }
}

/// Shows a premium, dismissible error popup dialog.
///
/// [context] – BuildContext
/// [title] – Dialog title (e.g. "Verification Failed")
/// [message] – User-friendly error description
/// [onDismiss] – Optional callback when user taps OK
void showErrorPopup(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onDismiss,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onDismiss?.call();
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.error,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}
