import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Email verification waiting screen
///
/// Shows after user requests a sign-in link
/// Handles incoming email links and completes authentication
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String? name;
  final bool isRegistration;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.name,
    this.isRegistration = false,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkForEmailLink();
  }

  Future<void> _checkForEmailLink() async {
    // Check if current URL contains email link
    final uri = Uri.base;
    final link = uri.toString();

    if (link.contains('apiKey') && link.contains('oobCode')) {
      await _handleEmailLink(link);
    }
  }

  Future<void> _handleEmailLink(String emailLink) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Sign in with email link
    final signInSuccess = await authProvider.signInWithEmailLink(
      widget.email,
      emailLink,
    );

    if (!signInSuccess) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to sign in'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
      return;
    }

    // If this is a registration, create user profile
    if (widget.isRegistration && widget.name != null) {
      final registerSuccess = await authProvider.registerUser(
        widget.email,
        widget.name!,
      );

      if (!registerSuccess) {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Failed to create account'),
              backgroundColor: AppColors.destructive,
            ),
          );
        }
        return;
      }
    }

    setState(() => _isProcessing = false);

    // Navigation will be handled by AuthWrapper based on auth state
  }

  Future<void> _resendEmail() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final continueUrl = Uri.base.toString();

    final success =
        await authProvider.sendSignInLink(widget.email, continueUrl);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Verification email sent!'
                : authProvider.error ?? 'Failed to resend email',
          ),
          backgroundColor: success ? AppColors.success : AppColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRegistration ? 'Verify Email' : 'Sign In'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Icon(
                  _isProcessing ? Icons.hourglass_empty : Icons.mail_outline,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  _isProcessing ? 'Verifying...' : 'Check Your Email',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Instructions
                if (!_isProcessing) ...[
                  Text(
                    'We\'ve sent a ${widget.isRegistration ? 'verification' : 'sign-in'} link to:',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.email,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Instructions card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withAlpha(76)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Next Steps:',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInstructionStep(
                          '1',
                          'Open the email in your inbox',
                        ),
                        _buildInstructionStep(
                          '2',
                          'Click the "Sign In" link',
                        ),
                        _buildInstructionStep(
                          '3',
                          'You\'ll be automatically signed in',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Note about expiration
                  Text(
                    'The link will expire in 15 minutes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Resend button
                  OutlinedButton.icon(
                    onPressed: _resendEmail,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Resend Email'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Back button
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Login'),
                  ),
                ] else ...[
                  // Processing
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Please wait while we verify your email...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryDark,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
