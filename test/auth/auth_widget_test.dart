import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:artist_finance_manager/providers/auth_provider.dart';
import 'package:artist_finance_manager/screens/auth/login_screen.dart';
import 'package:artist_finance_manager/screens/auth/registration_screen.dart';
import 'package:artist_finance_manager/models/app_user.dart';

/// Authentication Widget Tests
/// Tests the authentication UI and validation without Firebase dependencies

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  bool _isAuthenticated = false;
  AppUser? _user;
  String? _error;
  final bool _isLoading = false;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  AppUser? get currentUser => _user;

  @override
  String? get error => _error;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get emailForSignIn => null;

  @override
  void setEmailForSignIn(String email) {}

  @override
  void clearError() => _error = null;

  @override
  Future<bool> sendSignInLink(String email, String continueUrl,
      {String? name}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return true;
  }

  @override
  Future<bool> sendRegistrationLink(
      String email, String name, String continueUrl) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return true;
  }

  @override
  Future<bool> verifyRegistrationToken(String token) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return true;
  }

  @override
  Future<bool> registerUser(String email, String name) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _user = AppUser(
      uid: 'test-uid',
      email: email,
      name: name,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      metadata: UserMetadata(),
    );
    notifyListeners();
    return true;
  }

  @override
  Future<bool> signInWithEmailLink(String email, String emailLink) async =>
      true;

  @override
  Future<void> signOut() async => _isAuthenticated = false;

  @override
  Future<bool> deleteAccount() async => true;

  @override
  Future<bool> updateProfile({required String name}) async => true;
}

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
  });

  Widget createTestApp(Widget home) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: mockAuthProvider,
      child: MaterialApp(home: home),
    );
  }

  group('Authentication Widget Tests', () {
    testWidgets('Login screen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Art Finance Hub'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Send Sign-In Link'),
          findsOneWidget);
    });

    testWidgets('Registration form validates required fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const RegistrationScreen()));
      await tester.pumpAndSettle();

      final registerButton =
          find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('Registration form validates email format',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const RegistrationScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), 'invalid-email');
      await tester.pumpAndSettle();

      final registerButton =
          find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('Login form validates email', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'not-an-email');
      await tester.pumpAndSettle();

      final button = find.widgetWithText(ElevatedButton, 'Send Sign-In Link');
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('Complete registration with valid data',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const RegistrationScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');
      await tester.enterText(
          find.byType(TextFormField).at(1), 'john@example.com');
      await tester.pumpAndSettle();

      final registerButton =
          find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Email link flow: should navigate to EmailVerificationScreen
      expect(find.text('Check Your Email'), findsOneWidget);
      expect(find.textContaining('john@example.com'), findsOneWidget);
    });

    testWidgets('Login shows success snackbar on email sent', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.pumpAndSettle();

      final button = find.widgetWithText(ElevatedButton, 'Send Sign-In Link');
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Should show success snackbar
      expect(find.text('Sign-in email sent! Please check your inbox.'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      // Verify snackbar has green background
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.green);
    });

    testWidgets('Registration shows success snackbar on email sent', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const RegistrationScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.pumpAndSettle();

      final button = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Should show success snackbar
      expect(find.text('Verification email sent! Please check your inbox.'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      // Verify snackbar has green background
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.green);
    });
  });
}
