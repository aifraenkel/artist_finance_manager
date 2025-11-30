import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home_screen.dart';

/// Authentication wrapper widget
///
/// Routes users to the appropriate screen based on authentication state
/// Also handles incoming registration/sign-in tokens and email authentication links
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isProcessingEmailLink = false;

  @override
  void initState() {
    super.initState();
    _checkForAuthenticationLinks();
  }

  Future<void> _checkForAuthenticationLinks() async {
    final uri = Uri.base;
    final link = uri.toString();

    // Check for registration token (new server-side flow)
    if (uri.queryParameters.containsKey('registrationToken')) {
      final token = uri.queryParameters['registrationToken']!;
      print('DEBUG: Registration token detected: ${token.substring(0, 10)}...');
      await _handleRegistrationToken(token);
      return;
    }

    // Check for sign-in token (new server-side flow)
    if (uri.queryParameters.containsKey('signInToken')) {
      final token = uri.queryParameters['signInToken']!;
      print('DEBUG: Sign-in token detected: ${token.substring(0, 10)}...');
      await _handleRegistrationToken(token); // Same handler works for both
      return;
    }

    // Check if URL contains old-style Firebase email link parameters (fallback)
    if (link.contains('apiKey') && link.contains('oobCode') && link.contains('mode=signIn')) {
      print('DEBUG: Firebase email link detected in URL: $link');
      await _handleFirebaseEmailLink(link);
    }
  }

  Future<void> _handleRegistrationToken(String token) async {
    if (_isProcessingEmailLink) return;

    setState(() => _isProcessingEmailLink = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    print('DEBUG: Verifying registration/sign-in token');

    // Verify token with backend - it will return email and name
    final success = await authProvider.verifyRegistrationToken(token);

    setState(() => _isProcessingEmailLink = false);

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

  Future<void> _handleFirebaseEmailLink(String emailLink) async {
    if (_isProcessingEmailLink) return;

    setState(() => _isProcessingEmailLink = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Prompt user for email (we no longer store it in localStorage)
    String? email;
    if (mounted) {
      email = await _promptForEmail();
      if (email == null || email.isEmpty) {
        setState(() => _isProcessingEmailLink = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email is required to complete sign-in'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } else {
      return;
    }

    print('DEBUG: Attempting to sign in with Firebase email link for: $email');

    // Sign in with email link
    final signInSuccess = await authProvider.signInWithEmailLink(email, emailLink);

    setState(() => _isProcessingEmailLink = false);

    if (!signInSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to sign in with email link'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      print('DEBUG: Sign-in with Firebase email link successful!');
    }
  }

  Future<String?> _promptForEmail() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter your email address to complete sign-in:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'you@example.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessingEmailLink) {
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
