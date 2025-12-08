import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Mock Firebase implementation for testing
class MockFirebasePlatform extends FirebasePlatform with MockPlatformInterfaceMixin {
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return MockFirebaseAppPlatform();
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return MockFirebaseAppPlatform();
  }

  @override
  List<FirebaseAppPlatform> get apps => [MockFirebaseAppPlatform()];
}

/// Mock Firebase App implementation
class MockFirebaseAppPlatform extends FirebaseAppPlatform with MockPlatformInterfaceMixin {
  MockFirebaseAppPlatform() : super('[DEFAULT]', const FirebaseOptions(
    apiKey: 'fake-api-key',
    appId: 'fake-app-id',
    messagingSenderId: 'fake-sender-id',
    projectId: 'fake-project-id',
  ));
}

/// Sets up Firebase mocks for testing
void setupFirebaseAuthMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FirebasePlatform.instance = MockFirebasePlatform();
}
