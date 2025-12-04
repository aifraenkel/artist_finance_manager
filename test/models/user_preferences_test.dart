import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artist_finance_manager/models/user_preferences.dart';

void main() {
  group('AppLanguage', () {
    test('should have correct codes and display names', () {
      expect(AppLanguage.english.code, 'en');
      expect(AppLanguage.english.displayName, 'English');

      expect(AppLanguage.spanish.code, 'es');
      expect(AppLanguage.spanish.displayName, 'Spanish');

      expect(AppLanguage.catalan.code, 'ca');
      expect(AppLanguage.catalan.displayName, 'Catalan');
    });

    test('should parse from code correctly', () {
      expect(AppLanguage.fromCode('en'), AppLanguage.english);
      expect(AppLanguage.fromCode('es'), AppLanguage.spanish);
      expect(AppLanguage.fromCode('ca'), AppLanguage.catalan);
    });

    test('should default to English for invalid code', () {
      expect(AppLanguage.fromCode('invalid'), AppLanguage.english);
      expect(AppLanguage.fromCode(''), AppLanguage.english);
    });
  });

  group('AppCurrency', () {
    test('should have correct codes and symbols', () {
      expect(AppCurrency.eur.code, 'EUR');
      expect(AppCurrency.eur.symbol, '€');
      expect(AppCurrency.eur.displayName, 'Euro');

      expect(AppCurrency.usd.code, 'USD');
      expect(AppCurrency.usd.symbol, '\$');
      expect(AppCurrency.usd.displayName, 'US Dollar');
    });

    test('should parse from code correctly', () {
      expect(AppCurrency.fromCode('EUR'), AppCurrency.eur);
      expect(AppCurrency.fromCode('USD'), AppCurrency.usd);
    });

    test('should default to EUR for invalid code', () {
      expect(AppCurrency.fromCode('invalid'), AppCurrency.eur);
      expect(AppCurrency.fromCode(''), AppCurrency.eur);
    });
  });

  group('UserPreferencesModel', () {
    test('should create default preferences', () {
      final prefs = UserPreferencesModel.defaultPreferences('user123');

      expect(prefs.userId, 'user123');
      expect(prefs.language, AppLanguage.english);
      expect(prefs.currency, AppCurrency.eur);
      expect(prefs.conversionRate, isNull);
    });

    test('should convert to Firestore format', () {
      final now = DateTime.now();
      final prefs = UserPreferencesModel(
        userId: 'user123',
        language: AppLanguage.spanish,
        currency: AppCurrency.usd,
        updatedAt: now,
        conversionRate: 1.12,
      );

      final firestore = prefs.toFirestore();

      expect(firestore['language'], 'es');
      expect(firestore['currency'], 'USD');
      expect(firestore['updatedAt'], isA<Timestamp>());
      expect(firestore['conversionRate'], 1.12);
    });

    test('should parse from Firestore format', () {
      final now = DateTime.now();
      final data = {
        'language': 'ca',
        'currency': 'EUR',
        'updatedAt': Timestamp.fromDate(now),
        'conversionRate': 1.08,
      };

      final prefs = UserPreferencesModel.fromFirestore('user456', data);

      expect(prefs.userId, 'user456');
      expect(prefs.language, AppLanguage.catalan);
      expect(prefs.currency, AppCurrency.eur);
      expect(prefs.conversionRate, 1.08);
    });

    test('should handle missing optional fields', () {
      final now = DateTime.now();
      final data = {
        'language': 'en',
        'currency': 'USD',
        'updatedAt': Timestamp.fromDate(now),
      };

      final prefs = UserPreferencesModel.fromFirestore('user789', data);

      expect(prefs.conversionRate, isNull);
    });

    test('should use defaults for invalid data', () {
      final now = DateTime.now();
      final data = {
        'language': 'invalid',
        'currency': 'INVALID',
        'updatedAt': Timestamp.fromDate(now),
      };

      final prefs = UserPreferencesModel.fromFirestore('user999', data);

      expect(prefs.language, AppLanguage.english);
      expect(prefs.currency, AppCurrency.eur);
    });

    test('should create copy with updated fields', () {
      final original = UserPreferencesModel.defaultPreferences('user123');
      final updated = original.copyWith(
        language: AppLanguage.catalan,
        conversionRate: 1.15,
      );

      expect(updated.userId, original.userId);
      expect(updated.language, AppLanguage.catalan);
      expect(updated.currency, AppCurrency.eur);
      expect(updated.conversionRate, 1.15);
    });

    test('should have string representation', () {
      final prefs = UserPreferencesModel.defaultPreferences('user123');
      final str = prefs.toString();

      expect(str, contains('user123'));
      expect(str, contains('English'));
      expect(str, contains('EUR'));
    });
  });
}
