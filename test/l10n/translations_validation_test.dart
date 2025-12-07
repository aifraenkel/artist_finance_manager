import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:artist_finance_manager/models/user_preferences.dart';

void main() {
  group('Translation Files Validation', () {
    // Define all required translation keys
    final requiredKeys = [
      'appTitle',
      'income',
      'expenses',
      'balance',
      'projects',
      'dashboard',
      'profile',
      'settings',
      'signOut',
      'signIn',
      'email',
      'password',
      'name',
      'cancel',
      'save',
      'delete',
      'edit',
      'add',
      'loading',
      'preferences',
      'language',
      'currency',
      'updateCurrency',
      'changeCurrency',
      'budgetGoal',
      'profileAndSettings',
    ];

    // Helper function to load and parse ARB file
    Map<String, dynamic> loadArbFile(String languageCode) {
      final file = File('lib/l10n/app_$languageCode.arb');
      expect(file.existsSync(), true,
          reason: 'Translation file for $languageCode should exist');

      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return json;
    }

    // Helper function to filter out metadata keys (starting with @)
    List<String> getTranslationKeys(Map<String, dynamic> arb) {
      return arb.keys.where((key) => !key.startsWith('@')).toList();
    }

    test('All supported languages have translation files', () {
      for (final language in AppLanguage.values) {
        final file = File('lib/l10n/app_${language.code}.arb');
        expect(file.existsSync(), true,
            reason:
                'Translation file for ${language.displayName} (${language.code}) should exist at ${file.path}');
      }
    });

    test('All translation files have the correct locale metadata', () {
      for (final language in AppLanguage.values) {
        final arb = loadArbFile(language.code);
        expect(arb['@@locale'], equals(language.code),
            reason:
                'Translation file for ${language.code} should have correct @@locale metadata');
      }
    });

    test('All translation files have all required keys', () {
      for (final language in AppLanguage.values) {
        final arb = loadArbFile(language.code);
        final translationKeys = getTranslationKeys(arb);

        for (final requiredKey in requiredKeys) {
          expect(translationKeys, contains(requiredKey),
              reason:
                  'Translation file for ${language.displayName} (${language.code}) is missing key: $requiredKey');
        }
      }
    });

    test('All translation keys have non-empty values', () {
      for (final language in AppLanguage.values) {
        final arb = loadArbFile(language.code);
        final translationKeys = getTranslationKeys(arb);

        for (final key in translationKeys) {
          final value = arb[key];
          expect(value, isNotNull,
              reason:
                  'Translation key "$key" in ${language.code} should not be null');
          expect(value.toString().trim(), isNotEmpty,
              reason:
                  'Translation key "$key" in ${language.code} should not be empty');
        }
      }
    });

    test('All translation files have consistent keys', () {
      // Get keys from English (template)
      final englishArb = loadArbFile('en');
      final englishKeys = getTranslationKeys(englishArb).toSet();

      // Check that all other languages have the same keys
      for (final language in AppLanguage.values) {
        if (language.code == 'en') continue;

        final arb = loadArbFile(language.code);
        final keys = getTranslationKeys(arb).toSet();

        final missingKeys = englishKeys.difference(keys);
        final extraKeys = keys.difference(englishKeys);

        expect(missingKeys, isEmpty,
            reason:
                'Translation file for ${language.displayName} (${language.code}) is missing keys: ${missingKeys.join(", ")}');
        expect(extraKeys, isEmpty,
            reason:
                'Translation file for ${language.displayName} (${language.code}) has extra keys: ${extraKeys.join(", ")}');
      }
    });

    test('appTitle is consistent across all translations', () {
      for (final language in AppLanguage.values) {
        final arb = loadArbFile(language.code);
        expect(arb['appTitle'], equals('Art Finance Hub'),
            reason:
                'appTitle should be "Art Finance Hub" in all languages, found: ${arb['appTitle']} in ${language.code}');
      }
    });

    group('Specific language validations', () {
      test('English translations are in English', () {
        final arb = loadArbFile('en');
        expect(arb['income'], equals('Income'));
        expect(arb['expenses'], equals('Expenses'));
        expect(arb['balance'], equals('Balance'));
      });

      test('German translations are in German', () {
        final arb = loadArbFile('de');
        expect(arb['income'], equals('Einnahmen'));
        expect(arb['expenses'], equals('Ausgaben'));
        expect(arb['balance'], equals('Saldo'));
      });

      test('Spanish translations are in Spanish', () {
        final arb = loadArbFile('es');
        expect(arb['income'], equals('Ingresos'));
        expect(arb['expenses'], equals('Gastos'));
        expect(arb['balance'], equals('Saldo'));
      });
    });

    test('No orphaned translation files exist', () {
      final l10nDir = Directory('lib/l10n');
      final arbFiles = l10nDir
          .listSync()
          .where((file) => file.path.endsWith('.arb'))
          .map((file) => file.path.split('/').last)
          .toList();

      final expectedFiles =
          AppLanguage.values.map((lang) => 'app_${lang.code}.arb').toSet();

      for (final arbFile in arbFiles) {
        expect(expectedFiles, contains(arbFile),
            reason:
                'Found translation file $arbFile but no corresponding language in AppLanguage enum');
      }
    });
  });
}
