import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_finance_manager/services/device_info_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceInfoService', () {
    setUp(() async {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('getDeviceId generates and persists a unique ID', () async {
      final deviceId1 = await DeviceInfoService.getDeviceId();
      expect(deviceId1, isNotEmpty);
      expect(deviceId1.length, greaterThan(20)); // UUID should be long

      // Second call should return the same ID
      final deviceId2 = await DeviceInfoService.getDeviceId();
      expect(deviceId2, equals(deviceId1));
    });

    test('getDeviceId returns different IDs after clearing', () async {
      final deviceId1 = await DeviceInfoService.getDeviceId();
      
      await DeviceInfoService.clearDeviceId();
      
      final deviceId2 = await DeviceInfoService.getDeviceId();
      expect(deviceId2, isNot(equals(deviceId1)));
    });

    test('getDeviceName returns a non-empty string', () async {
      final deviceName = await DeviceInfoService.getDeviceName();
      expect(deviceName, isNotEmpty);
    });

    test('getDeviceInfo returns comprehensive device information', () async {
      final deviceInfo = await DeviceInfoService.getDeviceInfo();
      
      expect(deviceInfo, isNotNull);
      expect(deviceInfo['deviceId'], isNotEmpty);
      expect(deviceInfo['deviceName'], isNotEmpty);
      expect(deviceInfo['platform'], isNotEmpty);
      expect(deviceInfo['timestamp'], isNotEmpty);
      
      // Verify platform is one of the expected values
      final validPlatforms = ['web', 'android', 'ios', 'macos', 'windows', 'linux'];
      expect(validPlatforms, contains(deviceInfo['platform']));
    });

    test('clearDeviceId removes stored device ID', () async {
      // Generate a device ID
      await DeviceInfoService.getDeviceId();
      
      // Clear it
      await DeviceInfoService.clearDeviceId();
      
      // Verify it was removed from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedId = prefs.getString('device_id');
      expect(storedId, isNull);
    });

    test('multiple calls to getDeviceInfo return consistent deviceId', () async {
      final info1 = await DeviceInfoService.getDeviceInfo();
      final info2 = await DeviceInfoService.getDeviceInfo();
      
      expect(info1['deviceId'], equals(info2['deviceId']));
    });
  });
}
