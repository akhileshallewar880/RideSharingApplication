import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';

/// Primary button component with animations
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  
  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.height,
    this.backgroundColor,
    this.textColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? AppSpacing.buttonHeightLG,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primaryYellow,
          foregroundColor: textColor ?? AppColors.primaryDark,
          disabledBackgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder 
              : AppColors.lightBorder,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMD,
          ),
          elevation: AppSpacing.elevationSM,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppSpacing.iconSM),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    text,
                    style: TextStyles.buttonLarge.copyWith(
                      color: textColor ?? AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).shimmer(
      duration: 2000.ms,
      color: Colors.white.withOpacity(0.3),
    ).then().shake(
      hz: 0,
      curve: Curves.easeInOut,
    );
  }
}

/// Secondary button with outline style
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? height;
  
  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.height,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? AppSpacing.buttonHeightLG,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryYellow,
          side: const BorderSide(
            color: AppColors.primaryYellow,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMD,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppSpacing.iconSM),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    text,
                    style: TextStyles.buttonLarge.copyWith(
                      color: AppColors.primaryYellow,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Icon button with rounded background
class RoundedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  
  const RoundedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = AppSpacing.iconLG,
  });
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? 
          (Theme.of(context).brightness == Brightness.dark ? AppColors.darkCardBg : AppColors.lightCardBg),
      borderRadius: AppSpacing.borderRadiusFull,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppSpacing.borderRadiusFull,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Icon(
            icon,
            size: size,
            color: iconColor ?? 
                (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
      ),
    ).animate().scale(
      duration: 200.ms,
      curve: Curves.easeOut,
    );
  }
}
