import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/signalr_service.dart';
import '../services/admin_auth_service.dart';

// SignalR service provider
final signalRServiceProvider = Provider<SignalRService>((ref) {
  final authService = AdminAuthService();
  return SignalRService(authService);
});

// Live tracking state
class LiveTrackingState {
  final Map<String, RideLocation> rideLocations;
  final bool isConnected;
  final String? errorMessage;
  final bool isLoading;
  
  const LiveTrackingState({
    this.rideLocations = const {},
    this.isConnected = false,
    this.errorMessage,
    this.isLoading = false,
  });
  
  LiveTrackingState copyWith({
    Map<String, RideLocation>? rideLocations,
    bool? isConnected,
    String? errorMessage,
    bool? isLoading,
  }) {
    return LiveTrackingState(
      rideLocations: rideLocations ?? this.rideLocations,
      isConnected: isConnected ?? this.isConnected,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Ride location model
class RideLocation {
  final String rideId;
  final double latitude;
  final double longitude;
  final DateTime lastUpdate;
  final String? driverName;
  final String? status;
  
  RideLocation({
    required this.rideId,
    required this.latitude,
    required this.longitude,
    required this.lastUpdate,
    this.driverName,
    this.status,
  });
  
  RideLocation copyWith({
    String? rideId,
    double? latitude,
    double? longitude,
    DateTime? lastUpdate,
    String? driverName,
    String? status,
  }) {
    return RideLocation(
      rideId: rideId ?? this.rideId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      driverName: driverName ?? this.driverName,
      status: status ?? this.status,
    );
  }
}

// Live tracking notifier
class LiveTrackingNotifier extends StateNotifier<LiveTrackingState> {
  final SignalRService _signalRService;
  
  LiveTrackingNotifier(this._signalRService) : super(const LiveTrackingState()) {
    _initializeSignalR();
  }
  
  /// Initialize SignalR connection and event handlers
  Future<void> _initializeSignalR() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Setup event handlers
      _signalRService.onLocationUpdate = _handleLocationUpdate;
      _signalRService.onRideStatusUpdate = _handleRideStatusUpdate;
      
      // Connect to SignalR
      await _signalRService.initialize();
      
      // Join all rides room for monitoring
      await _signalRService.joinAllRidesRoom();
      
      state = state.copyWith(
        isConnected: true,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        isLoading: false,
        errorMessage: 'Failed to connect: $e',
      );
    }
  }
  
  /// Handle location update from SignalR
  void _handleLocationUpdate(String rideId, double latitude, double longitude) {
    final updatedLocations = Map<String, RideLocation>.from(state.rideLocations);
    final existing = updatedLocations[rideId];
    
    updatedLocations[rideId] = RideLocation(
      rideId: rideId,
      latitude: latitude,
      longitude: longitude,
      lastUpdate: DateTime.now(),
      driverName: existing?.driverName,
      status: existing?.status,
    );
    
    state = state.copyWith(rideLocations: updatedLocations);
  }
  
  /// Handle ride status update from SignalR
  void _handleRideStatusUpdate(String rideId, String status) {
    final updatedLocations = Map<String, RideLocation>.from(state.rideLocations);
    final existing = updatedLocations[rideId];
    
    if (existing != null) {
      updatedLocations[rideId] = existing.copyWith(status: status);
      state = state.copyWith(rideLocations: updatedLocations);
    }
  }
  
  /// Add ride to tracking (with initial data)
  void addRideToTracking({
    required String rideId,
    required double latitude,
    required double longitude,
    String? driverName,
    String? status,
  }) {
    final updatedLocations = Map<String, RideLocation>.from(state.rideLocations);
    updatedLocations[rideId] = RideLocation(
      rideId: rideId,
      latitude: latitude,
      longitude: longitude,
      lastUpdate: DateTime.now(),
      driverName: driverName,
      status: status,
    );
    
    state = state.copyWith(rideLocations: updatedLocations);
  }
  
  /// Remove ride from tracking
  void removeRideFromTracking(String rideId) {
    final updatedLocations = Map<String, RideLocation>.from(state.rideLocations);
    updatedLocations.remove(rideId);
    state = state.copyWith(rideLocations: updatedLocations);
  }
  
  /// Join specific ride tracking room
  Future<void> joinRideTracking(String rideId) async {
    await _signalRService.joinRideRoom(rideId);
  }
  
  /// Leave specific ride tracking room
  Future<void> leaveRideTracking(String rideId) async {
    await _signalRService.leaveRideRoom(rideId);
  }
  
  /// Reconnect to SignalR
  Future<void> reconnect() async {
    await _signalRService.disconnect();
    await _initializeSignalR();
  }
  
  @override
  void dispose() {
    _signalRService.dispose();
    super.dispose();
  }
}

// Live tracking provider
final liveTrackingProvider = StateNotifierProvider<LiveTrackingNotifier, LiveTrackingState>((ref) {
  final signalRService = ref.watch(signalRServiceProvider);
  return LiveTrackingNotifier(signalRService);
});
