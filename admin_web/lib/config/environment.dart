class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://57.159.31.172:8000',
  );
  
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: true,
  );
  
  // Use relative path for same-server deployment
  static String get apiUrl => '/api/v1';
}
