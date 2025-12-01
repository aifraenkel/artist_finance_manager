/// Stub for non-web platforms
/// This provides a no-op window.history for platforms that don't support dart:html

class _Window {
  final _History history = _History();
}

class _History {
  void replaceState(dynamic data, String title, String? url) {
    // No-op on non-web platforms
  }
}

final window = _Window();
