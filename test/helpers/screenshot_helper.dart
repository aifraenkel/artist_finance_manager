import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Helper class for taking screenshots during tests
///
/// NOTE: Widget tests don't support actual screenshots.
/// For real screenshots, use test/integration_test/ with flutter drive.
/// This helper creates log files to track test results.
class ScreenshotHelper {
  static Future<void> takeScreenshot({
    required WidgetTester tester,
    required String testName,
    required bool passed,
  }) async {
    try {
      // Create screenshots directory if it doesn't exist
      final screenshotsDir = Directory('test/screenshots');
      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }

      // Generate filename with timestamp
      final now = DateTime.now();
      final timestamp = DateFormat('yyyyMMdd-HHmmss').format(now);
      final status = passed ? 'OK' : 'FAIL';
      final cleanTestName = testName
          .replaceAll(' ', '-')
          .replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '')
          .toLowerCase();
      final filename = '$timestamp-$cleanTestName-$status.txt';
      final filePath = '${screenshotsDir.path}/$filename';

      // Save test result log
      await tester.pumpAndSettle();
      final file = File(filePath);
      await file.writeAsString('''
Test: $testName
Status: $status
Timestamp: $timestamp
Date: ${now.toIso8601String()}
''');

      print('📝 Test log saved: $filePath');
    } catch (e) {
      print('⚠️  Failed to save test log: $e');
    }
  }

  /// Wrapper for test execution with automatic screenshot on failure
  static Future<void> runTestWithScreenshot({
    required WidgetTester tester,
    required String testName,
    required Future<void> Function() testBody,
  }) async {
    bool passed = false;
    try {
      await testBody();
      passed = true;
    } catch (e) {
      passed = false;
      rethrow;
    } finally {
      await takeScreenshot(
        tester: tester,
        testName: testName,
        passed: passed,
      );
    }
  }
}
