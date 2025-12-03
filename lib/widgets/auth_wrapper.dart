import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home_screen.dart';

// Web-only import for URL manipulation
// ignore: avoid_web_libraries_in_flutter
import 'auth_wrapper_stub.dart' if (dart.library.html) 'dart:html' as html;

/// Authentication wrapper widget
///
/// Routes users to the appropriate screen based on authentication state
/// Handles incoming registration/sign-in tokens from email links (server-side flow only)
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isProcessingToken = false;

  @override
  void initState() {
    super.initState();
    _checkForAuthenticationTokens();
  }

  /// Clean URL by removing query parameters after processing
  void _cleanUrl() {
    if (kIsWeb) {
      try {
        // Remove query params from URL without reloading page
        final cleanUrl = Uri.base.origin + Uri.base.path;
        html.window.history.replaceState(null, '', cleanUrl);
      } catch (e) {
        print('DEBUG: Could not clean URL: $e');
      }
    }
  }

  Future<void> _checkForAuthenticationTokens() async {
    final uri = Uri.base;

    // Check for registration token (new server-side flow)
    if (uri.queryParameters.containsKey('registrationToken')) {
      final token = uri.queryParameters['registrationToken']!;
      print('DEBUG: Registration token detected: ${token.substring(0, 10)}...');
      await _handleToken(token);
      return;
    }

    // Check for sign-in token (new server-side flow)
    if (uri.queryParameters.containsKey('signInToken')) {
      final token = uri.queryParameters['signInToken']!;
      print('DEBUG: Sign-in token detected: ${token.substring(0, 10)}...');
      await _handleToken(token);
      return;
    }

    // Old Firebase email link flow is no longer supported
    // Users must use the token-based flow via registration/sign-in emails
    final link = uri.toString();
    if (link.contains('apiKey') &&
        link.contains('oobCode') &&
        link.contains('mode=signIn')) {
      print(
          'DEBUG: Ignoring legacy Firebase email link - use token-based flow instead');
      // Clean URL and show login screen - user will need to request new sign-in link
      _cleanUrl();
    }
  }

  Future<void> _handleToken(String token) async {
    if (_isProcessingToken) return;

    setState(() => _isProcessingToken = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    print('DEBUG: Verifying registration/sign-in token');

    // Verify token with backend - it will create/get user and return sign-in link
    final success = await authProvider.verifyRegistrationToken(token);

    // Clean URL after processing (success or failure)
    _cleanUrl();

    setState(() => _isProcessingToken = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to verify registration'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      print('DEBUG: Registration/sign-in completed successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessingToken) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Completing sign-in...'),
            ],
          ),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading indicator while checking auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show home screen if authenticated, login screen otherwise
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
