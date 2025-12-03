import 'observability_service.dart';
import 'user_preferences.dart';

/// Stub implementation for non-web platforms (iOS, Android)
class ObservabilityServiceImpl implements ObservabilityService {
  // Note: _userPreferences is kept for interface consistency with web implementation
  // even though this is a no-op stub. Mobile platforms could use this in the future
  // for platform-specific analytics (e.g., Firebase Analytics, Crashlytics)
  // ignore: unused_field
  final UserPreferences? _userPreferences;

  ObservabilityServiceImpl({UserPreferences? userPreferences})
      : _userPreferences = userPreferences;
  @override
  void trackEvent(String name, {Map<String, dynamic>? attributes}) {
    // No-op on mobile platforms
    // You could add mobile-specific analytics here (Firebase, etc.)
  }

  @override
  void trackMeasurement(String name, double value,
      {Map<String, String>? attributes}) {
    // No-op on mobile platforms
  }

  @override
  void trackError(dynamic error,
      {StackTrace? stackTrace, Map<String, dynamic>? context}) {
    // No-op on mobile platforms
    // You could add Crashlytics or similar here
  }

  @override
  void log(String message,
      {String level = 'info', Map<String, dynamic>? context}) {
    // No-op on mobile platforms
  }

  @override
  void setUser(String userId, {String? email, String? username}) {
    // No-op on mobile platforms
  }
}

/// Factory function to get the observability service
ObservabilityService getObservabilityService(
        {UserPreferences? userPreferences}) =>
    ObservabilityServiceImpl(userPreferences: userPreferences);
