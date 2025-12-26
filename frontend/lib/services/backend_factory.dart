import 'backend_api.dart';

/// Provides a single hook to override the backend client in tests
/// without rewriting every screen.
class BackendFactory {
  /// When set (typically in tests), all screens using [create] will
  /// receive this instance instead of hitting the real backend.
  static BackendApi? overrideInstance;

  static BackendApi create() => overrideInstance ?? BackendApi();
}
