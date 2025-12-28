import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/mock_location_service.dart';

/// Debug panel for testing intermediate stops without physical travel
/// Only shows in debug mode
class MockLocationDebugPanel extends StatefulWidget {
  final VoidCallback? onMockModeChanged;
  
  const MockLocationDebugPanel({
    super.key,
    this.onMockModeChanged,
  });

  @override
  State<MockLocationDebugPanel> createState() => _MockLocationDebugPanelState();
}

class _MockLocationDebugPanelState extends State<MockLocationDebugPanel> {
  final MockLocationService _mockService = MockLocationService();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 100,
      right: 10,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: Colors.black87,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isExpanded ? 320 : 60,
          height: _isExpanded ? 450 : 60,
          padding: const EdgeInsets.all(12),
          child: _isExpanded ? _buildExpandedPanel() : _buildCollapsedButton(),
        ),
      ),
    );
  }

  Widget _buildCollapsedButton() {
    return IconButton(
      icon: const Icon(Icons.bug_report, color: Colors.white),
      onPressed: () {
        setState(() => _isExpanded = true);
      },
    );
  }

  Widget _buildExpandedPanel() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🧪 Mock GPS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () {
                  setState(() => _isExpanded = false);
                },
              ),
            ],
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          
          // Enable/Disable Mock Mode
          SwitchListTile(
            title: const Text(
              'Mock Mode',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: Text(
              _mockService.isMockEnabled ? 'Active' : 'Inactive',
              style: TextStyle(
                color: _mockService.isMockEnabled ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
            value: _mockService.isMockEnabled,
            onChanged: (value) {
              setState(() {
                if (value) {
                  _mockService.enableMockMode();
                } else {
                  _mockService.disableMockMode();
                }
              });
              
              // Notify parent to restart tracking
              widget.onMockModeChanged?.call();
              
              // Show feedback
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value 
                        ? '🧪 Mock mode enabled. Tracking restarted.' 
                        : '📱 Real GPS mode. Tracking restarted.',
                    ),
                    backgroundColor: value ? Colors.green : Colors.blue,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            activeColor: Colors.green,
            dense: true,
          ),
          
          const Divider(color: Colors.white24),
          
          // Quick presets
          const Text(
            'Quick Locations:',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _mockService.getAvailableLocations().map((location) {
              return ElevatedButton(
                onPressed: _mockService.isMockEnabled
                    ? () {
                        _mockService.setMockLocationByName(location);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('📍 Moved to $location'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  location,
                  style: const TextStyle(fontSize: 11),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          
          // Manual coordinates
          const Text(
            'Manual Coordinates:',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _latController,
            enabled: _mockService.isMockEnabled,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'Latitude',
              labelStyle: TextStyle(color: Colors.white70, fontSize: 11),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white30),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              isDense: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _lngController,
            enabled: _mockService.isMockEnabled,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'Longitude',
              labelStyle: TextStyle(color: Colors.white70, fontSize: 11),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white30),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              isDense: true,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _mockService.isMockEnabled ? _setManualLocation : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                'Set Location',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          const Divider(color: Colors.white24),
          
          // Add custom location
          const Text(
            'Save Location:',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            enabled: _mockService.isMockEnabled,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'Location Name',
              labelStyle: TextStyle(color: Colors.white70, fontSize: 11),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white30),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _mockService.isMockEnabled ? _saveCurrentLocation : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                'Save Current',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setManualLocation() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    
    if (lat == null || lng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Invalid coordinates'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    _mockService.setMockLocation(
      latitude: lat,
      longitude: lng,
    );
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📍 Location set: $lat, $lng'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveCurrentLocation() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Enter a location name'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    
    if (lat == null || lng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Set coordinates first'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    _mockService.addLocation(name, lat, lng);
    _nameController.clear();
    
    if (!mounted) return;
    setState(() {});
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Saved location: $name'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
