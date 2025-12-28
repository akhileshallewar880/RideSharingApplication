import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';

/// Custom bottom sheet wrapper
class CustomBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool isDismissible;
  final bool enableDrag;
  final double? height;
  
  const CustomBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.isDismissible = true,
    this.enableDrag = true,
    this.height,
  });
  
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
    double? height,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomBottomSheet(
        title: title,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        height: height,
        child: child,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.borderRadiusTopXL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          if (enableDrag)
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark 
                    ? AppColors.darkBorder 
                    : AppColors.lightBorder,
                borderRadius: AppSpacing.borderRadiusFull,
              ),
            ),
          
          // Title
          if (title != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: TextStyles.headingMedium,
                    ),
                  ),
                  if (isDismissible)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),
          
          // Content
          Flexible(
            child: child,
          ),
        ],
      ),
    ).animate().slideY(
      begin: 1,
      end: 0,
      duration: 300.ms,
      curve: Curves.easeOut,
    );
  }
}

/// Slide up modal with overlay
class SlideUpModal extends StatelessWidget {
  final Widget child;
  final String? title;
  
  const SlideUpModal({
    super.key,
    required this.child,
    this.title,
  });
  
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (context) => SlideUpModal(
        title: title,
        child: child,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          borderRadius: AppSpacing.borderRadiusXL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: TextStyles.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            child,
          ],
        ),
      ).animate().scale(
        duration: 200.ms,
        curve: Curves.easeOut,
      ).fade(),
    );
  }
}

/// Custom alert dialog
class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  
  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });
  
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => CustomAlertDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDestructive: isDestructive,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLG,
      ),
      title: Text(
        title,
        style: TextStyles.headingMedium,
      ),
      content: Text(
        message,
        style: TextStyles.bodyMedium,
      ),
      actions: [
        if (cancelText != null || onCancel != null)
          TextButton(
            onPressed: () {
              onCancel?.call();
              Navigator.of(context).pop(false);
            },
            child: Text(cancelText ?? 'Cancel'),
          ),
        TextButton(
          onPressed: () {
            onConfirm?.call();
            Navigator.of(context).pop(true);
          },
          style: TextButton.styleFrom(
            foregroundColor: isDestructive ? AppColors.error : AppColors.primaryYellow,
          ),
          child: Text(confirmText ?? 'OK'),
        ),
      ],
    );
  }
}
