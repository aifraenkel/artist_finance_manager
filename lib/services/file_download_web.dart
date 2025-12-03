import 'dart:html' as html;
import 'dart:convert';

/// Web implementation for file downloads.
///
/// Uses the browser's download API to trigger a file download.
Future<void> downloadFileImpl(String content, String filename) async {
  // Create a Blob from the content
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'text/csv', );

  // Create a download link
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';

  // Add to document, click, and remove
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  // Clean up the URL
  html.Url.revokeObjectUrl(url);
}
