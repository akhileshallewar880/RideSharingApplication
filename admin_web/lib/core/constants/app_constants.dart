class AppConstants {
  // API Configuration
  // For production deployment, use AdminEnvironmentConfig from '../config/environment_config.dart'
  static const String baseUrl = 'http://57.159.31.172/api/v1';
  // Note: Updated to point to production server through nginx on port 80
  // Nginx proxies /api/ requests to backend on port 8000
  static const String authEndpoint = '/auth';
  static const String driversEndpoint = '/drivers';
  static const String ridesEndpoint = '/rides';
  static const String usersEndpoint = '/users';
  static const String analyticsEndpoint = '/analytics';
  static const String vehiclesEndpoint = '/vehicles';
  
  // Storage Keys
  static const String tokenKey = 'admin_auth_token';
  static const String refreshTokenKey = 'admin_refresh_token';
  static const String userDataKey = 'admin_user_data';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Document Types
  static const String documentTypeLicense = 'license';
  static const String documentTypeRC = 'rc_book';
  static const String documentTypePhoto = 'profile_photo';
  
  // Verification Status
  static const String verificationPending = 'pending';
  static const String verificationApproved = 'approved';
  static const String verificationRejected = 'rejected';
  
  // Ride Status
  static const String rideRequested = 'requested';
  static const String rideAccepted = 'accepted';
  static const String rideInProgress = 'in_progress';
  static const String rideCompleted = 'completed';
  static const String rideCancelled = 'cancelled';
  
  // Vehicle Types
  static const List<String> vehicleTypes = [
    'car',
    'suv',
    'van',
    'bus',
    'bike',
    'auto',
  ];
  
  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
  
  // Validation
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int minPasswordLength = 8;
  static const int phoneNumberLength = 10;
  
  // File Upload
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration refreshInterval = Duration(seconds: 30);
  
  // Chart Colors
  static const List<String> chartColors = [
    '#1a237e',
    '#ff6f00',
    '#4caf50',
    '#f44336',
    '#2196f3',
    '#9c27b0',
    '#00bcd4',
    '#ff9800',
  ];
}
