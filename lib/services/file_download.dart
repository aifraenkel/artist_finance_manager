import 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart';

/// Download a file with the given content and filename.
///
/// This function uses platform-specific implementations:
/// - On web: Uses browser download API
/// - On other platforms: Stub implementation (not supported)
Future<void> downloadFile(String content, String filename) async {
  return downloadFileImpl(content, filename);
}
