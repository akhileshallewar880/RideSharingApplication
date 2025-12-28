import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../theme/admin_theme.dart';

class ToastHelper {
  static final FToast _fToast = FToast();
  
  static void init(BuildContext context) {
    _fToast.init(context);
  }
  
  /// Show success toast
  static void success(String message, {BuildContext? context}) {
    if (context != null) {
      _fToast.init(context);
    }
    
    _fToast.showToast(
      child: _buildToastContainer(
        message: message,
        icon: Icons.check_circle,
        backgroundColor: AdminTheme.successColor,
      ),
      gravity: ToastGravity.TOP_RIGHT,
      toastDuration: const Duration(seconds: 3),
    );
  }
  
  /// Show error toast
  static void error(String message, {BuildContext? context}) {
    if (context != null) {
      _fToast.init(context);
    }
    
    _fToast.showToast(
      child: _buildToastContainer(
        message: message,
        icon: Icons.error,
        backgroundColor: AdminTheme.errorColor,
      ),
      gravity: ToastGravity.TOP_RIGHT,
      toastDuration: const Duration(seconds: 4),
    );
  }
  
  /// Show warning toast
  static void warning(String message, {BuildContext? context}) {
    if (context != null) {
      _fToast.init(context);
    }
    
    _fToast.showToast(
      child: _buildToastContainer(
        message: message,
        icon: Icons.warning,
        backgroundColor: AdminTheme.warningColor,
      ),
      gravity: ToastGravity.TOP_RIGHT,
      toastDuration: const Duration(seconds: 3),
    );
  }
  
  /// Show info toast
  static void info(String message, {BuildContext? context}) {
    if (context != null) {
      _fToast.init(context);
    }
    
    _fToast.showToast(
      child: _buildToastContainer(
        message: message,
        icon: Icons.info,
        backgroundColor: AdminTheme.infoColor,
      ),
      gravity: ToastGravity.TOP_RIGHT,
      toastDuration: const Duration(seconds: 3),
    );
  }
  
  /// Build toast container widget
  static Widget _buildToastContainer({
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Remove all toasts
  static void removeAll() {
    _fToast.removeQueuedCustomToasts();
  }
}
