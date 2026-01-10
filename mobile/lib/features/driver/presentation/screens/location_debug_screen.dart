import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/location_tracking_service.dart';

/// Debug screen to test location updates
/// Helps diagnose why mock locations aren't working
class LocationDebugScreen extends StatefulWidget {
  const LocationDebugScreen({super.key});

  @override
  State<LocationDebugScreen> createState() => _LocationDebugScreenState();
}

class _LocationDebugScreenState extends State<LocationDebugScreen> {
  final LocationTrackingService _locationService = LocationTrackingService();
  final List<String> _logs = [];
  StreamSubscription<Position>? _streamSubscription;
  Timer? _pollingTimer;
  Position? _lastPosition;
  Position? _lastStreamPosition;
  
  bool _isStreaming = false;
  bool _isPolling = false;
  
  @override
  void initState() {
    super.initState();
    _addLog('🚀 Location Debug Screen initialized');
    _checkLocationSettings();
  }
  
  @override
  void dispose() {
    _streamSubscription?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }
  
  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toIso8601String().substring(11, 19)} - $message');
      if (_logs.length > 50) _logs.removeLast();
    });
    debugPrint(message);
  }
  
  Future<void> _checkLocationSettings() async {
    _addLog('🔍 Checking location settings...');
    
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    _addLog('📡 Location services: ${serviceEnabled ? "ENABLED" : "DISABLED"}');
    
    final permission = await Geolocator.checkPermission();
    _addLog('🔐 Permission: $permission');
    
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _addLog('⚠️ Requesting location permission...');
      final newPermission = await Geolocator.requestPermission();
      _addLog('🔐 New permission: $newPermission');
    }
    
    // Check mock location status
    if (_locationService.isMockEnabled) {
      _addLog('🧪 INTERNAL mock location mode: ENABLED');
    } else {
      _addLog('🌍 Using REAL GPS (external mock apps should still work)');
    }
  }
  
  Future<void> _getCurrentPositionOnce() async {
    _addLog('📍 Calling Geolocator.getCurrentPosition()...');
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _lastPosition = position;
      _addLog('✅ Got position: ${position.latitude}, ${position.longitude}');
      _addLog('   Speed: ${position.speed} m/s, Heading: ${position.heading}°');
      _addLog('   Accuracy: ${position.accuracy}m, Time: ${position.timestamp}');
    } catch (e) {
      _addLog('❌ Error: $e');
    }
  }
  
  void _startPositionStream() {
    if (_isStreaming) {
      _addLog('⚠️ Stream already running');
      return;
    }
    
    _addLog('🎧 Starting position stream...');
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0, // Update on ANY location change
    );
    
    _streamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _lastStreamPosition = position;
        _addLog('🎧 STREAM UPDATE: ${position.latitude}, ${position.longitude}');
        setState(() {});
      },
      onError: (error) {
        _addLog('❌ Stream error: $error');
      },
      onDone: () {
        _addLog('✅ Stream closed');
        setState(() => _isStreaming = false);
      },
    );
    
    setState(() => _isStreaming = true);
    _addLog('✅ Stream started');
  }
  
  void _stopPositionStream() {
    _addLog('🛑 Stopping stream...');
    _streamSubscription?.cancel();
    _streamSubscription = null;
    setState(() => _isStreaming = false);
    _addLog('✅ Stream stopped');
  }
  
  void _startPolling() {
    if (_isPolling) {
      _addLog('⚠️ Polling already running');
      return;
    }
    
    _addLog('⏰ Starting 3-second polling...');
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      _addLog('⏰ POLL TICK - fetching position...');
      await _getCurrentPositionOnce();
    });
    
    setState(() => _isPolling = true);
    _addLog('✅ Polling started');
  }
  
  void _stopPolling() {
    _addLog('🛑 Stopping polling...');
    _pollingTimer?.cancel();
    _pollingTimer = null;
    setState(() => _isPolling = false);
    _addLog('✅ Polling stopped');
  }
  
  void _clearLogs() {
    setState(() => _logs.clear());
  }
  
  void _copyLogsToClipboard() {
    final allLogs = _logs.reversed.join('\n');
    Clipboard.setData(ClipboardData(text: allLogs));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogsToClipboard,
            tooltip: 'Copy logs',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLogs,
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusRow('Stream', _isStreaming),
                  _buildStatusRow('Polling', _isPolling),
                  const Divider(),
                  if (_lastPosition != null) ...[
                    Text('Last getCurrentPosition():',
                        style: Theme.of(context).textTheme.titleSmall),
                    Text('  ${_lastPosition!.latitude.toStringAsFixed(6)}, '
                        '${_lastPosition!.longitude.toStringAsFixed(6)}'),
                    Text('  ${_lastPosition!.timestamp}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                  if (_lastStreamPosition != null) ...[
                    const SizedBox(height: 8),
                    Text('Last stream position:',
                        style: Theme.of(context).textTheme.titleSmall),
                    Text('  ${_lastStreamPosition!.latitude.toStringAsFixed(6)}, '
                        '${_lastStreamPosition!.longitude.toStringAsFixed(6)}'),
                    Text('  ${_lastStreamPosition!.timestamp}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
          
          // Control Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _getCurrentPositionOnce,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Get Position Once'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _checkLocationSettings,
                        icon: const Icon(Icons.settings),
                        label: const Text('Check Settings'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isStreaming ? _stopPositionStream : _startPositionStream,
                        icon: Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
                        label: Text(_isStreaming ? 'Stop Stream' : 'Start Stream'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isStreaming ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isPolling ? _stopPolling : _startPolling,
                        icon: Icon(_isPolling ? Icons.stop : Icons.timer),
                        label: Text(_isPolling ? 'Stop Poll' : 'Start Poll (3s)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPolling ? Colors.red : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          
          // Instructions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Instructions:', style: Theme.of(context).textTheme.titleSmall),
                const Text('1. Enable "Mock location app" in Developer Options'),
                const Text('2. Select your mock location app (e.g., Fake GPS)'),
                const Text('3. Set a location in your mock app'),
                const Text('4. Click "Get Position Once" to test'),
                const Text('5. Start "Stream" or "Poll" to test continuous updates'),
                const Text('6. Change location in mock app'),
                const Text('7. Watch logs to see if position updates'),
              ],
            ),
          ),
          
          const Divider(),
          
          // Logs
          Expanded(
            child: Container(
              color: Colors.black87,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.greenAccent,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusRow(String label, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: '),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isActive ? 'ACTIVE' : 'INACTIVE',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
