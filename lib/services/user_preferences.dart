import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user preferences including analytics consent
///
/// Stores user consent preferences for data collection and analytics.
/// Default is privacy-first (no tracking without explicit consent).
class UserPreferences {
  static const String _analyticsConsentKey = 'analytics_consent';
  static const String _consentTimestampKey = 'consent_timestamp';

  bool _analyticsConsent = false;
  DateTime? _consentTimestamp;

  /// Whether the user has consented to analytics tracking
  bool get analyticsConsent => _analyticsConsent;

  /// When the user last updated their consent preference
  DateTime? get consentTimestamp => _consentTimestamp;

  /// Whether the consent prompt has been shown to the user
  bool get hasSeenConsentPrompt => _consentTimestamp != null;

  /// Initialize and load preferences from storage
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _analyticsConsent = prefs.getBool(_analyticsConsentKey) ?? false;
    
    final timestampMillis = prefs.getInt(_consentTimestampKey);
    if (timestampMillis != null) {
      _consentTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    }
  }

  /// Set analytics consent preference
  ///
  /// [consent] - true to enable analytics, false to disable
  Future<void> setAnalyticsConsent(bool consent) async {
    _analyticsConsent = consent;
    _consentTimestamp = DateTime.now();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsConsentKey, consent);
    await prefs.setInt(_consentTimestampKey, _consentTimestamp!.millisecondsSinceEpoch);
  }

  /// Reset all preferences (useful for testing)
  Future<void> reset() async {
    _analyticsConsent = false;
    _consentTimestamp = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_analyticsConsentKey);
    await prefs.remove(_consentTimestampKey);
  }
}
