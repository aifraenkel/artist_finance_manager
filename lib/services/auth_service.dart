import 'package:firebase_auth/firebase_auth.dart' hide UserMetadata;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/app_user.dart';
import 'device_info_service.dart';
import 'observability_service.dart';
import 'preferences_service.dart';

/// Authentication service for managing user authentication and profile
///
/// This service handles server-side token-based email authentication:
/// - Email token (passwordless from user perspective) authentication
/// - User registration and profile creation via backend-verified tokens
/// - User profile updates
/// - Account soft deletion
/// - Session management
///
/// Note: Firebase passwords are used internally for compatibility but are
/// generated deterministically from backend-verified email tokens.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ObservabilityService _observability = ObservabilityService();
  final PreferencesService _preferencesService = PreferencesService();

  AuthService() {
    // Configure Firebase Auth persistence
    // On web: LOCAL persistence (survives browser close)
    // On mobile: persistence is always enabled by default
    _configurePersistence();
  }

  /// Configure Firebase Auth persistence for session management
  ///
  /// Ensures authentication state persists across app restarts
  /// following OWASP session management best practices.
  Future<void> _configurePersistence() async {
    try {
      // On web, explicitly set persistence to LOCAL for session persistence
      // This keeps the user logged in even after closing the browser
      await _auth.setPersistence(Persistence.LOCAL);
      print('DEBUG: Firebase Auth persistence configured to LOCAL');
    } catch (e) {
      // Mobile platforms don't support setPersistence (always enabled)
      // This is expected and not an error
      print('DEBUG: Persistence configuration not needed on this platform: $e');
    }
  }

  /// Hash email for secure logging (OWASP compliance)
  ///
  /// Creates a SHA-256 hash of the email for logging without exposing PII.
  /// The hash is deterministic so same email always produces same hash,
  /// allowing for tracking across logs while protecting user privacy.
  String _hashEmail(String email) {
    final bytes = utf8.encode(email.toLowerCase().trim());
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // First 16 chars of hash
  }

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Get current app user from Firestore
  ///
  /// Validates session and returns user data if authenticated.
  /// Handles soft-deleted users and logs session restoration events.
  Future<AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final appUser = AppUser.fromFirestore(doc);

      // Check if user is soft-deleted
      if (appUser.isDeleted) {
        print(
            'WARN: User ${_hashEmail(user.email ?? '')} is soft-deleted, signing out');
        await signOut();
        return null;
      }

      // Log session restoration for security monitoring
      _observability.log(
        'Session restored from persistent storage',
        level: 'info',
        context: {
          'userId': user.uid,
          'emailHash': _hashEmail(user.email ?? ''),
          'lastLoginAt': appUser.lastLoginAt.toIso8601String(),
          'loginCount': appUser.metadata.loginCount,
        },
      );

      print('DEBUG: Session restored for user ${_hashEmail(user.email ?? '')}');

      // Ensure user has preferences (for existing users migration)
      try {
        await _preferencesService.migrateUserPreferences(user.uid);
      } catch (e) {
        print('WARN: Failed to migrate preferences for user ${_hashEmail(user.email ?? '')}: $e');
        // Don't fail the login
      }

      return appUser;
    } catch (e) {
      print('Error getting current app user: $e');
      _observability.trackError(e, context: {
        'operation': 'getCurrentAppUser',
        'userId': user.uid,
      });
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
      print('DEBUG: Attempting to send sign-in link to ${_hashEmail(email)}');
      print(
          'DEBUG: ActionCodeSettings - URL: ${actionCodeSettings.url}, handleCodeInApp: ${actionCodeSettings.handleCodeInApp}');

      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      print('DEBUG: Sign-in link sent successfully to ${_hashEmail(email)}');
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

  /// Sign in with custom token from backend
  ///
  /// [customToken] - Custom token generated by backend via Firebase Admin SDK
  Future<UserCredential> signInWithCustomToken(String customToken) async {
    try {
      print('DEBUG: Signing in with custom token');
      final userCredential = await _auth.signInWithCustomToken(customToken);
      print('DEBUG: Custom token sign-in successful');
      return userCredential;
    } catch (e) {
      print('Error signing in with custom token: $e');
      rethrow;
    }
  }

  /// Register a new user
  ///
  /// Creates user profile in Firestore after successful authentication
  /// with device tracking for security monitoring.
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

      // Get device information for initial registration
      final deviceId = await DeviceInfoService.getDeviceId();
      final deviceName = await DeviceInfoService.getDeviceName();
      final deviceInfo = await DeviceInfoService.getDeviceInfo();

      // Create device info for first device
      final initialDevice = DeviceInfo(
        deviceId: deviceId,
        deviceName: deviceName,
        firstSeen: now,
        lastSeen: now,
      );

      final appUser = AppUser(
        uid: user.uid,
        email: email,
        name: name,
        createdAt: now,
        lastLoginAt: now,
        metadata: UserMetadata(
          loginCount: 1,
          devices: [initialDevice],
          lastLoginUserAgent: deviceInfo['userAgent'] is String
              ? deviceInfo['userAgent'] as String
              : null,
        ),
      );

      // Use server timestamp for createdAt and lastLoginAt
      final userDoc = appUser.toFirestore();
      userDoc['createdAt'] = FieldValue.serverTimestamp();
      userDoc['lastLoginAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(user.uid).set(userDoc);

      // Initialize default preferences for new user
      try {
        await _preferencesService.initializeDefaultPreferences(user.uid);
        print('INFO: Default preferences initialized for user ${_hashEmail(email)}');
      } catch (e) {
        // Log error but don't fail registration
        print('WARN: Failed to initialize preferences for user ${_hashEmail(email)}: $e');
      }

      // Log registration event
      _observability.trackEvent('user_registered', attributes: {
        'userId': user.uid,
        'emailHash': _hashEmail(email),
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': deviceInfo['platform'],
        'timestamp': now.toIso8601String(),
      });

      _observability.log(
        'New user registered successfully',
        level: 'info',
        context: {
          'userId': user.uid,
          'emailHash': _hashEmail(email),
          'deviceId': deviceId,
          'deviceName': deviceName,
        },
      );

      print(
          'INFO: New user registered: ${_hashEmail(email)} from $deviceName (device: $deviceId)');

      return appUser;
    } catch (e) {
      print('Error registering user: $e');
      _observability.trackError(e, context: {
        'operation': 'registerUser',
        'emailHash': _hashEmail(email),
      });
      rethrow;
    }
  }

  /// Update user's last login timestamp and metadata with device tracking
  ///
  /// Tracks device information and logs sign-in events for security monitoring.
  /// Implements OWASP recommendations for authentication logging.
  Future<void> updateLastLogin() async {
    final user = currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return;

      final appUser = AppUser.fromFirestore(doc);

      // Get device information
      final deviceId = await DeviceInfoService.getDeviceId();
      final deviceName = await DeviceInfoService.getDeviceName();
      final deviceInfo = await DeviceInfoService.getDeviceInfo();

      // Update or add device to the list
      final now = DateTime.now();
      final devices = List<DeviceInfo>.from(appUser.metadata.devices);
      final existingDeviceIndex =
          devices.indexWhere((d) => d.deviceId == deviceId);

      if (existingDeviceIndex >= 0) {
        // Update existing device
        devices[existingDeviceIndex] = DeviceInfo(
          deviceId: deviceId,
          deviceName: deviceName,
          firstSeen: devices[existingDeviceIndex].firstSeen,
          lastSeen: now,
        );
      } else {
        // Add new device
        devices.add(DeviceInfo(
          deviceId: deviceId,
          deviceName: deviceName,
          firstSeen: now,
          lastSeen: now,
        ));
      }

      // Update metadata with device tracking
      final updatedMetadata = appUser.metadata.copyWith(
        loginCount: appUser.metadata.loginCount + 1,
        devices: devices,
        lastLoginUserAgent: (deviceInfo['userAgent'] as String?) ?? 'Unknown',
      );

      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': Timestamp.fromDate(now),
        'metadata': updatedMetadata.toMap(),
      });

      // Log sign-in event for security monitoring
      _observability.trackEvent('user_sign_in', attributes: {
        'userId': user.uid,
        'emailHash': _hashEmail(user.email ?? ''),
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': deviceInfo['platform'],
        'loginCount': updatedMetadata.loginCount,
        'timestamp': now.toIso8601String(),
      });

      _observability.log(
        'User signed in successfully',
        level: 'info',
        context: {
          'userId': user.uid,
          'emailHash': _hashEmail(user.email ?? ''),
          'deviceId': deviceId,
          'deviceName': deviceName,
          'loginCount': updatedMetadata.loginCount,
        },
      );

      print(
          'INFO: User ${_hashEmail(user.email ?? '')} signed in from $deviceName (device: $deviceId, login #${updatedMetadata.loginCount})');

      // Ensure user has preferences (for existing users migration)
      try {
        await _preferencesService.migrateUserPreferences(user.uid);
      } catch (e) {
        print('WARN: Failed to migrate preferences for user ${_hashEmail(user.email ?? '')}: $e');
        // Don't fail the login
      }
    } catch (e) {
      print('Error updating last login: $e');
      _observability.trackError(e, context: {
        'operation': 'updateLastLogin',
        'userId': user.uid,
      });
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
  ///
  /// Logs the sign-out event for security monitoring before clearing the session.
  Future<void> signOut() async {
    final user = currentUser;

    try {
      if (user != null) {
        // Log sign-out event before clearing session
        _observability.trackEvent('user_sign_out', attributes: {
          'userId': user.uid,
          'emailHash': _hashEmail(user.email ?? ''),
          'timestamp': DateTime.now().toIso8601String(),
        });

        _observability.log(
          'User signed out',
          level: 'info',
          context: {
            'userId': user.uid,
            'emailHash': _hashEmail(user.email ?? ''),
          },
        );

        print('INFO: User ${_hashEmail(user.email ?? '')} signed out');
      }

      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      _observability.trackError(e, context: {
        'operation': 'signOut',
        'userId': user?.uid,
      });
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
}
