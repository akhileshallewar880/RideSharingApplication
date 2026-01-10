/// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'VanYatra';
  static const String appVersion = '1.0.0';
  
  // API Endpoints - Now configured via EnvironmentConfig
  // Import '../core/config/environment_config.dart' to use these
  static String get baseUrl => 'http://57.159.31.172:8000'; // Production server
  static const String apiVersion = '/api/v1';
  
  // Full API URL
  static String get apiBaseUrl => '$baseUrl$apiVersion';
  
  // SignalR WebSocket URL for real-time tracking (SignalR uses HTTP/HTTPS, not ws://)
  static String get socketBaseUrl {
    final uri = Uri.parse(baseUrl);
    return 'http://${uri.host}:${uri.port}';  // SignalR endpoint at /tracking
  }
  
  // Note: For production deployment, use EnvironmentConfig instead of hardcoded URLs
  // Example: EnvironmentConfig.apiBaseUrl
  
  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserType = 'user_type'; // 'passenger' or 'driver'
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyOnboardingCompleted = 'onboarding_completed';
  
  // User Types
  static const String userTypePassenger = 'passenger';
  static const String userTypeDriver = 'driver';
  
  // Ride Status
  static const String rideStatusScheduled = 'scheduled';
  static const String rideStatusUpcoming = 'upcoming';
  static const String rideStatusActive = 'active';
  static const String rideStatusCompleted = 'completed';
  static const String rideStatusCancelled = 'cancelled';
  
  // Legacy ride statuses (for backward compatibility)
  static const String rideStatusSearching = 'searching';
  static const String rideStatusMatched = 'matched';
  static const String rideStatusOngoing = 'ongoing';
  
  // Booking Status
  static const String bookingStatusPending = 'pending';
  static const String bookingStatusConfirmed = 'confirmed';
  static const String bookingStatusActive = 'active';
  static const String bookingStatusCompleted = 'completed';
  static const String bookingStatusCancelled = 'cancelled';
  static const String bookingStatusRefunded = 'refunded';
  
  // Cancellation Type
  static const String cancellationTypePassenger = 'passenger';
  static const String cancellationTypeDriver = 'driver';
  static const String cancellationTypeSystem = 'system';
  
  // Notification Types
  static const String notificationRideCreated = 'ride_created';
  static const String notificationBookingConfirmed = 'booking_confirmed';
  static const String notificationRideCancelled = 'ride_cancelled';
  static const String notificationBookingCancelled = 'booking_cancelled';
  static const String notificationBookingNoShow = 'booking_noshow';
  static const String notificationRideStarted = 'ride_started';
  static const String notificationRideCompleted = 'ride_completed';
  
  // Payment Status
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusPaid = 'paid';
  static const String paymentStatusRefunded = 'refunded';
  static const String paymentStatusFailed = 'failed';
  
  // Payment Methods
  static const String paymentCash = 'cash';
  static const String paymentUPI = 'upi';
  static const String paymentCard = 'card';
  static const String paymentWallet = 'wallet';
  
  // Vehicle Types
  static const String vehicleAuto = 'auto';
  static const String vehicleBike = 'bike';
  static const String vehicleCar = 'car';
  static const String vehicleShared = 'shared';
  
  // Map Settings
  static const double defaultMapZoom = 15.0;
  static const double defaultMapTilt = 0.0;
  static const double defaultMapBearing = 0.0;
  
  // Animation Durations (milliseconds)
  static const int animationFast = 200;
  static const int animationNormal = 300;
  static const int animationSlow = 400;
  
  // Timeouts (seconds)
  static const int connectionTimeout = 60;
  static const int receiveTimeout = 60;
  
  // Pagination
  static const int pageSize = 20;
  
  // Regex Patterns
  static const String phonePattern = r'^[6-9]\d{9}$'; // Indian mobile numbers
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String otpPattern = r'^\d{4}$'; // 4-digit OTP as per API spec
  
  // Languages
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'हिंदी'},
    {'code': 'te', 'name': 'తెలుగు'},
    {'code': 'mr', 'name': 'मराठी'},
  ];
  
  // Support
  static const String supportPhone = '+91-1234567890';
  static const String supportEmail = 'support@vanyatra.com';
  static const String supportWhatsApp = '+91-1234567890';
  
  // Driver Support Contact (for verification pending screen)
  static const String supportPhoneNumber = '+91-7709456789';
  static const String officeAddress = 'Main Road, Allapalli, Gadchiroli - 442707, Maharashtra';
  
  // Social Media (if applicable)
  static const String facebookUrl = 'https://facebook.com/vanyatra';
  static const String instagramUrl = 'https://instagram.com/vanyatra';
  static const String twitterUrl = 'https://twitter.com/vanyatra';
}
