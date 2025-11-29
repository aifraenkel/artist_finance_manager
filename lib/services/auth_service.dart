import 'package:firebase_auth/firebase_auth.dart' hide UserMetadata;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../config/auth_config.dart';

/// Authentication service for managing user authentication and profile
///
/// This service handles:
/// - Email link (passwordless) authentication
/// - Simple email-only authentication (for development/testing)
/// - User registration and profile creation
/// - User profile updates
/// - Account soft deletion
/// - Session management
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Get current app user from Firestore
  Future<AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final appUser = AppUser.fromFirestore(doc);

      // Check if user is soft-deleted
      if (appUser.isDeleted) {
        await signOut();
        return null;
      }

      return appUser;
    } catch (e) {
      print('Error getting current app user: $e');
      return null;
    }
  }

  /// Send sign-in email link to user's email
  ///
  /// [email] - User's email address
  /// [actionCodeSettings] - Settings for the email link
  Future<void> sendSignInLinkToEmail({
    required String email,
    required ActionCodeSettings actionCodeSettings,
  }) async {
    try {
      print('DEBUG: Attempting to send sign-in link to $email');
      print('DEBUG: ActionCodeSettings - URL: ${actionCodeSettings.url}, handleCodeInApp: ${actionCodeSettings.handleCodeInApp}');
      
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
      
      print('DEBUG: Sign-in link sent successfully to $email');
      print('DEBUG: Check your email inbox and spam folder');
    } catch (e) {
      print('ERROR: Failed to send sign-in link: $e');
      if (e is FirebaseAuthException) {
        print('ERROR: Firebase Auth Error Code: ${e.code}');
        print('ERROR: Firebase Auth Error Message: ${e.message}');
      }
      rethrow;
    }
  }

  /// Verify if the link is a sign-in email link
  bool isSignInWithEmailLink(String emailLink) {
    return _auth.isSignInWithEmailLink(emailLink);
  }

  /// Sign in user with email link
  ///
  /// [email] - User's email address
  /// [emailLink] - The sign-in link from email
  Future<UserCredential> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );

      return userCredential;
    } catch (e) {
      print('Error signing in with email link: $e');
      rethrow;
    }
  }

  /// Register a new user
  ///
  /// Creates user profile in Firestore after successful authentication
  ///
  /// [email] - User's email address
  /// [name] - User's display name
  Future<AppUser> registerUser({
    required String email,
    required String name,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    try {
      final now = DateTime.now();
      final appUser = AppUser(
        uid: user.uid,
        email: email,
        name: name,
        createdAt: now,
        lastLoginAt: now,
        metadata: UserMetadata(loginCount: 1),
      );

      // Use server timestamp for createdAt and lastLoginAt
      final userDoc = appUser.toFirestore();
      userDoc['createdAt'] = FieldValue.serverTimestamp();
      userDoc['lastLoginAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userDoc);

      return appUser;
    } catch (e) {
      print('Error registering user: $e');
      rethrow;
    }
  }

  /// Update user's last login timestamp and metadata
  Future<void> updateLastLogin() async {
    final user = currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return;

      final appUser = AppUser.fromFirestore(doc);
      final updatedMetadata = appUser.metadata.copyWith(
        loginCount: appUser.metadata.loginCount + 1,
      );

      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
        'metadata': updatedMetadata.toMap(),
      });
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  /// Update user profile
  ///
  /// [name] - New display name (optional)
  Future<void> updateUserProfile({String? name}) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updates);
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Soft delete user account
  ///
  /// Sets deletedAt timestamp instead of permanently deleting the account.
  /// User data will be retained for 90 days for potential recovery.
  Future<void> softDeleteAccount() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'deletedAt': Timestamp.fromDate(DateTime.now()),
      });

      await signOut();
    } catch (e) {
      print('Error soft deleting account: $e');
      rethrow;
    }
  }

  /// Restore a soft-deleted account
  ///
  /// This can only be called within the retention period (90 days)
  Future<void> restoreAccount() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'deletedAt': null,
      });
    } catch (e) {
      print('Error restoring account: $e');
      rethrow;
    }
  }

  /// Check if a user exists and if their account is deleted
  Future<Map<String, dynamic>> checkUserStatus(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {'exists': false, 'isDeleted': false};
      }

      final userData = querySnapshot.docs.first.data();
      final deletedAt = userData['deletedAt'];

      return {
        'exists': true,
        'isDeleted': deletedAt != null,
        'userId': querySnapshot.docs.first.id,
      };
    } catch (e) {
      print('Error checking user status: $e');
      return {'exists': false, 'isDeleted': false};
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  /// Delete user account permanently
  ///
  /// This is used by the automated cleanup job after retention period
  Future<void> permanentlyDeleteAccount(String userId) async {
    try {
      // Delete user document from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Note: Firebase Auth user deletion requires admin SDK
      // This should be done via Cloud Function
    } catch (e) {
      print('Error permanently deleting account: $e');
      rethrow;
    }
  }

  /// Get action code settings for email link authentication
  ActionCodeSettings getActionCodeSettings(String continueUrl) {
    return ActionCodeSettings(
      url: continueUrl,
      handleCodeInApp: true,
      androidPackageName: 'com.artist.financemanager',
      androidInstallApp: true,
      androidMinimumVersion: '21',
      iOSBundleId: 'com.artist.financemanager',
    );
  }

  /// Simple email authentication (for development/testing)
  ///
  /// Creates or signs in a user with just their email, bypassing email verification.
  /// Only enabled when AuthConfig.useEmailLinkAuth is false.
  ///
  /// [email] - User's email address
  /// [name] - User's display name (for new users)
  Future<UserCredential> simpleEmailAuth({
    required String email,
    String? name,
  }) async {
    if (AuthConfig.useEmailLinkAuth) {
      throw Exception('Simple email auth is disabled. Use email link authentication instead.');
    }

    // Validate email domain if whitelist is configured
    if (AuthConfig.allowedEmailDomains.isNotEmpty) {
      final domain = email.split('@').last;
      if (!AuthConfig.allowedEmailDomains.contains(domain)) {
        throw Exception('Email domain not allowed. Allowed domains: ${AuthConfig.allowedEmailDomains.join(", ")}');
      }
    }

    try {
      // Use a deterministic password based on email for simple auth
      // This is insecure but acceptable for development/testing
      final password = _generateDevPassword(email);

      UserCredential? userCredential;

      try {
        // Try to sign in first
        print('DEBUG: Attempting sign in for $email with generated password');
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('DEBUG: Sign in successful');
      } on FirebaseAuthException catch (e) {
        print('FirebaseAuthException during sign in: code=${e.code}, message=${e.message}');
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          // User doesn't exist, create new account
          print('DEBUG: User not found, creating new account for $email');
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          print('DEBUG: Account created successfully');

          // Create user profile in Firestore
          if (name != null) {
            final now = DateTime.now();
            final appUser = AppUser(
              uid: userCredential.user!.uid,
              email: email,
              name: name,
              createdAt: now,
              lastLoginAt: now,
              metadata: UserMetadata(loginCount: 1),
            );

            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .set(appUser.toFirestore());
          }
        } else {
          rethrow;
        }
      }

      return userCredential;
    } catch (e) {
      print('Error with simple email auth: $e');
      rethrow;
    }
  }

  /// Generate a deterministic password for development
  /// WARNING: This is NOT secure and should only be used for development/testing
  String _generateDevPassword(String email) {
    return 'dev_${email.hashCode}_password';
  }
}
