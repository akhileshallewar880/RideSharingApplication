import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/core/models/saved_location.dart';
import 'package:allapalli_ride/core/services/saved_location_service.dart';

/// Dialog for saving a location
class SaveLocationDialog extends ConsumerStatefulWidget {
  final String address;
  final double latitude;
  final double longitude;
  final SavedLocation? existingLocation;

  const SaveLocationDialog({
    super.key,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.existingLocation,
  });

  @override
  ConsumerState<SaveLocationDialog> createState() => _SaveLocationDialogState();
}

class _SaveLocationDialogState extends ConsumerState<SaveLocationDialog> {
  final _nameController = TextEditingController();
  SavedLocationType _selectedType = SavedLocationType.favorite;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingLocation != null) {
      _nameController.text = widget.existingLocation!.name;
      _selectedType = widget.existingLocation!.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveLocation() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name for this location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final name = _selectedType == SavedLocationType.home
          ? 'Home'
          : _selectedType == SavedLocationType.work
              ? 'Work'
              : _nameController.text.trim();

      await ref.read(savedLocationNotifierProvider.notifier).saveLocation(
            name: name,
            address: widget.address,
            latitude: widget.latitude,
            longitude: widget.longitude,
            type: _selectedType,
            existingId: widget.existingLocation?.id,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location saved as $name'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.bookmark_add,
                  color: AppColors.primaryGreen,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.existingLocation != null ? 'Edit Location' : 'Save Location',
                    style: TextStyles.headingMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Address display
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.grey[100],
                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.address,
                      style: TextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Type selector
            Text(
              'Save as',
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildTypeSelector(isDark),
            const SizedBox(height: AppSpacing.lg),

            // Name field (only for favorites)
            if (_selectedType == SavedLocationType.favorite) ...[
              Text(
                'Location name',
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g., Mom\'s House, Favorite Park',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        _buildTypeChip(
          icon: Icons.home,
          label: 'Home',
          type: SavedLocationType.home,
          isDark: isDark,
        ),
        _buildTypeChip(
          icon: Icons.work,
          label: 'Work',
          type: SavedLocationType.work,
          isDark: isDark,
        ),
        _buildTypeChip(
          icon: Icons.star,
          label: 'Favorite',
          type: SavedLocationType.favorite,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildTypeChip({
    required IconData icon,
    required String label,
    required SavedLocationType type,
    required bool isDark,
  }) {
    final isSelected = _selectedType == type;
    
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedType = type);
        }
      },
      selectedColor: AppColors.primaryGreen,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    );
  }
}

/// Show save location dialog
Future<bool?> showSaveLocationDialog({
  required BuildContext context,
  required String address,
  required double latitude,
  required double longitude,
  SavedLocation? existingLocation,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => SaveLocationDialog(
      address: address,
      latitude: latitude,
      longitude: longitude,
      existingLocation: existingLocation,
    ),
  );
}
