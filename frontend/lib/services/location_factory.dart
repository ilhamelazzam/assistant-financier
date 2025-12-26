/// Simple hook to bypass geolocation during tests.
class LocationFactory {
  /// When provided, UI screens will use this resolver instead of
  /// requesting device location.
  static Future<String?> Function()? resolver;
}
