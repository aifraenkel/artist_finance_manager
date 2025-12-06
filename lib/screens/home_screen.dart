import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../services/firestore_sync_service.dart';
import '../services/observability_service.dart';
import '../services/user_preferences.dart';
import '../services/migration_service.dart';
import '../services/preferences_service.dart';
import '../widgets/summary_cards.dart';
import '../widgets/transaction_form.dart';
import '../widgets/transaction_list.dart';
import '../widgets/consent_dialog.dart';
import '../widgets/project_drawer.dart';
import '../widgets/empty_project_state.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import 'profile/profile_screen.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late StorageService _storageService;
  FirestoreSyncService? _syncService;
  final UserPreferences _userPreferences = UserPreferences();
  PreferencesService? _preferencesService;
  late ObservabilityService _observability;
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String _currencySymbol = '€'; // Default to Euro
  Map<String, double> _globalSummary = {
    'income': 0,
    'expenses': 0,
    'balance': 0,
  };
  StreamSubscription<UserPreferencesModel>? _prefsSubscription;

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    print('[HomeScreen] initState called');
    // Use post-frame callback to safely access Provider context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[HomeScreen] PostFrameCallback - calling _initializeStorage');
      _initializeStorage();
    });
  }

  Future<void> _initializeStorage() async {
    print('[HomeScreen] _initializeStorage called');
    // Initialize user preferences first
    await _userPreferences.initialize();
    print('[HomeScreen] User preferences initialized');

    // Initialize observability with user preferences
    _observability = ObservabilityService(userPreferences: _userPreferences);
    print('[HomeScreen] Observability service initialized');

    // Show consent dialog if user hasn't seen it yet
    if (!_userPreferences.hasSeenConsentPrompt && mounted) {
      // Wait a bit for the UI to settle
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await ConsentDialog.show(context, _userPreferences);
      }
    }

    if (!mounted) return;

    // Initialize project provider
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);

    // Run data migration before initializing projects
    final migrationService = MigrationService(projectProvider.projectService);
    final migrated = await migrationService.migrate();

    if (migrated && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your data has been migrated to the Default project'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.blue,
        ),
      );
    }

    await projectProvider.initialize();

    // Get current project
    final currentProject = projectProvider.currentProject;
    if (currentProject == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Create storage service with project context
    FirestoreSyncService? syncService;
    try {
      // Firestore may be unavailable in tests or offline scenarios; fall back to local-only storage.
      if (Firebase.apps.isNotEmpty) {
        syncService = FirestoreSyncService(projectId: currentProject.id);
      }
    } catch (e) {
      syncService = null;
      print('[HomeScreen] Firestore not initialized, using local storage only: $e');
    }

    _syncService = syncService;
    _storageService = StorageService(
      syncService: syncService,
      projectId: currentProject.id,
    );
    await _storageService.initialize();

    if (!mounted) return;

    // Check if user is authenticated and enable cloud sync
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      final isSyncAvailable = await _storageService.isSyncAvailable();
      if (isSyncAvailable) {
        await _storageService.setStorageMode(StorageMode.cloudSync);
      }

      // Load user currency preference
      await _loadCurrencyPreference();
      _listenToPreferenceChanges();
    }

    // Load transactions and mark initialization as complete
    if (mounted) {
      await _loadTransactions();
    }
  }

  Future<void> _loadCurrencyPreference() async {
    print('[HomeScreen] _loadCurrencyPreference called');
    if (!_isFirebaseAvailable) {
      print('[HomeScreen] Firebase not available, skipping currency preference load');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      print('[HomeScreen] No current user, skipping currency preference load');
      return;
    }

    print(
        '[HomeScreen] Loading currency preference for user: ${authProvider.currentUser!.uid}');
    try {
      // Lazy initialize PreferencesService to avoid Firebase initialization in tests
      _preferencesService ??= PreferencesService();
      print('[HomeScreen] Fetching preferences from PreferencesService...');
      final userPrefs = await _preferencesService!
          .getPreferences(authProvider.currentUser!.uid);
      print(
          '[HomeScreen] Got preferences - currency: ${userPrefs.currency.code}, symbol: ${userPrefs.currency.symbol}');
      if (mounted) {
        setState(() {
          _currencySymbol = userPrefs.currency.symbol;
        });
        print('[HomeScreen] Updated currency symbol to: $_currencySymbol');
      }
    } catch (e) {
      print('[HomeScreen] ERROR loading user preferences: $e');
      print('[HomeScreen] Stack trace: ${StackTrace.current}');
      // Keep default currency symbol
    }
  }

  void _listenToPreferenceChanges() {
    if (!_isFirebaseAvailable) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    _preferencesService ??= PreferencesService();
    _prefsSubscription?.cancel();
    _prefsSubscription = _preferencesService!
        .watchPreferences(authProvider.currentUser!.uid)
        .listen((prefs) {
      if (!mounted) return;
      if (_currencySymbol != prefs.currency.symbol) {
        setState(() {
          _currencySymbol = prefs.currency.symbol;
        });
        print('[HomeScreen] Preference stream updated currency to: $_currencySymbol');
      }
    });
  }

  Future<void> _loadTransactions() async {
    final startTime = DateTime.now();

    setState(() {
      _isLoading = true;
    });

    try {
      // calling storage
      final transactions = await _storageService.loadTransactions();
      // loaded transactions

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });

      // Track successful load with performance metric
      final loadDuration = DateTime.now().difference(startTime).inMilliseconds;
      _observability.trackMeasurement(
        'transactions_load_time_ms',
        loadDuration.toDouble(),
        attributes: {
          'transaction_count': transactions.length.toString(),
          'storage_mode': _storageService.storageMode.name,
        },
      );

      _observability.trackEvent(
        'transactions_loaded',
        attributes: {
          'count': transactions.length,
          'load_time_ms': loadDuration,
          'storage_mode': _storageService.storageMode.name,
        },
      );
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
      });

      // Track error
      _observability.trackError(
        e,
        stackTrace: stackTrace,
        context: {'operation': 'load_transactions'},
      );

      _observability.log(
        'Failed to load transactions: $e',
        level: 'error',
      );
    }
    // finished loading
  }

  // ignore: unused_element
  Future<void> _saveTransactions() async {
    await _storageService.saveTransactions(_transactions);
  }

  /// Syncs local data to the cloud.
  /// Called when user logs in to upload existing local data.
  // ignore: unused_element
  Future<void> _syncToCloud() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final success = await _storageService.forceSyncToCloud();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synced to cloud'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sync data'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  /// Refreshes data from the cloud.
  Future<void> _refreshFromCloud() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final transactions = await _storageService.forceSyncFromCloud();
      if (transactions != null && mounted) {
        setState(() {
          _transactions = transactions;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data refreshed from cloud'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync unavailable'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh data'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  /// Load global summary across all projects
  Future<void> _loadGlobalSummary() async {
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);

    try {
      final summary = await projectProvider.getGlobalSummary((projectId) async {
        // Create a temporary storage service for this project
        final tempSyncService = FirestoreSyncService(projectId: projectId);
        final tempStorage = StorageService(
          syncService: tempSyncService,
          projectId: projectId,
        );
        await tempStorage.initialize();

        // Load transactions for this project
        final transactions = await tempStorage.loadTransactions();

        // Calculate summary
        final income = transactions
            .where((t) => t.type == 'income')
            .fold(0.0, (sum, t) => sum + t.amount);
        final expenses = transactions
            .where((t) => t.type == 'expense')
            .fold(0.0, (sum, t) => sum + t.amount);

        return {
          'income': income,
          'expenses': expenses,
          'balance': income - expenses,
        };
      });

      setState(() {
        _globalSummary = summary;
      });
    } catch (e) {
      // Log error and notify user that global summary may be incomplete
      _observability.trackError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Global summary may be incomplete'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Refresh all data (called when switching projects)
  Future<void> _refreshAll() async {
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    final currentProject = projectProvider.currentProject;

    if (currentProject == null) {
      setState(() {
        _transactions = [];
        _isLoading = false;
      });
      return;
    }

    // Update storage service with new project
    _syncService?.setProjectId(currentProject.id);
    _storageService.setProjectId(currentProject.id);

    await _loadTransactions();
    await _loadGlobalSummary();
  }

  Future<void> _addTransaction(
    String description,
    double amount,
    String type,
    String category,
  ) async {
    final newTransaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch,
      description: description,
      amount: amount,
      type: type,
      category: category,
      date: DateTime.now(),
    );

    setState(() {
      _transactions.insert(0, newTransaction);
    });

    // Use optimized add method when in cloud sync mode
    await _storageService.addTransaction(newTransaction, _transactions);

    // Track transaction added event (privacy-safe: no actual amounts)
    _observability.trackEvent(
      'transaction_added',
      attributes: {
        'type': type,
        'category': category,
        'total_transactions': _transactions.length,
        'storage_mode': _storageService.storageMode.name,
      },
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transaction added: $description'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteTransaction(int id) async {
    // Find transaction index
    final index = _transactions.indexWhere((t) => t.id == id);

    if (index == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction not found'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final transaction = _transactions[index];

    setState(() {
      _transactions.removeAt(index);
    });

    // Use optimized delete method when in cloud sync mode
    await _storageService.deleteTransaction(id, _transactions);

    // Track transaction deleted event (privacy-safe: no actual amounts)
    _observability.trackEvent(
      'transaction_deleted',
      attributes: {
        'type': transaction.type,
        'category': transaction.category,
        'remaining_transactions': _transactions.length,
        'storage_mode': _storageService.storageMode.name,
      },
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction deleted'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }

  double get _totalIncome {
    return _transactions
        .where((t) => t.type == 'income')
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get _totalExpenses {
    return _transactions
        .where((t) => t.type == 'expense')
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get _balance => _totalIncome - _totalExpenses;

  void _showPrivacyPolicy(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.privacyPolicy),
        content: SingleChildScrollView(
          child: Text(l10n.privacyPolicyCallout),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ProjectProvider>(
          builder: (context, projectProvider, child) {
            final projectName =
                projectProvider.currentProject?.name ?? l10n.loading;
            return Text(projectName);
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Sync indicator and refresh button
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (!authProvider.isAuthenticated) {
                return const SizedBox.shrink();
              }

              return Row(
                children: [
                  if (_isSyncing)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.sync),
                      tooltip: 'Sync with cloud',
                      onPressed: _refreshFromCloud,
                    ),
                ],
              );
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.currentUser;
              if (user == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  tooltip: 'Profile & Settings',
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    )
                        .then((_) {
                      // Reload currency preference when returning from ProfileScreen
                      _loadCurrencyPreference();
                    });
                  },
                ),
              );
            },
          ),
        ],
      ),
      drawer: ProjectDrawer(
        globalSummary: _globalSummary,
        onRefresh: _refreshAll,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.indigo.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Consumer<ProjectProvider>(
                  builder: (context, projectProvider, child) {
                    // Show empty state if no projects exist
                    if (projectProvider.currentProject == null) {
                      return EmptyProjectState(
                        onCreateProject: () {
                          // Open drawer to show create project button
                          Scaffold.of(context).openDrawer();
                        },
                      );
                    }

                    // Show normal content when project exists
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isWideScreen = constraints.maxWidth > 800;
                        final maxWidth =
                            isWideScreen ? 1200.0 : double.infinity;

                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SummaryCards(
                                    key: const ValueKey('summary-cards'),
                                    totalIncome: _totalIncome,
                                    totalExpenses: _totalExpenses,
                                    balance: _balance,
                                    currencySymbol: _currencySymbol,
                                  ),
                                  const SizedBox(height: 24),
                                  TransactionForm(
                                    key: const ValueKey('transaction-form'),
                                    onSubmit: _addTransaction,
                                  ),
                                  const SizedBox(height: 24),
                                  TransactionList(
                                    key: const ValueKey('transaction-list'),
                                    transactions: _transactions,
                                    onDelete: _deleteTransaction,
                                    currencySymbol: _currencySymbol,
                                  ),
                                  const SizedBox(height: 32),
                                  // Footer with privacy policy link
                                  Center(
                                    child: TextButton.icon(
                                      onPressed: () {
                                        // Open privacy policy in browser or show dialog
                                        _showPrivacyPolicy(context);
                                      },
                                      icon: const Icon(
                                          Icons.privacy_tip_outlined,
                                          size: 16),
                                      label: Text(
                                        l10n.privacyPolicy,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _prefsSubscription?.cancel();
    super.dispose();
  }
}
