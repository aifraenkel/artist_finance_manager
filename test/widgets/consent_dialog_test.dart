import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_finance_manager/services/user_preferences.dart';
import 'package:artist_finance_manager/widgets/consent_dialog.dart';
import 'package:artist_finance_manager/l10n/app_localizations.dart';

void main() {
  group('ConsentDialog Tests', () {
    late UserPreferences userPreferences;
    late AppLocalizations l10n;

    setUp(() async {
      userPreferences = UserPreferences();
      SharedPreferences.setMockInitialValues({});
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    testWidgets('Shows dialog with correct title and content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ConsentDialog.show(context, userPreferences);
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
        expect(find.text(l10n.privacyAnalyticsTitle), findsOneWidget);
        expect(find.text(l10n.privacyAnalyticsIntro), findsOneWidget);
    });

    testWidgets('Has Accept and Essential Only buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ConsentDialog.show(context, userPreferences);
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.accept), findsOneWidget);
      expect(find.text(l10n.essentialOnly), findsOneWidget);
    });

    testWidgets('Accept button sets consent to true', (
      WidgetTester tester,
    ) async {
      await userPreferences.initialize();
      expect(userPreferences.analyticsConsent, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ConsentDialog.show(context, userPreferences);
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.accept));
      await tester.pumpAndSettle();

      expect(userPreferences.analyticsConsent, isTrue);
      expect(userPreferences.hasSeenConsentPrompt, isTrue);
    });

    testWidgets('Essential Only button sets consent to false', (
      WidgetTester tester,
    ) async {
      await userPreferences.initialize();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ConsentDialog.show(context, userPreferences);
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.essentialOnly));
      await tester.pumpAndSettle();

      expect(userPreferences.analyticsConsent, isFalse);
      expect(userPreferences.hasSeenConsentPrompt, isTrue);
    });

    testWidgets('Dialog dismisses after Accept', (WidgetTester tester) async {
      await userPreferences.initialize();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ConsentDialog.show(context, userPreferences);
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text(l10n.privacyAnalyticsTitle), findsOneWidget);

      await tester.tap(find.text(l10n.accept));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text(l10n.privacyAnalyticsTitle), findsNothing);
    });
  });
}
