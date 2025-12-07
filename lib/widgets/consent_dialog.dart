import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.privacyAnalyticsTitle,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.privacyAnalyticsIntro,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.privacyAnalyticsCollect,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint(l10n.privacyCollectTransactions, Icons.check),
            _buildBulletPoint(l10n.privacyCollectPerformance, Icons.check),
            _buildBulletPoint(l10n.privacyCollectErrors, Icons.check),
            _buildBulletPoint(l10n.privacyCollectSessions, Icons.check),
            const SizedBox(height: 16),
            Text(
              l10n.privacyAnalyticsNoCollect,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint(l10n.privacyNoCollectAmounts, Icons.close,
                isNegative: true),
            _buildBulletPoint(l10n.privacyNoCollectDescriptions, Icons.close,
                isNegative: true),
            _buildBulletPoint(l10n.privacyNoCollectPersonal, Icons.close,
                isNegative: true),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withAlpha(51)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.privacyChangeAnytime,
                      style: const TextStyle(fontSize: 12),
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
          child: Text(l10n.essentialOnly),
        ),
        ElevatedButton(
          onPressed: () => _handleAccept(context),
          child: Text(l10n.accept),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text, IconData icon,
      {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isNegative ? AppColors.destructive : AppColors.success,
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
