/// Environment configuration for Admin Web App
/// Use this file to define environment-specific settings
enum AdminEnvironment {
  development,
  staging,
  production,
}

class AdminEnvironmentConfig {
  // Current environment - change this based on build configuration
  static const AdminEnvironment currentEnvironment = AdminEnvironment.development;

  // API Base URLs
  static const Map<AdminEnvironment, String> _apiBaseUrls = {
    AdminEnvironment.development: 'http://192.168.88.14:5056', // Local Server API
    AdminEnvironment.staging: 'https://staging-api.vanyatra.com',
    AdminEnvironment.production: 'https://api.vanyatra.com',
  };

  // API Version
  static const String apiVersion = '/api/v1';

  // Getters
  static String get baseUrl => _apiBaseUrls[currentEnvironment]!;
  static String get apiBaseUrl => '$baseUrl$apiVersion';

  // Admin specific endpoints
  static String get notificationsUrl => '$apiBaseUrl/admin/notifications';
  static String get bannersUrl => '$apiBaseUrl/admin/banners';
  static String get locationsUrl => '$apiBaseUrl/admin/locations';
  static String get driversUrl => '$baseUrl$apiVersion'; // For driver service

  // Feature Flags
  static bool get enableAnalytics => currentEnvironment == AdminEnvironment.production;
  static bool get showDebugInfo => currentEnvironment == AdminEnvironment.development;

  // Timeouts
  static int get connectionTimeout {
    switch (currentEnvironment) {
      case AdminEnvironment.development:
        return 120; // Longer timeout for development
      case AdminEnvironment.staging:
      case AdminEnvironment.production:
        return 60;
    }
  }

  // Log level
  static bool get verboseLogging => currentEnvironment != AdminEnvironment.production;
  
  // Image base URL
  static String getImageUrl(String imagePath) {
    return '$baseUrl$imagePath';
  }
}
