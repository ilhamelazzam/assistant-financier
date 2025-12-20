import 'dart:typed_data';

/// No-op implementation for non-web platforms.
void triggerWebDownload(Uint8List bytes, String filename) {
  // Intentionally empty on mobile/desktop.
}
