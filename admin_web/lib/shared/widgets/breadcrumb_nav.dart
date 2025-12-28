import 'package:flutter/material.dart';
import '../../core/theme/admin_theme.dart';

class BreadcrumbNav extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const BreadcrumbNav({
    Key? key,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: AdminTheme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.home_outlined,
            size: 18,
            color: AdminTheme.textSecondary,
          ),
          SizedBox(width: 8),
          ...List.generate(items.length * 2 - 1, (index) {
            if (index.isOdd) {
              // Separator
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AdminTheme.textSecondary,
                ),
              );
            }
            
            final itemIndex = index ~/ 2;
            final item = items[itemIndex];
            final isLast = itemIndex == items.length - 1;
            
            return InkWell(
              onTap: isLast || item.onTap == null ? null : item.onTap,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: isLast ? AdminTheme.primaryColor : AdminTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
                    decoration: !isLast && item.onTap != null
                        ? TextDecoration.underline
                        : null,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  const BreadcrumbItem({
    required this.label,
    this.onTap,
  });
}
