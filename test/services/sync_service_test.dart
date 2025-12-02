import 'package:flutter_test/flutter_test.dart';
import 'package:artist_finance_manager/services/sync_service.dart';
import 'package:artist_finance_manager/models/transaction.dart';

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

void main() {
  group('SyncService Interface Tests', () {
    late MockSyncService mockSyncService;

    setUp(() {
      mockSyncService = MockSyncService();
    });

    test('loadTransactions returns empty list initially', () async {
      final transactions = await mockSyncService.loadTransactions();
      expect(transactions, isEmpty);
    });

    test('saveTransactions stores all transactions', () async {
      final transactions = [
        Transaction(
          id: 1,
          description: 'Test expense',
          amount: 100.0,
          type: 'expense',
          category: 'Venue',
          date: DateTime.now(),
        ),
        Transaction(
          id: 2,
          description: 'Test income',
          amount: 200.0,
          type: 'income',
          category: 'Book Sales',
          date: DateTime.now(),
        ),
      ];

      await mockSyncService.saveTransactions(transactions);
      
      expect(mockSyncService.transactionCount, 2);
      
      final loaded = await mockSyncService.loadTransactions();
      expect(loaded.length, 2);
      expect(loaded.any((t) => t.id == 1), isTrue);
      expect(loaded.any((t) => t.id == 2), isTrue);
    });

    test('addTransaction adds single transaction', () async {
      final transaction = Transaction(
        id: 1,
        description: 'Test',
        amount: 50.0,
        type: 'expense',
        category: 'Materials',
        date: DateTime.now(),
      );

      await mockSyncService.addTransaction(transaction);
      
      expect(mockSyncService.transactionCount, 1);
      
      final loaded = await mockSyncService.loadTransactions();
      expect(loaded.length, 1);
      expect(loaded[0].id, 1);
    });

    test('deleteTransaction removes specific transaction', () async {
      final transactions = [
        Transaction(
          id: 1,
          description: 'Keep',
          amount: 100.0,
          type: 'expense',
          category: 'Venue',
          date: DateTime.now(),
        ),
        Transaction(
          id: 2,
          description: 'Delete',
          amount: 200.0,
          type: 'income',
          category: 'Book Sales',
          date: DateTime.now(),
        ),
      ];

      await mockSyncService.saveTransactions(transactions);
      await mockSyncService.deleteTransaction(2);
      
      final loaded = await mockSyncService.loadTransactions();
      expect(loaded.length, 1);
      expect(loaded[0].id, 1);
    });

    test('clearAll removes all transactions', () async {
      final transactions = [
        Transaction(
          id: 1,
          description: 'Test',
          amount: 100.0,
          type: 'expense',
          category: 'Venue',
          date: DateTime.now(),
        ),
      ];

      await mockSyncService.saveTransactions(transactions);
      await mockSyncService.clearAll();
      
      final loaded = await mockSyncService.loadTransactions();
      expect(loaded, isEmpty);
    });

    test('isAvailable returns configured availability', () async {
      expect(await mockSyncService.isAvailable(), isTrue);
      
      mockSyncService.setAvailable(false);
      expect(await mockSyncService.isAvailable(), isFalse);
    });

    test('getLastSyncTime returns null initially', () async {
      expect(await mockSyncService.getLastSyncTime(), isNull);
    });

    test('getLastSyncTime returns time after save', () async {
      final beforeSave = DateTime.now();
      
      await mockSyncService.saveTransactions([]);
      
      final syncTime = await mockSyncService.getLastSyncTime();
      expect(syncTime, isNotNull);
      expect(syncTime!.isAfter(beforeSave) || syncTime.isAtSameMomentAs(beforeSave), isTrue);
    });

    test('loadTransactions throws SyncException on error', () async {
      mockSyncService.setShouldThrowOnLoad(true);
      
      expect(
        () => mockSyncService.loadTransactions(),
        throwsA(isA<SyncException>()),
      );
    });

    test('saveTransactions throws SyncException on error', () async {
      mockSyncService.setShouldThrowOnSave(true);
      
      expect(
        () => mockSyncService.saveTransactions([]),
        throwsA(isA<SyncException>()),
      );
    });
  });

  group('SyncException Tests', () {
    test('SyncException has correct properties', () {
      final exception = SyncException(
        code: SyncException.networkError,
        message: 'Test message',
        cause: Exception('Original'),
      );

      expect(exception.code, SyncException.networkError);
      expect(exception.message, 'Test message');
      expect(exception.cause, isNotNull);
    });

    test('SyncException toString includes code and message', () {
      final exception = SyncException(
        code: 'test_code',
        message: 'Test message',
      );

      expect(exception.toString(), contains('test_code'));
      expect(exception.toString(), contains('Test message'));
    });

    test('SyncException error codes are defined', () {
      expect(SyncException.notAuthenticated, isNotEmpty);
      expect(SyncException.networkError, isNotEmpty);
      expect(SyncException.permissionDenied, isNotEmpty);
      expect(SyncException.notFound, isNotEmpty);
      expect(SyncException.unknown, isNotEmpty);
    });
  });
}
