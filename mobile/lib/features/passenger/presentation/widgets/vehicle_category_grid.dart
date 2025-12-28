import 'package:flutter/material.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';

class VehicleCategoryGrid extends StatelessWidget {
  final Function(String) onCategorySelected;

  const VehicleCategoryGrid({
    super.key,
    required this.onCategorySelected,
  });

  final List<Map<String, dynamic>> _categories = const [
    {
      'id': 'auto',
      'name': 'Auto',
      'icon': Icons.electric_rickshaw,
      'color': Color(0xFFFFF3E0), // Light Orange
      'iconColor': AppColors.primaryOrange,
    },
    {
      'id': 'bike',
      'name': 'Bike',
      'icon': Icons.two_wheeler,
      'color': Color(0xFFE3F2FD), // Light Blue
      'iconColor': Colors.blue,
    },
    {
      'id': 'car',
      'name': 'Car',
      'icon': Icons.directions_car,
      'color': Color(0xFFF3E5F5), // Light Purple
      'iconColor': Colors.purple,
    },
    {
      'id': 'rental',
      'name': 'Rentals',
      'icon': Icons.car_rental,
      'color': Color(0xFFE8F5E9), // Light Green
      'iconColor': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'Ways to Travel',
            style: TextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.8,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return InkWell(
              onTap: () => onCategorySelected(category['id']),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: category['color'],
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                    ),
                    child: Icon(
                      category['icon'],
                      size: 30,
                      color: category['iconColor'],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    category['name'],
                    style: TextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
