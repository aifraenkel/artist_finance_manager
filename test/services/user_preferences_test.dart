import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_finance_manager/services/user_preferences.dart';

void main() {
  group('UserPreferences Tests', () {
    late UserPreferences userPreferences;

    setUp(() {
      userPreferences = UserPreferences();
      SharedPreferences.setMockInitialValues({});
    });

    test('Default analytics consent is false (privacy-first)', () async {
      await userPreferences.initialize();
      expect(userPreferences.analyticsConsent, isFalse);
    });

    test('hasSeenConsentPrompt is false initially', () async {
      await userPreferences.initialize();
      expect(userPreferences.hasSeenConsentPrompt, isFalse);
    });

    test('consentTimestamp is null initially', () async {
      await userPreferences.initialize();
      expect(userPreferences.consentTimestamp, isNull);
    });

    test('Setting analytics consent to true updates preference', () async {
      await userPreferences.initialize();
      await userPreferences.setAnalyticsConsent(true);

      expect(userPreferences.analyticsConsent, isTrue);
      expect(userPreferences.consentTimestamp, isNotNull);
      expect(userPreferences.hasSeenConsentPrompt, isTrue);
    });

    test('Setting analytics consent to false updates preference', () async {
      await userPreferences.initialize();
      await userPreferences.setAnalyticsConsent(false);

      expect(userPreferences.analyticsConsent, isFalse);
      expect(userPreferences.consentTimestamp, isNotNull);
      expect(userPreferences.hasSeenConsentPrompt, isTrue);
    });

    test('Consent preference persists across initialize calls', () async {
      await userPreferences.initialize();
      await userPreferences.setAnalyticsConsent(true);

      // Create new instance and initialize
      final newPreferences = UserPreferences();
      await newPreferences.initialize();

      expect(newPreferences.analyticsConsent, isTrue);
      expect(newPreferences.hasSeenConsentPrompt, isTrue);
      expect(newPreferences.consentTimestamp, isNotNull);
    });

    test('Changing consent updates timestamp', () async {
      await userPreferences.initialize();
      await userPreferences.setAnalyticsConsent(true);
      final firstTimestamp = userPreferences.consentTimestamp;

      // Wait a bit to ensure timestamp is different
      await Future.delayed(const Duration(milliseconds: 10));

      await userPreferences.setAnalyticsConsent(false);
      final secondTimestamp = userPreferences.consentTimestamp;

      expect(secondTimestamp, isNotNull);
      expect(secondTimestamp!.isAfter(firstTimestamp!), isTrue);
    });

    test('Reset clears all preferences', () async {
      await userPreferences.initialize();
      await userPreferences.setAnalyticsConsent(true);

      await userPreferences.reset();

      expect(userPreferences.analyticsConsent, isFalse);
      expect(userPreferences.consentTimestamp, isNull);
      expect(userPreferences.hasSeenConsentPrompt, isFalse);
    });

    test('Reset persists across initialize calls', () async {
      await userPreferences.initialize();
      await userPreferences.setAnalyticsConsent(true);
      await userPreferences.reset();

      // Create new instance and initialize
      final newPreferences = UserPreferences();
      await newPreferences.initialize();

      expect(newPreferences.analyticsConsent, isFalse);
      expect(newPreferences.consentTimestamp, isNull);
      expect(newPreferences.hasSeenConsentPrompt, isFalse);
    });

    test('Timestamp is stored and loaded correctly', () async {
      await userPreferences.initialize();
      final beforeTime = DateTime.now();
      await userPreferences.setAnalyticsConsent(true);
      final afterTime = DateTime.now();

      final timestamp = userPreferences.consentTimestamp!;
      expect(timestamp.isAfter(beforeTime.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(timestamp.isBefore(afterTime.add(const Duration(seconds: 1))),
          isTrue);

      // Verify it persists
      final newPreferences = UserPreferences();
      await newPreferences.initialize();

      expect(newPreferences.consentTimestamp, isNotNull);
      expect(newPreferences.consentTimestamp!.millisecondsSinceEpoch,
          equals(timestamp.millisecondsSinceEpoch));
    });

    test('Can toggle consent multiple times', () async {
      await userPreferences.initialize();

      await userPreferences.setAnalyticsConsent(true);
      expect(userPreferences.analyticsConsent, isTrue);

      await userPreferences.setAnalyticsConsent(false);
      expect(userPreferences.analyticsConsent, isFalse);

      await userPreferences.setAnalyticsConsent(true);
      expect(userPreferences.analyticsConsent, isTrue);

      // Verify final state persists
      final newPreferences = UserPreferences();
      await newPreferences.initialize();
      expect(newPreferences.analyticsConsent, isTrue);
    });
  });
}
