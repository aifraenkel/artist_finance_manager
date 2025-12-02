import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../services/firestore_sync_service.dart';
import '../services/observability_service.dart';
import '../widgets/summary_cards.dart';
import '../widgets/transaction_form.dart';
import '../widgets/transaction_list.dart';
import '../providers/auth_provider.dart';
import 'profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late StorageService _storageService;
  final ObservabilityService _observability = ObservabilityService();
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    // Create storage service with optional sync service
    final syncService = FirestoreSyncService();
    _storageService = StorageService(syncService: syncService);
    await _storageService.initialize();

    // Check if user is authenticated and enable cloud sync
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      final isSyncAvailable = await _storageService.isSyncAvailable();
      if (isSyncAvailable) {
        await _storageService.setStorageMode(StorageMode.cloudSync);
      }
    }

    await _loadTransactions();
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

  Future<void> _saveTransactions() async {
    await _storageService.saveTransactions(_transactions);
  }

  /// Syncs local data to the cloud.
  /// Called when user logs in to upload existing local data.
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

  void _addTransaction(
    String description,
    double amount,
    String type,
    String category,
  ) {
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
    _storageService.addTransaction(newTransaction, _transactions);

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transaction added: $description'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteTransaction(int id) {
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
    _storageService.deleteTransaction(id, _transactions);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Finance Tracker'),
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
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
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideScreen = constraints.maxWidth > 800;
                    final maxWidth = isWideScreen ? 1200.0 : double.infinity;

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
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
