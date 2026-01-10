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
            borderRadius: BorderRadius.circular(50),
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
            borderRadius: BorderRadius.circular(50),
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

/// Google Sign-In button following official Google branding guidelines
/// Uses pre-approved Google Sign-In button assets
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  
  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 48,
      child: isLoading
          ? Container(
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF4285F4) : Colors.white,
                border: isDark ? null : Border.all(color: Color(0xFF747775), width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? Colors.white : Color(0xFF1F1F1F),
                  ),
                ),
              ),
            )
          : InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                isDark
                    ? 'assets/images/dark/android_dark_sq.png'
                    : 'assets/images/light/android_light_sq.png',
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading Google Sign-In image: $error');
                  // Fallback button with icon and text
                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF4285F4) : Colors.white,
                      border: isDark ? null : Border.all(color: Color(0xFF747775), width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.g_mobiledata,
                          size: 24,
                          color: isDark ? Colors.white : Color(0xFF1F1F1F),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Roboto',
                            color: isDark ? Colors.white : Color(0xFF1F1F1F),
                            letterSpacing: 0.25,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
