import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/core/models/vehicle_models.dart';
import 'package:allapalli_ride/core/services/vehicle_model_service.dart';

/// Vehicle model selector widget with category filters
class VehicleModelSelector extends ConsumerStatefulWidget {
  final VehicleModel? selectedModel;
  final Function(VehicleModel) onModelSelected;
  final bool showBusCategory;

  const VehicleModelSelector({
    super.key,
    this.selectedModel,
    required this.onModelSelected,
    this.showBusCategory = true,
  });

  @override
  ConsumerState<VehicleModelSelector> createState() =>
      _VehicleModelSelectorState();
}

class _VehicleModelSelectorState extends ConsumerState<VehicleModelSelector> {
  final VehicleModelService _service = VehicleModelService();
  String _selectedCategory = 'All';
  List<VehicleModel> _vehicles = [];
  List<VehicleModel> _filteredVehicles = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVehicleModels();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleModels() async {
    setState(() => _isLoading = true);

    final response = await _service.getVehicleModels();
    if (response.success && response.data != null) {
      setState(() {
        _vehicles = response.data!.vehicles;
        _filterVehicles();
        _isLoading = false;
      });
    } else {
      // Use fallback models
      setState(() {
        _vehicles = PopularVehicleModels.all;
        _filterVehicles();
        _isLoading = false;
      });
    }
  }

  void _filterVehicles() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredVehicles = _vehicles.where((vehicle) {
        // Category filter
        final matchesCategory = _selectedCategory == 'All' ||
            vehicle.typeLabel == _selectedCategory;

        // Bus filter
        final includeBus = widget.showBusCategory || vehicle.type != 'bus';

        // Search filter
        final matchesSearch = query.isEmpty ||
            vehicle.name.toLowerCase().contains(query) ||
            vehicle.brand.toLowerCase().contains(query) ||
            vehicle.displayName.toLowerCase().contains(query);

        return matchesCategory && includeBus && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = widget.showBusCategory
        ? ['All', 'Car', 'SUV', 'Van', 'Bus']
        : ['All', 'Car', 'SUV', 'Van'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Select Vehicle Model',
                      style: TextStyles.headingMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _filterVehicles(),
                  decoration: InputDecoration(
                    hintText: 'Search vehicle model...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor:
                        isDark ? AppColors.darkBackground : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category tabs
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                          _filterVehicles();
                        });
                      }
                    },
                    selectedColor: AppColors.primaryYellow,
                    backgroundColor:
                        isDark ? AppColors.darkCardBg : Colors.grey[200],
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Vehicle list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVehicles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_car_outlined,
                              size: 64,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.lightTextTertiary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No vehicles found',
                              style: TextStyles.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _filteredVehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = _filteredVehicles[index];
                          final isSelected =
                              widget.selectedModel?.id == vehicle.id;

                          return _VehicleModelCard(
                            vehicle: vehicle,
                            isSelected: isSelected,
                            isDark: isDark,
                            onTap: () {
                              widget.onModelSelected(vehicle);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Individual vehicle model card
class _VehicleModelCard extends StatelessWidget {
  final VehicleModel vehicle;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _VehicleModelCard({
    required this.vehicle,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryYellow
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primaryYellow.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Vehicle icon/image placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getVehicleIcon(vehicle.type),
                  color: AppColors.primaryYellow,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Vehicle details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.displayName,
                      style: TextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            vehicle.typeLabel,
                            style: TextStyles.caption.copyWith(
                              color: AppColors.primaryYellow,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.event_seat,
                          size: 14,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${vehicle.seatingCapacity} Seats',
                          style: TextStyles.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (vehicle.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        vehicle.description!,
                        style: TextStyles.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (vehicle.features != null &&
                        vehicle.features!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: vehicle.features!.take(3).map((feature) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBackground
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              feature,
                              style: TextStyles.caption.copyWith(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primaryYellow,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getVehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'car':
        return Icons.directions_car;
      case 'suv':
        return Icons.airport_shuttle;
      case 'van':
        return Icons.local_shipping;
      case 'bus':
        return Icons.directions_bus;
      default:
        return Icons.directions_car;
    }
  }
}
