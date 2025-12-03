import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:artist_finance_manager/providers/auth_provider.dart';
import 'package:artist_finance_manager/models/app_user.dart';
import 'package:artist_finance_manager/widgets/auth_wrapper.dart';
import 'package:artist_finance_manager/screens/auth/login_screen.dart';
import 'package:artist_finance_manager/screens/home_screen.dart';

/**
 * Auth Wrapper Session Persistence Widget Tests
 * 
 * Tests the AuthWrapper widget's behavior when handling
 * persisted authentication sessions.
 */

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  bool _isAuthenticated = false;
  AppUser? _user;
  bool _isLoading = false;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  AppUser? get currentUser => _user;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => null;

  @override
  String? get emailForSignIn => null;

  void setAuthenticated(bool value, {AppUser? user}) {
    _isAuthenticated = value;
    _user = user;
    _isLoading = false;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void setEmailForSignIn(String email) {}

  @override
  void clearError() {}

  @override
  Future<bool> sendSignInLink(String email, String continueUrl, {String? name}) async => true;

  @override
  Future<bool> sendRegistrationLink(String email, String name, String continueUrl) async => true;

  @override
  Future<bool> verifyRegistrationToken(String token) async => true;

  @override
  Future<bool> registerUser(String email, String name) async => true;

  @override
  Future<bool> signInWithEmailLink(String email, String emailLink) async => true;

  @override
  Future<void> signOut() async {
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }

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

  Widget createTestApp() {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: mockAuthProvider,
      child: const MaterialApp(home: AuthWrapper()),
    );
  }

  group('AuthWrapper Session Persistence', () {
    testWidgets('Shows loading indicator while checking session', (WidgetTester tester) async {
      mockAuthProvider.setLoading(true);
      
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Shows LoginScreen when no persisted session', (WidgetTester tester) async {
      mockAuthProvider.setAuthenticated(false);
      
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Shows HomeScreen when session is restored', (WidgetTester tester) async {
      final testUser = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        metadata: UserMetadata(loginCount: 5),
      );
      
      mockAuthProvider.setAuthenticated(true, user: testUser);
      
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('Transitions from loading to authenticated state', (WidgetTester tester) async {
      mockAuthProvider.setLoading(true);
      
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Simulate session restoration
      final testUser = AppUser(
        uid: 'test-uid',
        email: 'restored@example.com',
        name: 'Restored User',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        metadata: UserMetadata(loginCount: 3),
      );
      
      mockAuthProvider.setAuthenticated(true, user: testUser);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Transitions from loading to unauthenticated state', (WidgetTester tester) async {
      mockAuthProvider.setLoading(true);
      
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Simulate no session found
      mockAuthProvider.setAuthenticated(false);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Handles sign out and returns to LoginScreen', (WidgetTester tester) async {
      final testUser = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        metadata: UserMetadata(loginCount: 1),
      );
      
      mockAuthProvider.setAuthenticated(true, user: testUser);
      
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      // Simulate sign out
      await mockAuthProvider.signOut();
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });
  });

  group('Session State Transitions', () {
    testWidgets('Handles rapid state changes correctly', (WidgetTester tester) async {
      mockAuthProvider.setLoading(true);
      
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      // Rapid transitions
      mockAuthProvider.setLoading(false);
      await tester.pump();
      
      mockAuthProvider.setAuthenticated(true, user: AppUser(
        uid: 'test',
        email: 'test@test.com',
        name: 'Test',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        metadata: UserMetadata(),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
