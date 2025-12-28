import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/app/themes/app_colors.dart';
import 'package:allapalli_ride/app/themes/app_spacing.dart';
import 'package:allapalli_ride/app/themes/text_styles.dart';
import 'package:allapalli_ride/features/passenger/domain/models/location_suggestion.dart';
import 'package:allapalli_ride/core/providers/location_provider.dart';
import 'package:allapalli_ride/core/models/saved_location.dart';
import 'package:allapalli_ride/core/services/saved_location_service.dart';
import 'package:allapalli_ride/features/passenger/presentation/widgets/save_location_dialog.dart';
import 'dart:async';

/// Full-screen location search with popular destinations and history
class LocationSearchScreen extends ConsumerStatefulWidget {
  final String title;
  final String? initialValue;
  final bool isPickup;
  
  const LocationSearchScreen({
    super.key,
    required this.title,
    this.initialValue,
    this.isPickup = true,
  });
  
  @override
  ConsumerState<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends ConsumerState<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<LocationSuggestion> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;
  
  // Popular boarding points
  final List<Map<String, String>> _popularPoints = [
    {'name': 'Allapalli Bus Stand', 'city': 'Allapalli, Maharashtra'},
    {'name': 'Chandrapur Railway Station', 'city': 'Chandrapur, Maharashtra'},
    {'name': 'Nagpur Airport', 'city': 'Nagpur, Maharashtra'},
    {'name': 'Gadchiroli Bus Station', 'city': 'Gadchiroli, Maharashtra'},
  ];
  
  // Popular cities
  final List<String> _popularCities = [
    'Allapalli',
    'Chandrapur',
    'Nagpur',
    'Gadchiroli',
    'Wardha',
    'Gondia',
  ];
  
  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _searchController.text = widget.initialValue!;
    }
    _searchController.addListener(_onSearchChanged);
    
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    final query = _searchController.text;
    
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
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
          _searchResults = [];
          _isLoading = false;
        });
      }
      return;
    }
    
    try {
      final results = await ref.read(locationServiceProvider).searchLocations(query);
      
      if (!mounted) return;
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }
  
  void _selectLocation(LocationSuggestion location) {
    Navigator.pop(context, location);
  }
  
  void _selectPopularPoint(String name, String city) {
    final location = LocationSuggestion(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      fullAddress: '$name, $city',
      latitude: 0.0,
      longitude: 0.0,
    );
    Navigator.pop(context, location);
  }
  
  void _selectCity(String city) {
    final location = LocationSuggestion(
      id: city.toLowerCase().replaceAll(' ', '_'),
      name: city,
      fullAddress: city,
      latitude: 0.0,
      longitude: 0.0,
    );
    Navigator.pop(context, location);
  }
  
  void _selectSavedLocation(SavedLocation saved) async {
    // Update last used timestamp
    await ref.read(savedLocationNotifierProvider.notifier).updateLastUsed(saved.id);
    
    final location = LocationSuggestion(
      id: saved.id,
      name: saved.name,
      fullAddress: saved.address,
      latitude: saved.latitude,
      longitude: saved.longitude,
    );
    if (mounted) {
      Navigator.pop(context, location);
    }
  }
  
  void _showSaveLocationDialog(LocationSuggestion location) {
    showSaveLocationDialog(
      context: context,
      address: location.fullAddress,
      latitude: location.latitude ?? 0.0,
      longitude: location.longitude ?? 0.0,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Set white status bar
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: isDark ? AppColors.darkSurface : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark 
                            ? AppColors.darkBackground 
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: TextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Search area',
                          hintStyle: TextStyles.bodyMedium.copyWith(
                            color: isDark 
                                ? AppColors.darkTextTertiary 
                                : AppColors.lightTextTertiary,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: isDark 
                                ? AppColors.darkTextSecondary 
                                : AppColors.lightTextSecondary,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _searchController.text.isNotEmpty
                  ? _buildSearchResults(isDark)
                  : _buildPopularDestinations(isDark),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchResults(bool isDark) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryYellow,
        ),
      );
    }
    
    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: isDark 
                    ? AppColors.darkTextTertiary 
                    : AppColors.lightTextTertiary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No locations found',
                style: TextStyles.bodyLarge.copyWith(
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      ),
      itemBuilder: (context, index) {
        final location = _searchResults[index];
        return ListTile(
          leading: Icon(
            Icons.location_on,
            color: isDark 
                ? AppColors.darkTextSecondary 
                : AppColors.lightTextSecondary,
          ),
          title: Text(
            location.name,
            style: TextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            location.fullAddress,
            style: TextStyles.bodySmall.copyWith(
              color: isDark 
                  ? AppColors.darkTextSecondary 
                  : AppColors.lightTextSecondary,
            ),
          ),
          onTap: () => _selectLocation(location),
        );
      },
    );
  }
  
  Widget _buildPopularDestinations(bool isDark) {
    final homeLocation = ref.read(savedLocationNotifierProvider.notifier).getHomeLocation();
    final workLocation = ref.read(savedLocationNotifierProvider.notifier).getWorkLocation();
    final favoriteLocations = ref.read(savedLocationNotifierProvider.notifier).getFavoriteLocations();
    
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Saved Locations Section
        if (homeLocation != null || workLocation != null || favoriteLocations.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved locations',
                style: TextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to manage saved locations
                  _navigateToManageSavedLocations();
                },
                child: Text(
                  'Manage',
                  style: TextStyles.bodySmall.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Home location
          if (homeLocation != null)
            _buildSavedLocationTile(homeLocation, Icons.home, isDark),
          
          // Work location
          if (workLocation != null)
            _buildSavedLocationTile(workLocation, Icons.work, isDark),
          
          // Favorite locations
          ...favoriteLocations.map((loc) => _buildSavedLocationTile(loc, Icons.star, isDark)),
          
          const SizedBox(height: AppSpacing.xl),
        ],
        
        // Popular Boarding Points
        Text(
          'Popular boarding points',
          style: TextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._popularPoints.map((point) {
          return InkWell(
            onTap: () => _selectPopularPoint(point['name']!, point['city']!),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_bus,
                    color: isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.lightTextSecondary,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          point['name']!,
                          style: TextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          point['city']!,
                          style: TextStyles.bodySmall.copyWith(
                            color: isDark 
                                ? AppColors.darkTextSecondary 
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        
        const SizedBox(height: AppSpacing.xl),
        
        // Popular Cities
        Text(
          'Popular cities',
          style: TextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._popularCities.map((city) {
          return InkWell(
            onTap: () => _selectCity(city),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.location_city,
                    color: isDark 
                        ? AppColors.darkTextSecondary 
                        : AppColors.lightTextSecondary,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Text(
                    city,
                    style: TextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
  
  Widget _buildSavedLocationTile(SavedLocation location, IconData icon, bool isDark) {
    return InkWell(
      onTap: () => _selectSavedLocation(location),
      onLongPress: () {
        _showManageLocationBottomSheet(location);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: TextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location.address,
                    style: TextStyles.bodySmall.copyWith(
                      color: isDark 
                          ? AppColors.darkTextSecondary 
                          : AppColors.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark 
                  ? AppColors.darkTextTertiary 
                  : AppColors.lightTextTertiary,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showManageLocationBottomSheet(SavedLocation location) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: AppColors.primaryGreen),
              title: const Text('Edit location'),
              onTap: () {
                Navigator.pop(context);
                showSaveLocationDialog(
                  context: context,
                  address: location.address,
                  latitude: location.latitude,
                  longitude: location.longitude,
                  existingLocation: location,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete location'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(savedLocationNotifierProvider.notifier).deleteLocation(location.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${location.name} deleted'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToManageSavedLocations() {
    // TODO: Navigate to saved locations management screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manage saved locations - Coming soon!')),
    );
  }
}
