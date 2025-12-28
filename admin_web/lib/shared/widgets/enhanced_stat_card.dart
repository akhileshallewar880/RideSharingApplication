import 'package:flutter/material.dart';
import '../../core/theme/admin_theme.dart';

/// Shiprocket-style high-density stat card with icon
class EnhancedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final String? trend;
  final bool isPositiveTrend;
  final VoidCallback? onTap;

  const EnhancedStatCard({
    Key? key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.trend,
    this.isPositiveTrend = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AdminTheme.primaryColor;
    final effectiveBgColor = backgroundColor ?? AdminTheme.highlightYellow;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AdminTheme.borderGray, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and Title Row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: effectiveBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: effectiveIconColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (trend != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPositiveTrend
                            ? AdminTheme.successColor.withOpacity(0.1)
                            : AdminTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositiveTrend
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: 14,
                            color: isPositiveTrend
                                ? AdminTheme.successColor
                                : AdminTheme.errorColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            trend!,
                            style: TextStyle(
                              color: isPositiveTrend
                                  ? AdminTheme.successColor
                                  : AdminTheme.errorColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
              
              // Value
              Text(
                value,
                style: TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              
              // Subtitle
              if (subtitle != null) ...[
                SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
