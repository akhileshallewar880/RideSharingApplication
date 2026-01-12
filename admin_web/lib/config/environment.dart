class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net',
  );
  
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: true,
  );
  
  // Use relative path for same-server deployment
  static String get apiUrl => '/api/v1';
}
