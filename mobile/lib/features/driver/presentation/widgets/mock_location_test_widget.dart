import 'package:flutter/material.dart';
import '../../../../core/services/location_tracking_service.dart';

/// Widget to test mock locations easily
/// Add this to your driver home screen or create a dedicated test screen
class MockLocationTestWidget extends StatefulWidget {
  const MockLocationTestWidget({super.key});

  @override
  State<MockLocationTestWidget> createState() => _MockLocationTestWidgetState();
}

class _MockLocationTestWidgetState extends State<MockLocationTestWidget> {
  final LocationTrackingService _locationService = LocationTrackingService();
  bool _isMockEnabled = false;
  String _currentLocation = 'None';
  bool _isSimulating = false;

  @override
  void initState() {
    super.initState();
    _isMockEnabled = _locationService.isMockEnabled;
  }

  void _toggleMockMode() {
    setState(() {
      if (_isMockEnabled) {
        _locationService.mockService.disableMockMode();
        _isMockEnabled = false;
        _currentLocation = 'None';
      } else {
        _locationService.mockService.enableMockMode();
        _isMockEnabled = true;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isMockEnabled ? '🧪 Mock mode ENABLED' : '🌍 Using real GPS'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _setLocation(String locationName) {
    if (!_isMockEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Enable mock mode first')),
      );
      return;
    }

    _locationService.mockService.setMockLocationByName(locationName);
    setState(() => _currentLocation = locationName);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📍 Moved to $locationName')),
    );
  }

  Future<void> _simulateFullRoute() async {
    if (!_isMockEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Enable mock mode first')),
      );
      return;
    }

    setState(() => _isSimulating = true);

    final stops = [
      'pickup',
      'between-pickup-stop1',
      'stop1',
      'between-stop1-stop2',
      'stop2',
      'between-stop2-stop3',
      'stop3',
      'between-stop3-dropoff',
      'dropoff',
    ];

    for (final stop in stops) {
      if (!_isSimulating) break;
      
      _locationService.mockService.setMockLocationByName(stop);
      setState(() => _currentLocation = stop);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 $stop'),
          duration: const Duration(seconds: 1),
        ),
      );

      await Future.delayed(const Duration(seconds: 4));
    }

    setState(() => _isSimulating = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Route simulation complete!')),
      );
    }
  }

  void _stopSimulation() {
    setState(() => _isSimulating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Row(
              children: [
                const Icon(Icons.location_on, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Mock Location Tester',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isMockEnabled ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isMockEnabled ? Colors.green : Colors.grey,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Mock Mode:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        _isMockEnabled ? 'ENABLED 🧪' : 'DISABLED 🌍',
                        style: TextStyle(
                          color: _isMockEnabled ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_isMockEnabled) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_currentLocation),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Toggle Button
            ElevatedButton.icon(
              onPressed: _isSimulating ? null : _toggleMockMode,
              icon: Icon(_isMockEnabled ? Icons.gps_fixed : Icons.gps_off),
              label: Text(_isMockEnabled ? 'Disable Mock Mode' : 'Enable Mock Mode'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMockEnabled ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            
            if (_isMockEnabled) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              // Quick Location Buttons
              const Text('Quick Locations:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildLocationChip('pickup', '🅿️'),
                  _buildLocationChip('stop1', '1️⃣'),
                  _buildLocationChip('stop2', '2️⃣'),
                  _buildLocationChip('stop3', '3️⃣'),
                  _buildLocationChip('dropoff', '🏁'),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Simulate Full Route
              ElevatedButton.icon(
                onPressed: _isSimulating ? _stopSimulation : _simulateFullRoute,
                icon: Icon(_isSimulating ? Icons.stop : Icons.play_arrow),
                label: Text(_isSimulating ? 'Stop Simulation' : 'Simulate Full Route'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSimulating ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              
              if (_isSimulating) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
                const SizedBox(height: 4),
                const Text(
                  'Moving through route... (4s per stop)',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            // Instructions
            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Text(
              '1. Enable Mock Mode\n'
              '2. Click location buttons or simulate route\n'
              '3. Watch tracking screen update every 3s',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationChip(String location, String emoji) {
    final isSelected = _currentLocation == location;
    return ActionChip(
      label: Text('$emoji ${location.toUpperCase()}'),
      onPressed: _isSimulating ? null : () => _setLocation(location),
      backgroundColor: isSelected ? Colors.blue.shade100 : null,
      side: BorderSide(
        color: isSelected ? Colors.blue : Colors.grey.shade300,
        width: isSelected ? 2 : 1,
      ),
    );
  }
}
