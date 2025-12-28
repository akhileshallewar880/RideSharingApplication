import 'package:flutter/material.dart';
import 'dart:async';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/features/passenger/domain/models/location_suggestion.dart';
import 'package:allapalli_ride/core/services/location_service.dart';

/// Location search field with autocomplete suggestions
class LocationSearchField extends StatefulWidget {
  final String? hint;
  final TextEditingController? controller;
  final void Function(LocationSuggestion)? onLocationSelected;
  final LocationService locationService;
  final String? initialValue;
  final IconData? prefixIcon;
  final bool showClearButton;
  
  const LocationSearchField({
    super.key,
    this.hint,
    this.controller,
    this.onLocationSelected,
    required this.locationService,
    this.initialValue,
    this.prefixIcon,
    this.showClearButton = true,
  });
  
  @override
  State<LocationSearchField> createState() => LocationSearchFieldState();
}

class LocationSearchFieldState extends State<LocationSearchField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<LocationSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  LocationSuggestion? _selectedLocation;
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
    _controller.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _removeOverlay();
    _controller.removeListener(_onSearchChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
  
  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Delay removal to allow tap on suggestion to register
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _removeOverlay();
        }
      });
    }
  }
  
  // Public method to set location programmatically (e.g., during swap)
  void setLocationWithoutSearch(LocationSuggestion? location) {
    if (location != null) {
      _selectedLocation = location;
      _controller.removeListener(_onSearchChanged);
      _controller.text = location.fullAddress;
      _controller.addListener(_onSearchChanged);
    }
  }
  
  void _onSearchChanged() {
    final query = _controller.text;
    
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _selectedLocation = null;
        _isLoading = false;
      });
      _removeOverlay();
      return;
    }
    
    // Only search if user is typing (not when location is selected)
    if (_selectedLocation != null && _controller.text == _selectedLocation!.fullAddress) {
      return;
    }
    
    _selectedLocation = null;
    
    // Show loading state immediately
    if (mounted && query.length >= 2) {
      setState(() {
        _isLoading = true;
      });
    }
    
    // Debounce the search
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _searchLocations(query);
      }
    });
  }
  
  Future<void> _searchLocations(String query) async {
    if (!mounted || query.length < 2) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
          _isLoading = false;
        });
        _removeOverlay();
      }
      return;
    }
    
    try {
      final results = await widget.locationService.searchLocations(query);
      
      if (!mounted) return;
      
      setState(() {
        _suggestions = results;
        _isLoading = false;
        _showSuggestions = results.isNotEmpty;
      });
      
      if (_showSuggestions) {
        // Add a small delay to ensure the widget is fully built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showOverlay();
          }
        });
      } else {
        _removeOverlay();
      }
    } catch (e) {
      debugPrint('Error searching locations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _suggestions = [];
          _showSuggestions = false;
        });
        _removeOverlay();
      }
    }
  }
  
  void _showOverlay() {
    if (!mounted) return;
    
    _removeOverlay();
    
    // Get the RenderBox to calculate width
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 300.0;
    
    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _removeOverlay();
        },
        child: Stack(
          children: [
            Positioned(
              width: width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 60),
                child: Material(
                  elevation: 8,
                  borderRadius: AppSpacing.borderRadiusMD,
                  child: _buildSuggestionsList(overlayContext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }
  
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
  }
  
  Widget _buildSuggestionsList(BuildContext overlayContext) {
    final isDark = Theme.of(overlayContext).brightness == Brightness.dark;
    
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.borderRadiusMD,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.darkShadow : AppColors.lightShadow).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        shrinkWrap: true,
        itemCount: _suggestions.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return _SuggestionItem(
            suggestion: suggestion,
            onTap: () => _onSuggestionSelected(suggestion),
          );
        },
      ),
    );
  }
  
  void _onSuggestionSelected(LocationSuggestion suggestion) {
    setState(() {
      _selectedLocation = suggestion;
      _controller.text = suggestion.fullAddress;
      _showSuggestions = false;
    });
    _removeOverlay();
    widget.onLocationSelected?.call(suggestion);
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: TextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: widget.hint ?? 'Enter location',
          hintStyle: TextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
          ),
          prefixIcon: Icon(
            widget.prefixIcon ?? Icons.location_on_outlined,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          suffixIcon: _isLoading
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryYellow,
                      ),
                    ),
                  ),
                )
              : (widget.showClearButton && _controller.text.isNotEmpty)
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _selectedLocation = null;
                          _suggestions = [];
                          _showSuggestions = false;
                        });
                        _removeOverlay();
                      },
                    )
                  : null,
          filled: true,
          fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusFull,
            borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusFull,
            borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppSpacing.borderRadiusFull,
            borderSide: BorderSide(
              color: AppColors.primaryYellow,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}

/// Individual suggestion item widget
class _SuggestionItem extends StatelessWidget {
  final LocationSuggestion suggestion;
  final VoidCallback onTap;
  
  const _SuggestionItem({
    required this.suggestion,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withOpacity(0.1),
                borderRadius: AppSpacing.borderRadiusSM,
              ),
              child: Icon(
                Icons.location_on,
                size: 20,
                color: AppColors.primaryYellow,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.name,
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  if (suggestion.state != null || suggestion.district != null)
                    Text(
                      [
                        if (suggestion.district != null) suggestion.district,
                        if (suggestion.state != null) suggestion.state,
                      ].join(', '),
                      style: TextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
