/// Stub implementation for file downloads on non-web platforms.
///
/// This is a placeholder that gets replaced by the actual implementation
/// on supported platforms.
Future<void> downloadFileImpl(String content, String filename) async {
  throw UnsupportedError(
    'File downloads are only supported on web platform',
  );
}
