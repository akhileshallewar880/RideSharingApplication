import 'package:flutter/material.dart';
import '../../core/theme/admin_theme.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final IconData? icon;
  final bool isDangerous;
  final Widget? child;
  
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    required this.onConfirm,
    this.onCancel,
    this.confirmColor,
    this.icon,
    this.isDangerous = false,
    this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    final effectiveConfirmColor = confirmColor ?? 
        (isDangerous ? AdminTheme.errorColor : AdminTheme.primaryColor);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and Title
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: effectiveConfirmColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: effectiveConfirmColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Message
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AdminTheme.textSecondary,
                height: 1.5,
              ),
            ),
            
            // Custom child content
            if (child != null) ...[
              const SizedBox(height: 16),
              child!,
            ],
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                    onCancel?.call();
                  },
                  child: Text(cancelText),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: effectiveConfirmColor,
                  ),
                  child: Text(confirmText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Show confirmation dialog with simple confirm/cancel
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    IconData? icon,
    bool isDangerous = false,
    Widget? child,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: () {},
        confirmColor: confirmColor,
        icon: icon,
        isDangerous: isDangerous,
        child: child,
      ),
    );
  }
  
  /// Show delete confirmation
  static Future<bool?> showDelete({
    required BuildContext context,
    required String title,
    required String itemName,
    String? additionalMessage,
  }) {
    return show(
      context: context,
      title: title,
      message: 'Are you sure you want to delete "$itemName"? '
          '${additionalMessage ?? 'This action cannot be undone.'}',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      icon: Icons.delete_outline,
      isDangerous: true,
    );
  }
  
  /// Show approval confirmation
  static Future<bool?> showApprove({
    required BuildContext context,
    required String itemName,
    String? additionalMessage,
  }) {
    return show(
      context: context,
      title: 'Approve Request',
      message: 'Are you sure you want to approve "$itemName"? '
          '${additionalMessage ?? ''}',
      confirmText: 'Approve',
      cancelText: 'Cancel',
      icon: Icons.check_circle_outline,
      confirmColor: AdminTheme.successColor,
    );
  }
  
  /// Show rejection confirmation
  static Future<bool?> showReject({
    required BuildContext context,
    required String itemName,
    Widget? reasonField,
  }) {
    return show(
      context: context,
      title: 'Reject Request',
      message: 'Are you sure you want to reject "$itemName"?',
      confirmText: 'Reject',
      cancelText: 'Cancel',
      icon: Icons.cancel_outlined,
      isDangerous: true,
      child: reasonField,
    );
  }
}
