import 'package:artist_finance_manager/models/transaction.dart';
import 'package:artist_finance_manager/services/sync_service.dart';

/// Mock implementation of SyncService for testing.
///
/// This mock allows testing StorageService with cloud sync
/// without requiring actual Firebase infrastructure.
class MockSyncService implements SyncService {
  final Map<int, Transaction> _transactions = {};
  DateTime? _lastSyncTime;
  bool _isAvailable = true;
  bool _shouldThrowOnLoad = false;
  bool _shouldThrowOnSave = false;

  /// Sets whether the sync service is available.
  void setAvailable(bool available) {
    _isAvailable = available;
  }

  /// Configures the mock to throw on load operations.
  void setShouldThrowOnLoad(bool shouldThrow) {
    _shouldThrowOnLoad = shouldThrow;
  }

  /// Configures the mock to throw on save operations.
  void setShouldThrowOnSave(bool shouldThrow) {
    _shouldThrowOnSave = shouldThrow;
  }

  /// Clears all stored transactions in the mock.
  void clearMockData() {
    _transactions.clear();
    _lastSyncTime = null;
  }

  /// Gets the number of stored transactions.
  int get transactionCount => _transactions.length;

  @override
  Future<List<Transaction>> loadTransactions() async {
    if (_shouldThrowOnLoad) {
      throw SyncException(
        code: SyncException.networkError,
        message: 'Mock network error',
      );
    }
    return _transactions.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> saveTransactions(List<Transaction> transactions) async {
    if (_shouldThrowOnSave) {
      throw SyncException(
        code: SyncException.networkError,
        message: 'Mock network error',
      );
    }
    _transactions.clear();
    for (final t in transactions) {
      _transactions[t.id] = t;
    }
    _lastSyncTime = DateTime.now();
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    if (_shouldThrowOnSave) {
      throw SyncException(
        code: SyncException.networkError,
        message: 'Mock network error',
      );
    }
    _transactions[transaction.id] = transaction;
    _lastSyncTime = DateTime.now();
  }

  @override
  Future<void> deleteTransaction(int transactionId) async {
    if (_shouldThrowOnSave) {
      throw SyncException(
        code: SyncException.networkError,
        message: 'Mock network error',
      );
    }
    _transactions.remove(transactionId);
    _lastSyncTime = DateTime.now();
  }

  @override
  Future<void> clearAll() async {
    if (_shouldThrowOnSave) {
      throw SyncException(
        code: SyncException.networkError,
        message: 'Mock network error',
      );
    }
    _transactions.clear();
    _lastSyncTime = DateTime.now();
  }

  @override
  Future<bool> isAvailable() async {
    return _isAvailable;
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    return _lastSyncTime;
  }
}
