import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../services/observability_service.dart';
import '../widgets/summary_cards.dart';
import '../widgets/transaction_form.dart';
import '../widgets/transaction_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  final ObservabilityService _observability = ObservabilityService();
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // init state
    _loadTransactions();
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
        attributes: {'transaction_count': transactions.length.toString()},
      );

      _observability.trackEvent(
        'transactions_loaded',
        attributes: {
          'count': transactions.length,
          'load_time_ms': loadDuration,
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

    _saveTransactions();

    // Track transaction added event (amount anonymized as range for privacy)
    _observability.trackEvent(
      'transaction_added',
      attributes: {
        'type': type,
        'category': category,
        'amount_range': _getAmountRange(amount),
        'total_transactions': _transactions.length,
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
    // Find transaction before deleting for logging
    final transaction = _transactions.firstWhere((t) => t.id == id);

    setState(() {
      _transactions.removeWhere((t) => t.id == id);
    });

    _saveTransactions();

    // Track transaction deleted event (amount anonymized as range for privacy)
    _observability.trackEvent(
      'transaction_deleted',
      attributes: {
        'type': transaction.type,
        'category': transaction.category,
        'amount_range': _getAmountRange(transaction.amount),
        'remaining_transactions': _transactions.length,
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

  /// Anonymizes amount into ranges for privacy-safe observability tracking
  String _getAmountRange(double amount) {
    final absAmount = amount.abs();
    if (absAmount < 10) return '0-10';
    if (absAmount < 50) return '10-50';
    if (absAmount < 100) return '50-100';
    if (absAmount < 500) return '100-500';
    if (absAmount < 1000) return '500-1000';
    if (absAmount < 5000) return '1000-5000';
    return '5000+';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                              const Text(
                                'Project Finance Tracker',
                                key: ValueKey('app-title'),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 24),
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
