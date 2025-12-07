import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../models/app_user.dart';
import '../../models/budget_goal.dart';
import '../../models/user_preferences.dart';
import '../../services/user_preferences.dart';
import '../../services/export_service.dart';
import '../../services/storage_service.dart';
import '../../services/firestore_sync_service.dart';
import '../../services/file_download.dart';
import '../../services/preferences_service.dart';
import '../../services/currency_conversion_service.dart';
import '../../widgets/consent_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

/// User profile and settings screen
///
/// Allows users to:
/// - View their profile information
/// - Update their name
/// - Set financial budget goals
/// - Configure OpenAI API key
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
  final _goalController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isExporting = false;
  final UserPreferences _userPreferences = UserPreferences();
  final PreferencesService _preferencesService = PreferencesService();
  final CurrencyConversionService _currencyService =
      CurrencyConversionService();
  bool _analyticsConsent = false;
  bool _goalActive = false;
  bool _isEditingGoal = false;
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

        // Load budget goal if exists
        final goal = _userPreferences.budgetGoal;
        if (goal != null) {
          _goalController.text = goal.goalText;
          _goalActive = goal.isActive;
        }

        // Load API key if exists
        final apiKey = _userPreferences.openaiApiKey;
        if (apiKey != null) {
          _apiKeyController.text = apiKey;
        }
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
            SnackBar(
              content: Text(AppLocalizations.of(context)!.failedToLoadUserPreferences),
              backgroundColor: AppColors.destructive,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _apiKeyController.dispose();
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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profileUpdatedSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? l10n.failedToUpdateProfile),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.signOut),
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.deleteAccountWarning,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(l10n.deleteAccountDetails),
            const SizedBox(height: 8),
            Text(l10n.deleteAccountRemoveAccess),
            Text(l10n.deleteAccountKeepData),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withAlpha(127)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.recoverAccountInfo,
                      style: const TextStyle(fontSize: 12),
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
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.deleteAccount),
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? l10n.failedToDeleteAccount),
            backgroundColor: AppColors.destructive,
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.projectsExportedSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToExport}: ${e.toString()}'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _saveBudgetGoal() async {
    final goalText = _goalController.text.trim();

    if (goalText.isEmpty) {
      // Clear the goal if text is empty
      await _userPreferences.clearBudgetGoal();
      setState(() {
        _goalActive = false;
        _isEditingGoal = false;
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.budgetGoalCleared),
            backgroundColor: AppColors.success,
          ),
        );
      }
      return;
    }

    final now = DateTime.now();
    final existingGoal = _userPreferences.budgetGoal;

    final goal = BudgetGoal(
      goalText: goalText,
      isActive: _goalActive,
      createdAt: existingGoal?.createdAt ?? now,
      updatedAt: now,
    );

    await _userPreferences.setBudgetGoal(goal);

    setState(() {
      _isEditingGoal = false;
    });

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.budgetGoalSavedSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _saveApiKey() async {
    try {
      final apiKey = _apiKeyController.text.trim();

      if (apiKey.isEmpty) {
        await _userPreferences.clearOpenaiApiKey();
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.openaiApiKeyCleared),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await _userPreferences.setOpenaiApiKey(apiKey);
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.openaiApiKeySavedSuccess),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToSaveApiKey}: ${e.toString()}'),
            backgroundColor: AppColors.destructive,
          ),
        );
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
      await MyApp.of(context)?.refreshUserPreferences(user.uid);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.languageUpdatedTo} ${language.displayName}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToUpdateLanguage}: ${e.toString()}'),
            backgroundColor: AppColors.destructive,
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changeCurrency),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.changingFrom} ${_userPrefs!.currency.code} to ${currency.code} ${l10n.currencyChangeDescription}',
            ),
            const SizedBox(height: 16),
            Text(
              l10n.currencyRateInfo,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withAlpha(76)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.noteNoConvertExistingAmounts,
                      style: const TextStyle(fontSize: 12),
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
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.updateCurrency),
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${l10n.currencyUpdatedWithRate} ${currency.code} (rate: ${conversionRate.toStringAsFixed(4)})'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToUpdateCurrency}: ${e.toString()}'),
            backgroundColor: AppColors.destructive,
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileAndSettings),
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
                          backgroundColor: AppColors.primary,
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
                              decoration: InputDecoration(
                                labelText: l10n.name,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.pleaseEnterYourName;
                                }
                                if (value.trim().length < 2) {
                                  return l10n.nameMinimumLength;
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
                                    color: AppColors.textMuted,
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
                                child: Text(l10n.cancel),
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
                                    : Text(l10n.save),
                              ),
                            ],
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _isEditing = true),
                            icon: const Icon(Icons.edit),
                            label: Text(l10n.editProfile),
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
                          l10n.preferences,
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
                              l10n.language,
                              style: TextStyle(
                                color: AppColors.textMuted,
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
                              l10n.currency,
                              style: TextStyle(
                                color: AppColors.textMuted,
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
                          l10n.accountInformation,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          l10n.memberSince,
                          DateFormat('MMM d, y').format(user.createdAt),
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          l10n.lastLogin,
                          DateFormat('MMM d, y HH:mm').format(user.lastLoginAt),
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          l10n.loginCount,
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
                          l10n.privacyAndData,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.analytics),
                          subtitle: Text(
                            l10n.analyticsHelperText,
                            style: const TextStyle(fontSize: 12),
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
                                        ? l10n.analyticsEnabledThankYou
                                        : l10n.analyticsDisabled,
                                  ),
                                  backgroundColor: AppColors.success,
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
                          label: Text(
                            l10n.whatDataDoWeCollect,
                            style: const TextStyle(fontSize: 13),
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

                // Budget Goal Settings
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.budgetGoal,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (_isEditingGoal) ...[
                          TextField(
                            controller: _goalController,
                            decoration: InputDecoration(
                              labelText: l10n.financialGoal,
                              hintText: l10n.financialGoalHint,
                              border: const OutlineInputBorder(),
                              helperText: l10n.financialGoalHelper,
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.goalActive),
                            subtitle: Text(
                              l10n.goalActiveHelper,
                              style: const TextStyle(fontSize: 12),
                            ),
                            value: _goalActive,
                            onChanged: (value) {
                              setState(() {
                                _goalActive = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    // Reload from preferences
                                    final goal = _userPreferences.budgetGoal;
                                    setState(() {
                                      _goalController.text =
                                          goal?.goalText ?? '';
                                      _goalActive = goal?.isActive ?? false;
                                      _isEditingGoal = false;
                                    });
                                  },
                                  child: Text(l10n.cancel),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveBudgetGoal,
                                  child: Text(l10n.saveGoal),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          if (_goalController.text.isEmpty)
                            Text(
                              l10n.noBudgetGoalSet,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            )
                          else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _goalActive
                                    ? AppColors.success.withAlpha(25)
                                    : AppColors.textMuted.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _goalActive
                                      ? AppColors.success.withAlpha(76)
                                      : AppColors.textMuted.withAlpha(76),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _goalActive
                                            ? Icons.check_circle
                                            : Icons.pause_circle,
                                        size: 16,
                                        color: _goalActive
                                            ? AppColors.success
                                            : AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _goalActive ? l10n.active : l10n.inactive,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _goalActive
                                              ? AppColors.success
                                              : AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _goalController.text,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isEditingGoal = true;
                              });
                            },
                            icon: Icon(_goalController.text.isEmpty
                                ? Icons.add
                                : Icons.edit),
                            label: Text(_goalController.text.isEmpty
                                ? l10n.setBudgetGoal
                                : l10n.editBudgetGoal),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // OpenAI API Key Configuration
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.openaiConfiguration,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _apiKeyController,
                          decoration: InputDecoration(
                            labelText: l10n.openaiApiKey,
                            hintText: l10n.openaiApiKeyPlaceholder,
                            border: const OutlineInputBorder(),
                            helperText: l10n.openaiApiKeyHelper,
                          ),
                          obscureText: true,
                          onEditingComplete: () {
                            // Save API key when editing is complete
                            _saveApiKey();
                          },
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.primary.withAlpha(76)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.openaiApiKeySecurityInfo,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
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
                          l10n.accountActions,
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
                          label: Text(l10n.exportToCSV),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _logout,
                          icon: const Icon(Icons.logout),
                          label: Text(l10n.signOut),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _deleteAccount,
                          icon: const Icon(Icons.delete_forever),
                          label: Text(l10n.deleteAccount),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.destructive,
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
            color: AppColors.textMuted,
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
