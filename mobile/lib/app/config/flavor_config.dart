/// Defines which app variant is being built.
/// Set once at startup via [FlavorConfig.initialize] in each entry point.
enum AppFlavor { driver, passenger }

class FlavorConfig {
  FlavorConfig._();

  static AppFlavor? _flavor;

  static void initialize(AppFlavor flavor) {
    assert(_flavor == null, 'FlavorConfig already initialized');
    _flavor = flavor;
  }

  static AppFlavor get flavor {
    assert(_flavor != null, 'FlavorConfig not initialized — call initialize() in main_*.dart');
    return _flavor!;
  }

  static bool get isDriver => flavor == AppFlavor.driver;
  static bool get isPassenger => flavor == AppFlavor.passenger;

  static String get appName => isDriver ? 'VanYatra Driver' : 'VanYatra';

  /// Initial route after successful auth.
  static String get homeRoute =>
      isDriver ? '/driver/dashboard' : '/passenger/home';
}
