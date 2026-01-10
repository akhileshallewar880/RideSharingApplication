import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signalr_core/signalr_core.dart';
import '../../app/constants/app_constants.dart';

/// SignalR service for real-time communication between driver, passengers, and admin
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  HubConnection? _hubConnection;
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  String? _currentRideId;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Stream controllers for different event types
  final _locationUpdateController = StreamController<LocationUpdateEvent>.broadcast();
  final _tripStatusController = StreamController<TripStatusEvent>.broadcast();
  final _passengerUpdateController = StreamController<PassengerUpdateEvent>.broadcast();
  final _otpVerificationController = StreamController<OtpVerificationEvent>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  
  Stream<LocationUpdateEvent> get locationUpdates => _locationUpdateController.stream;
  Stream<TripStatusEvent> get tripStatusUpdates => _tripStatusController.stream;
  Stream<PassengerUpdateEvent> get passengerUpdates => _passengerUpdateController.stream;
  Stream<OtpVerificationEvent> get otpVerifications => _otpVerificationController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;
  
  /// Connect to SignalR hub
  Future<bool> connect() async {
    if (_isConnected && _hubConnection?.state == HubConnectionState.connected) {
      debugPrint('✅ SignalR already connected');
      return true;
    }
    
    try {
      final token = await _secureStorage.read(key: 'access_token');
      if (token == null) {
        debugPrint('❌ No access token found for SignalR connection');
        return false;
      }
      
      debugPrint('🔄 Connecting to SignalR at: ${AppConstants.socketBaseUrl}/tracking');
      
      // Create SignalR hub connection
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            '${AppConstants.socketBaseUrl}/tracking',
            HttpConnectionOptions(
              accessTokenFactory: () async => token,
              logging: (level, message) => debugPrint('SignalR: $message'),
              transport: HttpTransportType.webSockets, // Force WebSocket
              skipNegotiation: true, // Skip negotiation since we're forcing WebSockets
            ),
          )
          .withAutomaticReconnect([0, 2000, 5000, 10000, 30000]) // Retry delays in ms
          .build();
      
      _setupEventListeners();
      
      // Start connection
      await _hubConnection!.start();
      
      _isConnected = true;
      _connectionController.add(true);
      debugPrint('✅ SignalR connected successfully!');
      
      return true;
      
    } catch (e) {
      debugPrint('❌ SignalR connection error: $e');
      _isConnected = false;
      _connectionController.add(false);
      return false;
    }
  }
  
  /// Setup event listeners
  void _setupEventListeners() {
    if (_hubConnection == null) return;
    
    // Connection state handlers
    _hubConnection!.onclose((error) {
      _isConnected = false;
      _connectionController.add(false);
      debugPrint('❌ SignalR disconnected: ${error ?? "No error"}');
    });
    
    _hubConnection!.onreconnecting((error) {
      debugPrint('🔄 SignalR reconnecting: ${error ?? "No error"}');
      _connectionController.add(false);
    });
    
    _hubConnection!.onreconnected((connectionId) {
      _isConnected = true;
      _connectionController.add(true);
      debugPrint('✅ SignalR reconnected! ConnectionId: $connectionId');
      
      // Rejoin ride room after reconnection
      if (_currentRideId != null) {
        joinRide(_currentRideId!);
      }
    });
    
    // Listen for SignalR hub events (PascalCase method names from C# backend)
    
    // Event: JoinedRide confirmation
    _hubConnection!.on('JoinedRide', (args) {
      debugPrint('✅ Successfully joined ride: ${args?[0]}');
    });
    
    // Event: LocationUpdate from driver
    _hubConnection!.on('LocationUpdate', (args) {
      if (args != null && args.isNotEmpty) {
        _handleLocationUpdate(args[0]);
      }
    });
    
    // Event: RideMetrics (trip status, ETA, speed, distance)
    _hubConnection!.on('RideMetrics', (args) {
      if (args != null && args.isNotEmpty) {
        _handleTripStatus(args[0]);
      }
    });
    
    // Event: PassengerBoarded
    _hubConnection!.on('PassengerBoarded', (args) {
      if (args != null && args.isNotEmpty) {
        _handlePassengerUpdate(args[0]);
      }
    });
    
    // Event: PaymentCollected
    _hubConnection!.on('PaymentCollected', (args) {
      if (args != null && args.isNotEmpty) {
        _handlePassengerUpdate(args[0]);
      }
    });
    
    // Event: OtpVerified (new event for OTP verification)
    _hubConnection!.on('OtpVerified', (args) {
      if (args != null && args.isNotEmpty) {
        _handleOtpVerification(args[0]);
      }
    });
    
    // Event: Error messages from hub
    _hubConnection!.on('Error', (args) {
      debugPrint('❌ SignalR hub error: ${args?[0]}');
    });
  }
  
  /// Join a ride room for real-time updates
  Future<void> joinRide(String rideId) async {
    if (!_isConnected || _hubConnection == null) {
      debugPrint('❌ Cannot join ride: SignalR not connected');
      return;
    }
    
    try {
      _currentRideId = rideId;
      
      // Invoke SignalR hub method: JoinRide(string rideId)
      await _hubConnection!.invoke('JoinRide', args: [rideId]);
      debugPrint('✅ Joined ride room: $rideId');
      
    } catch (e) {
      debugPrint('❌ Error joining ride: $e');
    }
  }
  
  /// Leave current ride room
  Future<void> leaveRide() async {
    if (_currentRideId != null && _isConnected && _hubConnection != null) {
      try {
        // Invoke SignalR hub method: LeaveRide(string rideId)
        await _hubConnection!.invoke('LeaveRide', args: [_currentRideId]);
        debugPrint('✅ Left ride room: $_currentRideId');
        _currentRideId = null;
        
      } catch (e) {
        debugPrint('❌ Error leaving ride: $e');
      }
    }
  }
  
  /// Send driver location update
  Future<void> sendLocationUpdate({
    required String rideId,
    required double latitude,
    required double longitude,
    required double speed,
    required double heading,
  }) async {
    if (!_isConnected || _hubConnection == null) {
      debugPrint('❌ Cannot send location: SignalR not connected');
      return;
    }
    
    try {
      final data = {
        'rideId': rideId,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'speed': speed,
          'heading': heading,
          'accuracy': 10.0,
        },
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
      
      // Invoke SignalR hub method: SendLocationUpdate(object data)
      await _hubConnection!.invoke('SendLocationUpdate', args: [data]);
      debugPrint('📡 Location update sent via SignalR');
      
    } catch (e) {
      debugPrint('❌ Error sending location update: $e');
    }
  }
  
  /// Handle incoming location update
  void _handleLocationUpdate(dynamic data) {
    try {
      final event = LocationUpdateEvent.fromJson(data as Map<String, dynamic>);
      _locationUpdateController.add(event);
      debugPrint('📍 Location update received: ${event.latitude}, ${event.longitude}');
    } catch (e) {
      debugPrint('❌ Error parsing location update: $e');
    }
  }
  
  /// Handle trip status update
  void _handleTripStatus(dynamic data) {
    try {
      final event = TripStatusEvent.fromJson(data as Map<String, dynamic>);
      _tripStatusController.add(event);
      debugPrint('🚗 Trip status received: ${event.status}');
    } catch (e) {
      debugPrint('❌ Error parsing trip status: $e');
    }
  }
  
  /// Handle passenger update
  void _handlePassengerUpdate(dynamic data) {
    try {
      final event = PassengerUpdateEvent.fromJson(data as Map<String, dynamic>);
      _passengerUpdateController.add(event);
      debugPrint('👤 Passenger update received: ${event.updateType}');
    } catch (e) {
      debugPrint('❌ Error parsing passenger update: $e');
    }
  }
  
  /// Handle OTP verification event
  void _handleOtpVerification(dynamic data) {
    try {
      final event = OtpVerificationEvent.fromJson(data as Map<String, dynamic>);
      _otpVerificationController.add(event);
      debugPrint('🎉 OTP verified event received: ${event.bookingId}');
    } catch (e) {
      debugPrint('❌ Error parsing OTP verification: $e');
    }
  }
  
  /// Notify passenger boarding status
  Future<void> notifyPassengerBoarded({
    required String rideId,
    required String bookingId,
    required String passengerName,
  }) async {
    if (!_isConnected || _hubConnection == null) return;
    
    try {
      // Invoke SignalR hub method: NotifyPassengerBoarded
      await _hubConnection!.invoke('NotifyPassengerBoarded', args: [
        rideId,
        {
          'passengerId': bookingId,
          'passengerName': passengerName,
          'stopName': 'Current Stop',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }
      ]);
      debugPrint('✅ Passenger boarded notification sent');
      
    } catch (e) {
      debugPrint('❌ Error notifying passenger boarded: $e');
    }
  }
  
  /// Notify payment collected
  Future<void> notifyPaymentCollected({
    required String rideId,
    required String bookingId,
    required double amount,
  }) async {
    if (!_isConnected || _hubConnection == null) return;
    
    try {
      // Invoke SignalR hub method: NotifyPaymentCollected
      await _hubConnection!.invoke('NotifyPaymentCollected', args: [
        rideId,
        {
          'passengerId': bookingId,
          'amount': amount,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }
      ]);
      debugPrint('✅ Payment collected notification sent');
      
    } catch (e) {
      debugPrint('❌ Error notifying payment collected: $e');
    }
  }
  
  /// Disconnect from SignalR
  Future<void> disconnect() async {
    try {
      await leaveRide();
      await _hubConnection?.stop();
      _hubConnection = null;
      _isConnected = false;
      _currentRideId = null;
      _connectionController.add(false);
      debugPrint('✅ SignalR disconnected');
    } catch (e) {
      debugPrint('❌ Error disconnecting SignalR: $e');
    }
  }
  
  /// Dispose all resources
  Future<void> dispose() async {
    await disconnect();
    await _locationUpdateController.close();
    await _tripStatusController.close();
    await _passengerUpdateController.close();
    await _otpVerificationController.close();
    await _connectionController.close();
  }
}

/// Location update event model
class LocationUpdateEvent {
  final String rideId;
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final DateTime timestamp;
  final double? estimatedArrival; // minutes
  final double? remainingDistance; // kilometers
  
  LocationUpdateEvent({
    required this.rideId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    required this.timestamp,
    this.estimatedArrival,
    this.remainingDistance,
  });
  
  factory LocationUpdateEvent.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? json;
    
    return LocationUpdateEvent(
      rideId: json['rideId'] as String? ?? '',
      latitude: (location['latitude'] as num).toDouble(),
      longitude: (location['longitude'] as num).toDouble(),
      speed: (location['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (location['heading'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(
        location['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      ),
      estimatedArrival: (json['estimatedArrival'] as num?)?.toDouble(),
      remainingDistance: (json['remainingDistance'] as num?)?.toDouble(),
    );
  }
}

/// Trip status event model
class TripStatusEvent {
  final String rideId;
  final String status;
  final DateTime timestamp;
  final String? message;
  final Map<String, dynamic>? additionalData;
  
  TripStatusEvent({
    required this.rideId,
    required this.status,
    required this.timestamp,
    this.message,
    this.additionalData,
  });
  
  factory TripStatusEvent.fromJson(Map<String, dynamic> json) {
    return TripStatusEvent(
      rideId: json['rideId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      ),
      message: json['message'] as String?,
      additionalData: json['data'] as Map<String, dynamic>?,
    );
  }
}

/// Passenger update event model
class PassengerUpdateEvent {
  final String rideId;
  final String bookingId;
  final String passengerName;
  final String updateType; // boarded, payment_collected, dropped
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  
  PassengerUpdateEvent({
    required this.rideId,
    required this.bookingId,
    required this.passengerName,
    required this.updateType,
    required this.timestamp,
    this.data,
  });
  
  factory PassengerUpdateEvent.fromJson(Map<String, dynamic> json) {
    return PassengerUpdateEvent(
      rideId: json['rideId'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      passengerName: json['passengerName'] as String? ?? '',
      updateType: json['updateType'] as String? ?? json['type'] as String? ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      ),
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

/// Event model for OTP verification
class OtpVerificationEvent {
  final String rideId;
  final String bookingId;
  final String bookingNumber;
  final String passengerName;
  final DateTime timestamp;
  final bool isVerified;
  
  OtpVerificationEvent({
    required this.rideId,
    required this.bookingId,
    required this.bookingNumber,
    required this.passengerName,
    required this.timestamp,
    required this.isVerified,
  });
  
  factory OtpVerificationEvent.fromJson(Map<String, dynamic> json) {
    return OtpVerificationEvent(
      rideId: json['rideId'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      bookingNumber: json['bookingNumber'] as String? ?? '',
      passengerName: json['passengerName'] as String? ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      ),
      isVerified: json['isVerified'] as bool? ?? true,
    );
  }
}
