import 'observability_service_stub.dart'
    if (dart.library.html) 'observability_service_web.dart';

/// Observability service for tracking events, metrics, and errors
/// Uses Grafana Faro on web, no-op on mobile platforms
abstract class ObservabilityService {
  /// Factory constructor that returns the appropriate implementation
  factory ObservabilityService() => getObservabilityService();

  /// Track a custom event
  void trackEvent(String name, {Map<String, dynamic>? attributes});

  /// Track a measurement (metric)
  void trackMeasurement(String name, double value,
      {Map<String, String>? attributes});

  /// Track an error
  void trackError(dynamic error,
      {StackTrace? stackTrace, Map<String, dynamic>? context});

  /// Log a message
  void log(String message,
      {String level = 'info', Map<String, dynamic>? context});

  /// Set user information
  void setUser(String userId, {String? email, String? username});
}
