import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../models/app_user.dart';
import '../../models/user_preferences.dart';
import '../../services/user_preferences.dart';
import '../../services/export_service.dart';
import '../../services/storage_service.dart';
import '../../services/firestore_sync_service.dart';
import '../../services/file_download.dart';
import '../../services/preferences_service.dart';
import '../../services/currency_conversion_service.dart';
import '../../widgets/consent_dialog.dart';

/// User profile and settings screen
///
/// Allows users to:
/// - View their profile information
/// - Update their name
/// - Log out
/// - Delete their account
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isExporting = false;
  final UserPreferences _userPreferences = UserPreferences();
  final PreferencesService _preferencesService = PreferencesService();
  final CurrencyConversionService _currencyService =
      CurrencyConversionService();
  bool _analyticsConsent = false;
  UserPreferencesModel? _userPrefs;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadUserPreferences();
  }

  Future<void> _loadPreferences() async {
    await _userPreferences.initialize();
    if (mounted) {
      setState(() {
        _analyticsConsent = _userPreferences.analyticsConsent;
      });
    }
  }

  Future<void> _loadUserPreferences() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      try {
        final prefs = await _preferencesService.getPreferences(user.uid);
        if (mounted) {
          setState(() {
            _userPrefs = prefs;
          });
        }
      } catch (e) {
        print('Error loading user preferences: $e');
        // Optionally, show a snackbar to the user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load user preferences'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile(AppUser user) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to update profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete your account?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('This will:'),
            const SizedBox(height: 8),
            const Text('• Remove access to your account'),
            const Text(
                '• Keep your data for 90 days in case you change your mind'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You can recover your account within 90 days by signing in again',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.deleteAccount();

      setState(() => _isLoading = false);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to delete account'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportToCSV() async {
    setState(() => _isExporting = true);

    try {
      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);

      // Create export service with a factory function for storage services
      final exportService = ExportService(
        projectService: projectProvider.projectService,
        createStorageService: (projectId) {
          final syncService = FirestoreSyncService(projectId: projectId);
          return StorageService(
            syncService: syncService,
            projectId: projectId,
          );
        },
      );

      // Generate CSV
      final csvContent = await exportService.exportToCSV();

      // Generate filename with current date
      final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final filename = 'art_finance_hub_export_$timestamp.csv';

      // Download the file
      await downloadFile(csvContent, filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Projects exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _updateLanguage(AppLanguage language) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    try {
      await _preferencesService.updateLanguage(user.uid, language);
      await _loadUserPreferences();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language updated to ${language.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update language: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateCurrency(AppCurrency currency) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null || _userPrefs == null) return;

    // If currency is same as current, no need to update
    if (_userPrefs!.currency == currency) return;

    // Show conversion warning dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Changing from ${_userPrefs!.currency.code} to ${currency.code} will update the currency symbol displayed in the app.',
            ),
            const SizedBox(height: 16),
            const Text(
              'The conversion rate from the European Central Bank (via Frankfurter API) will be fetched and stored for your reference.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
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
                      'Note: This does not convert existing transaction amounts',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Update Currency'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      // Fetch conversion rate based on the direction of currency change
      double? conversionRate;
      if (currency == AppCurrency.usd &&
          _userPrefs!.currency == AppCurrency.eur) {
        // Converting from EUR to USD
        conversionRate = await _currencyService.getEurToUsdRate();
      } else if (currency == AppCurrency.eur &&
          _userPrefs!.currency == AppCurrency.usd) {
        // Converting from USD to EUR
        conversionRate = await _currencyService.getUsdToEurRate();
      }

      if (conversionRate == null) {
        throw Exception('Failed to fetch conversion rate');
      }

      // Update currency preference with conversion rate
      await _preferencesService.updateCurrency(
        user.uid,
        currency,
        conversionRate: conversionRate,
      );
      await _loadUserPreferences();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Currency updated to ${currency.code} (rate: ${conversionRate.toStringAsFixed(4)})'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update currency: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading || authProvider.currentUser == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authProvider.currentUser!;

          if (!_isEditing) {
            _nameController.text = user.name;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            user.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isEditing)
                          Form(
                            key: _formKey,
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                if (value.trim().length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                            ),
                          )
                        else
                          Text(
                            user.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          user.email,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 16),
                        if (_isEditing)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => setState(() => _isEditing = false),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _updateProfile(user),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Save'),
                              ),
                            ],
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _isEditing = true),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Profile'),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // User Preferences (Language & Currency)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preferences',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        // Language selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Language',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            DropdownButton<AppLanguage>(
                              value:
                                  _userPrefs?.language ?? AppLanguage.english,
                              items: AppLanguage.values.map((lang) {
                                return DropdownMenuItem(
                                  value: lang,
                                  child: Text(lang.displayName),
                                );
                              }).toList(),
                              onChanged: _isLoading
                                  ? null
                                  : (AppLanguage? newValue) {
                                      if (newValue != null) {
                                        _updateLanguage(newValue);
                                      }
                                    },
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        // Currency selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Currency',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            DropdownButton<AppCurrency>(
                              value: _userPrefs?.currency ?? AppCurrency.eur,
                              items: AppCurrency.values.map((curr) {
                                return DropdownMenuItem(
                                  value: curr,
                                  child: Text(
                                      '${curr.symbol} ${curr.displayName}'),
                                );
                              }).toList(),
                              onChanged: _isLoading
                                  ? null
                                  : (AppCurrency? newValue) {
                                      if (newValue != null) {
                                        _updateCurrency(newValue);
                                      }
                                    },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Account information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Information',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'Member since',
                          DateFormat('MMM d, y').format(user.createdAt),
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          'Last login',
                          DateFormat('MMM d, y HH:mm').format(user.lastLoginAt),
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          'Login count',
                          user.metadata.loginCount.toString(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Privacy & Data Settings
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Privacy & Data',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Analytics'),
                          subtitle: const Text(
                            'Help improve the app by sharing anonymous usage data',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _analyticsConsent,
                          onChanged: (value) async {
                            final messenger = ScaffoldMessenger.of(context);
                            await _userPreferences.setAnalyticsConsent(value);
                            setState(() {
                              _analyticsConsent = value;
                            });
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value
                                        ? 'Analytics enabled - thank you!'
                                        : 'Analytics disabled',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            // Show detailed info about what data is collected
                            ConsentDialog.show(
                              context,
                              _userPreferences,
                              onConsentChanged: () async {
                                await _loadPreferences();
                              },
                            );
                          },
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text(
                            'What data do we collect?',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: TextButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Actions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Account Actions',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: (_isLoading || _isExporting)
                              ? null
                              : _exportToCSV,
                          icon: _isExporting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download),
                          label: const Text('Export to CSV'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _logout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _deleteAccount,
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Delete Account'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
