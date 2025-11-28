import 'dart:js_util' as js_util;
import 'dart:html' as html;
import 'observability_service.dart';

/// Web implementation using Grafana Faro
class ObservabilityServiceImpl implements ObservabilityService {
  // Check if Faro is available
  bool get _isFaroAvailable {
    try {
      return js_util.hasProperty(html.window, 'faro');
    } catch (e) {
      return false;
    }
  }

  dynamic get _faro {
    if (!_isFaroAvailable) return null;
    return js_util.getProperty(html.window, 'faro');
  }

  dynamic get _faroApi {
    final faro = _faro;
    if (faro == null) return null;
    return js_util.getProperty(faro, 'api');
  }

  @override
  void trackEvent(String name, {Map<String, dynamic>? attributes}) {
    final api = _faroApi;
    if (api == null) return;

    try {
      js_util.callMethod(api, 'pushEvent', [
        name,
        js_util.jsify(attributes ?? {}),
      ]);
    } catch (e) {
      print('Failed to track event: $e');
    }
  }

  @override
  void trackMeasurement(String name, double value, {Map<String, String>? attributes}) {
    final api = _faroApi;
    if (api == null) return;

    try {
      js_util.callMethod(api, 'pushMeasurement', [
        js_util.jsify({
          'type': name,
          'values': {'value': value},
          'context': attributes ?? {},
        }),
      ]);
    } catch (e) {
      print('Failed to track measurement: $e');
    }
  }

  @override
  void trackError(dynamic error, {StackTrace? stackTrace, Map<String, dynamic>? context}) {
    final api = _faroApi;
    if (api == null) return;

    try {
      final errorData = js_util.jsify({
        'message': error.toString(),
        'stack': stackTrace?.toString() ?? '',
        'context': context ?? {},
      });

      js_util.callMethod(api, 'pushError', [errorData]);
    } catch (e) {
      print('Failed to track error: $e');
    }
  }

  @override
  void log(String message, {String level = 'info', Map<String, dynamic>? context}) {
    final api = _faroApi;
    if (api == null) return;

    try {
      js_util.callMethod(api, 'pushLog', [
        js_util.jsify([message]),
        js_util.jsify({
          'level': level,
          'context': context ?? {},
        }),
      ]);
    } catch (e) {
      print('Failed to log message: $e');
    }
  }

  @override
  void setUser(String userId, {String? email, String? username}) {
    final api = _faroApi;
    if (api == null) return;

    try {
      js_util.callMethod(api, 'setUser', [
        js_util.jsify({
          'id': userId,
          'email': email,
          'username': username,
        }),
      ]);
    } catch (e) {
      print('Failed to set user: $e');
    }
  }
}

/// Factory function to get the observability service
ObservabilityService getObservabilityService() => ObservabilityServiceImpl();
