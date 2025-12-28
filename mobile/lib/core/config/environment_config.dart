/// Environment configuration
/// Use this file to define environment-specific settings
/// DO NOT commit .env files with sensitive data to version control
enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  // Current environment - change this based on build configuration
  static const Environment currentEnvironment = Environment.development;

  // API Base URLs
  static const Map<Environment, String> _apiBaseUrls = {
    Environment.development: 'http://192.168.88.9:5056', // Replace with your local IP
    Environment.staging: 'https://staging-api.vanyatra.com',
    Environment.production: 'https://api.vanyatra.com',
  };

  // API Version
  static const String apiVersion = '/api/v1';

  // Getters
  static String get baseUrl => _apiBaseUrls[currentEnvironment]!;
  static String get apiBaseUrl => '$baseUrl$apiVersion';
  
  static String get socketBaseUrl {
    final uri = Uri.parse(baseUrl);
    return 'http://${uri.host}:${uri.port}';
  }

  // Feature Flags
  static bool get enableAnalytics => currentEnvironment == Environment.production;
  static bool get enableCrashReporting => currentEnvironment == Environment.production;
  static bool get showDebugInfo => currentEnvironment == Environment.development;

  // Timeouts
  static int get connectionTimeout {
    switch (currentEnvironment) {
      case Environment.development:
        return 120; // Longer timeout for development
      case Environment.staging:
      case Environment.production:
        return 60;
    }
  }

  static int get receiveTimeout {
    switch (currentEnvironment) {
      case Environment.development:
        return 120;
      case Environment.staging:
      case Environment.production:
        return 60;
    }
  }

  // Log level
  static bool get verboseLogging => currentEnvironment != Environment.production;
}
