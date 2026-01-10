import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/models/location_suggestion.dart';
import '../../core/services/admin_location_service.dart';

/// Location search field with autocomplete suggestions for web
class LocationSearchField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final void Function(LocationSuggestion)? onLocationSelected;
  final LocationSuggestion? initialLocation;
  final IconData? prefixIcon;
  final bool showClearButton;
  final String? Function(String?)? validator;
  final bool enabled;

  const LocationSearchField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onLocationSelected,
    this.initialLocation,
    this.prefixIcon,
    this.showClearButton = true,
    this.validator,
    this.enabled = true,
  });

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final AdminLocationService _locationService = AdminLocationService();
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
    if (widget.initialLocation != null) {
      _controller.text = widget.initialLocation!.fullAddress;
      _selectedLocation = widget.initialLocation;
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
      final results = await _locationService.searchLocations(query);

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
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return InkWell(
                          onTap: () => _selectLocation(suggestion),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: index < _suggestions.length - 1
                                    ? BorderSide(color: Colors.grey.shade200)
                                    : BorderSide.none,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 20,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        suggestion.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (suggestion.district != null)
                                        Text(
                                          '${suggestion.district}, ${suggestion.state}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
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
    _overlayEntry = null;
  }

  void _selectLocation(LocationSuggestion location) {
    setState(() {
      _selectedLocation = location;
      _controller.text = location.fullAddress;
      _showSuggestions = false;
      _suggestions = [];
    });
    _removeOverlay();
    _focusNode.unfocus();
    widget.onLocationSelected?.call(location);
  }

  void _clearSelection() {
    setState(() {
      _controller.clear();
      _selectedLocation = null;
      _suggestions = [];
      _showSuggestions = false;
    });
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint ?? 'Search for a location',
          prefixIcon: Icon(widget.prefixIcon ?? Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              if (widget.showClearButton && _controller.text.isNotEmpty && !_isLoading)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSelection,
                  tooltip: 'Clear',
                ),
            ],
          ),
          border: const OutlineInputBorder(),
        ),
        validator: widget.validator,
        onChanged: (_) {
          // Trigger rebuild to show/hide clear button
          setState(() {});
        },
      ),
    );
  }
}
