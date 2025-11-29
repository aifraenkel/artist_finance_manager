import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home_screen.dart';

/// Authentication wrapper widget
///
/// Routes users to the appropriate screen based on authentication state
/// Also handles incoming email authentication links
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
    _checkForEmailLink();
  }

  Future<void> _checkForEmailLink() async {
    final uri = Uri.base;
    final link = uri.toString();

    // Check if URL contains email link parameters
    if (link.contains('apiKey') && link.contains('oobCode') && link.contains('mode=signIn')) {
      print('DEBUG: Email link detected in URL: $link');
      await _handleEmailLink(link);
    }
  }

  Future<void> _handleEmailLink(String emailLink) async {
    if (_isProcessingEmailLink) return;

    setState(() => _isProcessingEmailLink = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Get saved email from local storage
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('emailForSignIn');

    print('DEBUG: Retrieved saved email: $email');

    // If email not found, prompt user to enter it
    if (email == null || email.isEmpty) {
      print('DEBUG: No saved email found, prompting user');
      setState(() => _isProcessingEmailLink = false);
      
      if (mounted) {
        email = await _promptForEmail();
        if (email == null || email.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email is required to complete sign-in'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        setState(() => _isProcessingEmailLink = true);
      } else {
        return;
      }
    }

    print('DEBUG: Attempting to sign in with email link for: $email');

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
      print('DEBUG: Sign-in with email link successful!');
      // Clear the saved email
      await prefs.remove('emailForSignIn');
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
