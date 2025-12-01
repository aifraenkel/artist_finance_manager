import 'dart:js_interop';
import 'observability_service.dart';

// External JS bindings for Faro
@JS('window.faro')
external JSAny? get _windowFaro;

/// Web implementation using Grafana Faro
class ObservabilityServiceImpl implements ObservabilityService {
  bool get _isFaroAvailable {
    try {
      return _windowFaro != null;
    } catch (e) {
      return false;
    }
  }

  @override
  void trackEvent(String name, {Map<String, dynamic>? attributes}) {
    if (!_isFaroAvailable) return;

    try {
      // Call Faro API using js_interop
      // window.faro.api.pushEvent(name, attributes)
      final code = '''
        if (window.faro && window.faro.api && window.faro.api.pushEvent) {
          window.faro.api.pushEvent('$name', ${_jsonEncode(attributes ?? {})});
        }
      ''';
      _evalJS(code);
    } catch (e) {
      print('Failed to track event: $e');
    }
  }

  @override
  void trackMeasurement(String name, double value,
      {Map<String, String>? attributes}) {
    if (!_isFaroAvailable) return;

    try {
      final measurement = {
        'type': name,
        'values': {'value': value},
        'context': attributes ?? {},
      };
      final code = '''
        if (window.faro && window.faro.api && window.faro.api.pushMeasurement) {
          window.faro.api.pushMeasurement(${_jsonEncode(measurement)});
        }
      ''';
      _evalJS(code);
    } catch (e) {
      print('Failed to track measurement: $e');
    }
  }

  @override
  void trackError(dynamic error,
      {StackTrace? stackTrace, Map<String, dynamic>? context}) {
    if (!_isFaroAvailable) return;

    try {
      final errorData = {
        'message': error.toString(),
        'stack': stackTrace?.toString() ?? '',
        'context': context ?? {},
      };
      final code = '''
        if (window.faro && window.faro.api && window.faro.api.pushError) {
          window.faro.api.pushError(${_jsonEncode(errorData)});
        }
      ''';
      _evalJS(code);
    } catch (e) {
      print('Failed to track error: $e');
    }
  }

  @override
  void log(String message,
      {String level = 'info', Map<String, dynamic>? context}) {
    if (!_isFaroAvailable) return;

    try {
      final logData = {
        'level': level,
        'context': context ?? {},
      };
      final code = '''
        if (window.faro && window.faro.api && window.faro.api.pushLog) {
          window.faro.api.pushLog(['${_escapeString(message)}'], ${_jsonEncode(logData)});
        }
      ''';
      _evalJS(code);
    } catch (e) {
      print('Failed to log message: $e');
    }
  }

  @override
  void setUser(String userId, {String? email, String? username}) {
    if (!_isFaroAvailable) return;

    try {
      final userData = {
        'id': userId,
        if (email != null) 'email': email,
        if (username != null) 'username': username,
      };
      final code = '''
        if (window.faro && window.faro.api && window.faro.api.setUser) {
          window.faro.api.setUser(${_jsonEncode(userData)});
        }
      ''';
      _evalJS(code);
    } catch (e) {
      print('Failed to set user: $e');
    }
  }

  // Helper methods
  String _jsonEncode(Map<String, dynamic> data) {
    final entries = data.entries.map((e) {
      final key = e.key;
      final value = e.value;
      if (value == null) {
        return '"$key": null';
      } else if (value is String) {
        return '"$key": "${_escapeString(value)}"';
      } else if (value is num) {
        return '"$key": $value';
      } else if (value is bool) {
        return '"$key": $value';
      } else if (value is Map) {
        return '"$key": ${_jsonEncode(value.cast<String, dynamic>())}';
      } else {
        return '"$key": "${_escapeString(value.toString())}"';
      }
    }).join(', ');
    return '{$entries}';
  }

  String _escapeString(String str) {
    return str
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  void _evalJS(String code) {
    // Use eval to execute JS code
    final jsCode = 'eval'.toJS;
    if (jsCode is JSFunction) {
      (jsCode as JSFunction).callAsFunction(null, code.toJS);
    }
  }
}

/// Factory function to get the observability service
ObservabilityService getObservabilityService() => ObservabilityServiceImpl();
