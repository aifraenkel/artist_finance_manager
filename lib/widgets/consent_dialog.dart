import 'package:flutter/material.dart';
import '../services/user_preferences.dart';

/// Dialog to get user consent for analytics and observability
///
/// Shows on first app launch or after account creation.
/// Explains what data is collected and gives users control.
class ConsentDialog extends StatelessWidget {
  final UserPreferences userPreferences;
  final VoidCallback? onConsentChanged;

  const ConsentDialog({
    super.key,
    required this.userPreferences,
    this.onConsentChanged,
  });

  Future<void> _handleAccept(BuildContext context) async {
    await userPreferences.setAnalyticsConsent(true);
    onConsentChanged?.call();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDecline(BuildContext context) async {
    await userPreferences.setAnalyticsConsent(false);
    onConsentChanged?.call();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.privacy_tip_outlined, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Privacy & Analytics',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help us improve the app by sharing anonymous analytics data.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'What we collect:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint('Transaction events (add/delete/load)', Icons.check),
            _buildBulletPoint('Performance metrics (load times, Web Vitals)', Icons.check),
            _buildBulletPoint('Error tracking', Icons.check),
            _buildBulletPoint('Session analytics', Icons.check),
            const SizedBox(height: 16),
            const Text(
              'What we DON\'T collect:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint('Transaction amounts', Icons.close, isNegative: true),
            _buildBulletPoint('Transaction descriptions', Icons.close, isNegative: true),
            _buildBulletPoint('Personal financial data', Icons.close, isNegative: true),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You can change this preference anytime in Settings.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _handleDecline(context),
          child: const Text('Essential Only'),
        ),
        ElevatedButton(
          onPressed: () => _handleAccept(context),
          child: const Text('Accept'),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text, IconData icon, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isNegative ? Colors.red[700] : Colors.green[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Show the consent dialog
  static Future<void> show(
    BuildContext context,
    UserPreferences userPreferences, {
    VoidCallback? onConsentChanged,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConsentDialog(
        userPreferences: userPreferences,
        onConsentChanged: onConsentChanged,
      ),
    );
  }
}
