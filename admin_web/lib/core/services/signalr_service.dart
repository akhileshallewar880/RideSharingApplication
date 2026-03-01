import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../services/admin_auth_service.dart';

class SignalRService {
  HubConnection? _hubConnection;
  final AdminAuthService _authService;
  bool _isConnected = false;
  bool _isInitializing = false; // Guard against concurrent initialize() calls

  // Callback handlers
  Function(String rideId, double latitude, double longitude)? onLocationUpdate;
  Function(String rideId, String status)? onRideStatusUpdate;
  Function(Map<String, dynamic> notification)? onNotificationReceived;

  SignalRService(this._authService);

  /// Check if connected to SignalR hub
  bool get isConnected => _isConnected;

  /// Initialize SignalR connection
  Future<void> initialize() async {
    if (_hubConnection != null && _isConnected) {
      debugPrint('SignalR: Already connected');
      return;
    }
    // Prevent duplicate concurrent initialization
    if (_isInitializing) {
      debugPrint('SignalR: Initialization already in progress');
      return;
    }
    _isInitializing = true;

    try {
      final token = await _authService.getToken();
      if (token == null) {
        debugPrint('SignalR: No auth token available');
        return;
      }

      // Create hub connection
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            '${AppConstants.baseUrl.replaceAll('/api/v1', '')}/tracking',
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token,
            ),
          )
          .withAutomaticReconnect()
          .build();

      // Register event handlers
      _registerEventHandlers();

      // Start connection
      await _hubConnection!.start();
      _isConnected = true;
      debugPrint('SignalR: Connected successfully');
    } catch (e) {
      debugPrint('SignalR: Connection error: $e');
      _isConnected = false;
    } finally {
      _isInitializing = false;
    }
  }
  
  /// Register event handlers for SignalR messages
  void _registerEventHandlers() {
    if (_hubConnection == null) return;
    
    // Location update handler - matches backend "LocationUpdate" event
    _hubConnection!.on('LocationUpdate', (arguments) {
      try {
        if (arguments != null && arguments.isNotEmpty) {
          final data = arguments[0] as Map<String, dynamic>;
          final rideId = (data['rideId'] ?? data['RideId']) as String?;
          if (rideId == null || rideId.isEmpty) return;

          final locationRaw = data['location'] ?? data['Location'];
          if (locationRaw == null) return;
          final location = locationRaw as Map<String, dynamic>;

          // Support both camelCase (latitude) and PascalCase (Latitude) from server
          final latRaw = location['latitude'] ?? location['Latitude'];
          final lngRaw = location['longitude'] ?? location['Longitude'];
          if (latRaw == null || lngRaw == null) return;

          final latitude = (latRaw as num).toDouble();
          final longitude = (lngRaw as num).toDouble();

          debugPrint('SignalR: Location update - Ride: $rideId, Lat: $latitude, Lng: $longitude');
          onLocationUpdate?.call(rideId, latitude, longitude);
        }
      } catch (e) {
        debugPrint('SignalR: Error parsing LocationUpdate: $e');
      }
    });
    
    // Ride status update handler - matches backend "TripStatus" event
    _hubConnection!.on('TripStatus', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        final rideId = data['rideId'] as String;
        final status = data['status'] as String;
        
        debugPrint('SignalR: Ride status update - Ride: $rideId, Status: $status');
        onRideStatusUpdate?.call(rideId, status);
      }
    });
    
    // Passenger update handler - matches backend "PassengerUpdate" event
    _hubConnection!.on('PassengerUpdate', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        debugPrint('SignalR: Passenger update - ${data['updateType']}');
      }
    });
    
    // Joined ride confirmation handler
    _hubConnection!.on('JoinedRide', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        debugPrint('SignalR: Joined ride ${data['rideId']}');
      }
    });
    
    // Error handler
    _hubConnection!.on('Error', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        debugPrint('SignalR: Error - ${data['message']}');
      }
    });
  }
  
  /// Join a ride tracking room
  Future<void> joinRideRoom(String rideId) async {
    if (_hubConnection == null || !_isConnected) {
      debugPrint('SignalR: Not connected, cannot join ride room');
      await initialize();
    }
    
    try {
      await _hubConnection!.invoke('JoinRide', args: [rideId]);
      debugPrint('SignalR: Joined ride room: $rideId');
    } catch (e) {
      debugPrint('SignalR: Error joining ride room: $e');
    }
  }
  
  /// Leave a ride tracking room
  Future<void> leaveRideRoom(String rideId) async {
    if (_hubConnection == null || !_isConnected) return;
    
    try {
      await _hubConnection!.invoke('LeaveRide', args: [rideId]);
      debugPrint('SignalR: Left ride room: $rideId');
    } catch (e) {
      debugPrint('SignalR: Error leaving ride room: $e');
    }
  }
  
  /// Join all active rides room (admin monitoring)
  Future<void> joinAllRidesRoom() async {
    if (_hubConnection == null || !_isConnected) {
      debugPrint('SignalR: Not connected, cannot join all rides room');
      await initialize();
    }
    
    try {
      await _hubConnection!.invoke('JoinAllRidesRoom');
      debugPrint('SignalR: Joined all rides monitoring room');
    } catch (e) {
      debugPrint('SignalR: Error joining all rides room: $e');
    }
  }
  
  /// Send admin notification to user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
  }) async {
    if (_hubConnection == null || !_isConnected) return;
    
    try {
      await _hubConnection!.invoke('SendNotificationToUser', args: [
        userId,
        {
          'title': title,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        }
      ]);
      debugPrint('SignalR: Notification sent to user: $userId');
    } catch (e) {
      debugPrint('SignalR: Error sending notification: $e');
    }
  }
  
  /// Disconnect from SignalR hub
  Future<void> disconnect() async {
    if (_hubConnection != null && _isConnected) {
      try {
        await _hubConnection!.stop();
        _isConnected = false;
        debugPrint('SignalR: Disconnected');
      } catch (e) {
        debugPrint('SignalR: Error disconnecting: $e');
      }
    }
  }
  
  /// Dispose and clean up
  void dispose() {
    disconnect();
    _hubConnection = null;
    onLocationUpdate = null;
    onRideStatusUpdate = null;
    onNotificationReceived = null;
  }
}
