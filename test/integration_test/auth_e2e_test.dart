import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:artist_finance_manager/main.dart' as app;

/**
 * E2E Authentication Flow Integration Test
 *
 * This test performs a REAL end-to-end test with Firebase Authentication.
 *
 * IMPORTANT: This test requires:
 * 1. Firebase to be configured and running
 * 2. Email authentication to be enabled in Firebase Console
 * 3. Manual email link clicking (or automated email checking)
 *
 * To run this test:
 * flutter test integration_test/auth_e2e_test.dart
 *
 * NOTE: Because email link authentication requires clicking a link sent via email,
 * this test includes instructions for manual testing. For fully automated testing,
 * you would need to integrate with an email testing service like Mailpit or Ethereal.
 */

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication E2E Flow', () {
    testWidgets('Complete registration and login flow (manual email verification)',
        (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 1: Verify we start at login screen (if not authenticated)
      expect(find.text('Welcome Back'), findsOneWidget);

      // Step 2: Navigate to registration
      final createAccountButton = find.text("Don't have an account? Create one");
      expect(createAccountButton, findsOneWidget);
      await tester.tap(createAccountButton);
      await tester.pumpAndSettle();

      // Verify registration screen loaded
      expect(find.text('Create Account'), findsOneWidget);

      // Step 3: Fill registration form with test data
      final testEmail = 'test+${DateTime.now().millisecondsSinceEpoch}@example.com';
      final testName = 'E2E Test User';

      await tester.enterText(find.byType(TextFormField).at(0), testName);
      await tester.enterText(find.byType(TextFormField).at(1), testEmail);
      await tester.pumpAndSettle();

      // Step 4: Submit registration
      final registerButton = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(registerButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 5: Verify email verification screen
      expect(find.text('Check Your Email'), findsOneWidget);
      expect(find.textContaining(testEmail), findsOneWidget);

      print('═════════════════════════════════════════════════════════════');
      print('MANUAL STEP REQUIRED:');
      print('1. Check Mailpit at: https://mailpit-smtp-456648586026.us-central1.run.app');
      print('2. Find the email sent to: $testEmail');
      print('3. Copy the sign-in link from the email');
      print('4. Open the link in the same browser/device running this test');
      print('5. The app should automatically complete authentication');
      print('═════════════════════════════════════════════════════════════');

      // Wait for manual email link click
      // In a real automated test, you would:
      // 1. Check Mailpit API for the email
      // 2. Parse the link from the email
      // 3. Programmatically navigate to the link
      await tester.pump(const Duration(seconds: 60)); // Wait up to 60 seconds

      // After clicking link, app should navigate to home
      // NOTE: This will fail if email link is not clicked within timeout
      // For full automation, implement email link extraction and navigation

      // Verify home screen loaded (once authenticated)
      // This assertion will pass only after manual email verification
      expect(find.text('Artist Finance Manager'), findsOneWidget);
    });

    testWidgets('Login flow for existing user',
        (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify we're on login screen
      expect(find.text('Welcome Back'), findsOneWidget);

      // Enter email for existing user
      final testEmail = 'existing-user@example.com';
      await tester.enterText(find.byType(TextFormField), testEmail);
      await tester.pumpAndSettle();

      // Send sign-in link
      final sendLinkButton = find.widgetWithText(ElevatedButton, 'Send Sign-In Link');
      await tester.tap(sendLinkButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify email verification screen
      expect(find.text('Check Your Email'), findsOneWidget);
      expect(find.textContaining(testEmail), findsOneWidget);

      print('═════════════════════════════════════════════════════════════');
      print('MANUAL STEP REQUIRED:');
      print('1. Check Mailpit at: https://mailpit-smtp-456648586026.us-central1.run.app');
      print('2. Find the email sent to: $testEmail');
      print('3. Click the sign-in link');
      print('═════════════════════════════════════════════════════════════');

      // Wait for manual email link click
      await tester.pump(const Duration(seconds: 60));

      // Verify home screen loaded after authentication
      expect(find.text('Artist Finance Manager'), findsOneWidget);
    });

    testWidgets('User profile and logout flow',
        (WidgetTester tester) async {
      // Prerequisite: User must be logged in
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify home screen is visible (user is authenticated)
      expect(find.text('Artist Finance Manager'), findsOneWidget);

      // Find and tap profile button (CircleAvatar with user initial)
      final profileButton = find.byType(CircleAvatar).first;
      expect(profileButton, findsOneWidget);
      await tester.tap(profileButton);
      await tester.pumpAndSettle();

      // Verify profile screen loaded
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Account Information'), findsOneWidget);

      // Find logout button and tap it
      final logoutButton = find.widgetWithText(ElevatedButton, 'Logout');
      expect(logoutButton, findsOneWidget);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify we're back at login screen
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to your account'), findsOneWidget);
    });
  });
}
