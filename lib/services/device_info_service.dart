import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for collecting and managing device information
///
/// Provides device fingerprinting and tracking for security and analytics.
/// Implements OWASP recommendations for device tracking without PII.
class DeviceInfoService {
  static const String _deviceIdKey = 'device_id';
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const Uuid _uuid = Uuid();

  /// Get or create a unique device ID
  ///
  /// Device ID is generated once and persisted across app sessions.
  /// This is used for tracking sign-ins from different devices.
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      deviceId = _uuid.v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  /// Get device name/model for display purposes
  ///
  /// Returns a human-readable device name without PII.
  static Future<String> getDeviceName() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return '${webInfo.browserName} on ${webInfo.platform}';
      } else {
        // For mobile platforms
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidInfo = await _deviceInfo.androidInfo;
          return '${androidInfo.brand} ${androidInfo.model}';
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          return '${iosInfo.name} (${iosInfo.model})';
        }
      }
    } catch (e) {
      print('Error getting device name: $e');
    }

    return 'Unknown Device';
  }

  /// Get comprehensive device information
  ///
  /// Returns a map of device information suitable for logging and analytics.
  /// Excludes PII per OWASP privacy guidelines.
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceId = await getDeviceId();
    final deviceName = await getDeviceName();

    final info = <String, dynamic>{
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': _getPlatform(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        info['browser'] = webInfo.browserName.toString();
        info['browserVersion'] = webInfo.appVersion;
        info['userAgent'] = webInfo.userAgent;
      } else {
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidInfo = await _deviceInfo.androidInfo;
          info['osVersion'] = androidInfo.version.release;
          info['manufacturer'] = androidInfo.manufacturer;
          info['model'] = androidInfo.model;
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          info['osVersion'] = iosInfo.systemVersion;
          info['model'] = iosInfo.model;
        }
      }
    } catch (e) {
      print('Error collecting device info: $e');
    }

    return info;
  }

  /// Get platform name
  static String _getPlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  /// Clear stored device ID (for testing or privacy purposes)
  static Future<void> clearDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
  }
}
