import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../config/auth_config.dart';

/// Authentication state provider
///
/// Manages authentication state and provides methods for
/// authentication operations throughout the app.
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  bool _isLoading = true;
  String? _error;
  String? _emailForSignIn;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;
  String? get emailForSignIn => _emailForSignIn;

  AuthProvider() {
    _init();
  }

  /// Initialize auth provider and listen to auth state changes
  void _init() {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        await _loadCurrentUser();
      } else {
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  /// Load current user from Firestore
  Future<void> _loadCurrentUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      _currentUser = await _authService.getCurrentAppUser();
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error loading current user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send sign-in email link or perform simple login
  ///
  /// [email] - User's email address
  /// [continueUrl] - URL to continue to after email verification (only used for email link auth)
  /// [name] - User's display name (optional, for registration)
  Future<bool> sendSignInLink(String email, String continueUrl, {String? name}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (AuthConfig.useEmailLinkAuth) {
        // Original email link flow
        final actionCodeSettings = _authService.getActionCodeSettings(continueUrl);

        await _authService.sendSignInLinkToEmail(
          email: email,
          actionCodeSettings: actionCodeSettings,
        );

        _emailForSignIn = email;
        
        // Save email and name to SharedPreferences for email link verification
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('emailForSignIn', email);
        if (name != null && name.isNotEmpty) {
          await prefs.setString('nameForSignIn', name);
        }
        print('DEBUG: Saved email for sign-in: $email');
        if (name != null) {
          print('DEBUG: Saved name for sign-in: $name');
        }
      } else {
        // Simple email auth flow - sign in directly
        await _authService.simpleEmailAuth(email: email);

        // Update last login
        await _authService.updateLastLogin();

        // Load the user data
        await _loadCurrentUser();
      }

      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      print('Error with sign-in: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Complete sign-in with email link
  ///
  /// [email] - User's email address
  /// [emailLink] - The sign-in link from email
  Future<bool> signInWithEmailLink(String email, String emailLink) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (!_authService.isSignInWithEmailLink(emailLink)) {
        throw Exception('Invalid sign-in link');
      }

      await _authService.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );

      // Check if user profile exists in Firestore, if not create it
      final existingUser = await _authService.getCurrentAppUser();
      
      if (existingUser == null) {
        // New user - create profile in Firestore
        print('DEBUG: New user detected, creating profile in Firestore');
        
        // Try to get saved name from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final savedName = prefs.getString('nameForSignIn');
        final userName = savedName ?? email.split('@').first;
        
        print('DEBUG: Creating user with name: $userName');
        
        final newUser = await _authService.registerUser(
          email: email,
          name: userName,
        );
        _currentUser = newUser;
        
        // Clear saved name after use
        await prefs.remove('nameForSignIn');
      } else {
        // Existing user - update last login
        await _authService.updateLastLogin();
        _currentUser = existingUser;
      }

      // Load user data to ensure we have latest
      await _loadCurrentUser();

      _emailForSignIn = null;
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      print('Error signing in with email link: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register new user
  ///
  /// [email] - User's email address
  /// [name] - User's display name
  Future<bool> registerUser(String email, String name) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (AuthConfig.useEmailLinkAuth) {
        // Original email link flow
        // Check if user already exists
        final userStatus = await _authService.checkUserStatus(email);

        if (userStatus['exists'] == true && userStatus['isDeleted'] == false) {
          throw Exception('User with this email already exists');
        }

        // If user exists but is deleted, we'll restore the account
        if (userStatus['exists'] == true && userStatus['isDeleted'] == true) {
          await _authService.restoreAccount();
          await _authService.updateUserProfile(name: name);
        } else {
          // Create new user
          await _authService.registerUser(email: email, name: name);
        }

        // Load the user data
        await _loadCurrentUser();
      } else {
        // Simple email auth flow - sign in/register directly
        await _authService.simpleEmailAuth(email: email, name: name);

        // Update last login
        await _authService.updateLastLogin();

        // Load the user data
        await _loadCurrentUser();
      }

      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      print('Error registering user: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile
  ///
  /// [name] - New display name
  Future<bool> updateProfile({required String name}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.updateUserProfile(name: name);

      // Reload user data
      await _loadCurrentUser();

      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      print('Error updating profile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Soft delete user account
  Future<bool> deleteAccount() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.softDeleteAccount();

      _currentUser = null;
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      print('Error deleting account: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();

      _currentUser = null;
      _emailForSignIn = null;
      _error = null;
    } catch (e) {
      _error = _getErrorMessage(e);
      print('Error signing out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Set email for sign-in (used when user needs to retrieve email)
  void setEmailForSignIn(String email) {
    _emailForSignIn = email;
    notifyListeners();
  }

  /// Get user-friendly error message
  String _getErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Invalid email address';
        case 'user-disabled':
          return 'This account has been disabled';
        case 'user-not-found':
          return 'No account found with this email';
        case 'invalid-action-code':
          return 'Invalid or expired sign-in link';
        case 'expired-action-code':
          return 'Sign-in link has expired. Please request a new one';
        case 'network-request-failed':
          return 'Network error. Please check your connection';
        default:
          return 'An error occurred: ${error.message}';
      }
    }
    return error.toString();
  }
}
