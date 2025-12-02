import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_finance_manager/models/transaction.dart';
import 'package:artist_finance_manager/services/storage_service.dart';
import 'package:artist_finance_manager/services/sync_service.dart';

/// Mock implementation of SyncService for testing.
class MockSyncService implements SyncService {
  final Map<int, Transaction> _transactions = {};
  DateTime? _lastSyncTime;
  bool _isAvailable = true;
  bool _shouldThrowOnLoad = false;
  bool _shouldThrowOnSave = false;

  void setAvailable(bool available) => _isAvailable = available;
  void setShouldThrowOnLoad(bool shouldThrow) => _shouldThrowOnLoad = shouldThrow;
  void setShouldThrowOnSave(bool shouldThrow) => _shouldThrowOnSave = shouldThrow;
  void clearMockData() {
    _transactions.clear();
    _lastSyncTime = null;
  }
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
  Future<bool> isAvailable() async => _isAvailable;

  @override
  Future<DateTime?> getLastSyncTime() async => _lastSyncTime;
}

void main() {
  group('StorageService Tests', () {
    late StorageService storageService;

    setUp(() {
      storageService = StorageService();
      SharedPreferences.setMockInitialValues({});
    });

    test('Load transactions returns empty list initially', () async {
      final transactions = await storageService.loadTransactions();
      expect(transactions, isEmpty);
    });

    test('Save and load transactions', () async {
      final transactions = [
        Transaction(
          id: 1,
          description: 'Test 1',
          amount: 100.0,
          type: 'expense',
          category: 'Venue',
          date: DateTime.now(),
        ),
        Transaction(
          id: 2,
          description: 'Test 2',
          amount: 200.0,
          type: 'income',
          category: 'Book Sales',
          date: DateTime.now(),
        ),
      ];

      await storageService.saveTransactions(transactions);
      final loaded = await storageService.loadTransactions();

      expect(loaded.length, 2);
      expect(loaded[0].description, 'Test 1');
      expect(loaded[1].description, 'Test 2');
      expect(loaded[0].amount, 100.0);
      expect(loaded[1].amount, 200.0);
    });

    test('Clear all data', () async {
      final transactions = [
        Transaction(
          id: 1,
          description: 'Test',
          amount: 50.0,
          type: 'expense',
          category: 'Other',
          date: DateTime.now(),
        ),
      ];

      await storageService.saveTransactions(transactions);
      await storageService.clearAll();

      final loaded = await storageService.loadTransactions();
      expect(loaded, isEmpty);
    });

    test('Load handles invalid JSON gracefully', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('project-finances', 'invalid json');

      final transactions = await storageService.loadTransactions();
      expect(transactions, isEmpty);
    });

    test('Save empty list', () async {
      await storageService.saveTransactions([]);
      final loaded = await storageService.loadTransactions();
      expect(loaded, isEmpty);
    });

    test('Save large number of transactions', () async {
      final transactions = List.generate(
        100,
        (index) => Transaction(
          id: index,
          description: 'Transaction $index',
          amount: index * 10.0,
          type: index % 2 == 0 ? 'expense' : 'income',
          category: 'Test',
          date: DateTime.now(),
        ),
      );

      await storageService.saveTransactions(transactions);
      final loaded = await storageService.loadTransactions();

      expect(loaded.length, 100);
      expect(loaded[50].description, 'Transaction 50');
      expect(loaded[99].amount, 990.0);
    });
  });

  group('StorageService Storage Mode Tests', () {
    late StorageService storageService;

    setUp(() {
      storageService = StorageService();
      SharedPreferences.setMockInitialValues({});
    });

    test('Default storage mode is localOnly', () {
      expect(storageService.storageMode, StorageMode.localOnly);
    });

    test('Storage mode can be changed to cloudSync', () async {
      await storageService.setStorageMode(StorageMode.cloudSync);
      expect(storageService.storageMode, StorageMode.cloudSync);
    });

    test('Storage mode persists across initialize calls', () async {
      await storageService.setStorageMode(StorageMode.cloudSync);

      // Create new instance and initialize
      final newStorageService = StorageService();
      await newStorageService.initialize();

      expect(newStorageService.storageMode, StorageMode.cloudSync);
    });

    test('isSyncAvailable returns false without syncService', () async {
      expect(await storageService.isSyncAvailable(), isFalse);
    });
  });

  group('StorageService Cloud Sync Tests', () {
    late StorageService storageService;
    late MockSyncService mockSyncService;

    setUp(() {
      mockSyncService = MockSyncService();
      storageService = StorageService(syncService: mockSyncService);
      SharedPreferences.setMockInitialValues({});
    });

    test('isSyncAvailable returns true when syncService is available', () async {
      mockSyncService.setAvailable(true);
      expect(await storageService.isSyncAvailable(), isTrue);
    });

    test('isSyncAvailable returns false when syncService is unavailable', () async {
      mockSyncService.setAvailable(false);
      expect(await storageService.isSyncAvailable(), isFalse);
    });

    test('In cloudSync mode, loads from cloud and updates local cache', () async {
      // Setup cloud data
      await mockSyncService.saveTransactions([
        Transaction(
          id: 1,
          description: 'Cloud transaction',
          amount: 100.0,
          type: 'expense',
          category: 'Venue',
          date: DateTime.now(),
        ),
      ]);

      // Enable cloud sync
      await storageService.setStorageMode(StorageMode.cloudSync);

      // Load transactions
      final transactions = await storageService.loadTransactions();

      expect(transactions.length, 1);
      expect(transactions[0].description, 'Cloud transaction');

      // Verify local cache was updated
      await storageService.setStorageMode(StorageMode.localOnly);
      final localTransactions = await storageService.loadTransactions();
      expect(localTransactions.length, 1);
    });

    test('In cloudSync mode, saves to both local and cloud', () async {
      await storageService.setStorageMode(StorageMode.cloudSync);

      final transactions = [
        Transaction(
          id: 1,
          description: 'Test',
          amount: 50.0,
          type: 'expense',
          category: 'Materials',
          date: DateTime.now(),
        ),
      ];

      await storageService.saveTransactions(transactions);

      // Verify saved to cloud
      expect(mockSyncService.transactionCount, 1);

      // Verify saved to local
      await storageService.setStorageMode(StorageMode.localOnly);
      final localTransactions = await storageService.loadTransactions();
      expect(localTransactions.length, 1);
    });

    test('In cloudSync mode, falls back to local on cloud error', () async {
      // Setup local data first
      await storageService.saveTransactions([
        Transaction(
          id: 1,
          description: 'Local transaction',
          amount: 100.0,
          type: 'expense',
          category: 'Venue',
          date: DateTime.now(),
        ),
      ]);

      // Enable cloud sync and configure to fail
      await storageService.setStorageMode(StorageMode.cloudSync);
      mockSyncService.setShouldThrowOnLoad(true);

      // Load should fall back to local
      final transactions = await storageService.loadTransactions();

      expect(transactions.length, 1);
      expect(transactions[0].description, 'Local transaction');
    });

    test('Cloud sync failure does not prevent local save', () async {
      await storageService.setStorageMode(StorageMode.cloudSync);
      mockSyncService.setShouldThrowOnSave(true);

      final transactions = [
        Transaction(
          id: 1,
          description: 'Test',
          amount: 50.0,
          type: 'expense',
          category: 'Materials',
          date: DateTime.now(),
        ),
      ];

      // Save should succeed locally even if cloud fails
      await storageService.saveTransactions(transactions);

      // Verify saved to local
      await storageService.setStorageMode(StorageMode.localOnly);
      final localTransactions = await storageService.loadTransactions();
      expect(localTransactions.length, 1);
    });

    test('forceSyncToCloud uploads local data to cloud', () async {
      // Add local data
      await storageService.saveTransactions([
        Transaction(
          id: 1,
          description: 'Local only',
          amount: 100.0,
          type: 'expense',
          category: 'Venue',
          date: DateTime.now(),
        ),
      ]);

      // Force sync to cloud
      final result = await storageService.forceSyncToCloud();

      expect(result, isTrue);
      expect(mockSyncService.transactionCount, 1);
    });

    test('forceSyncFromCloud downloads cloud data to local', () async {
      // Add cloud data
      await mockSyncService.saveTransactions([
        Transaction(
          id: 1,
          description: 'Cloud only',
          amount: 200.0,
          type: 'income',
          category: 'Book Sales',
          date: DateTime.now(),
        ),
      ]);

      // Force sync from cloud
      final transactions = await storageService.forceSyncFromCloud();

      expect(transactions, isNotNull);
      expect(transactions!.length, 1);

      // Verify local storage updated
      final localTransactions = await storageService.loadTransactions();
      expect(localTransactions.length, 1);
      expect(localTransactions[0].description, 'Cloud only');
    });

    test('forceSyncToCloud returns false when sync unavailable', () async {
      mockSyncService.setAvailable(false);
      final result = await storageService.forceSyncToCloud();
      expect(result, isFalse);
    });

    test('forceSyncFromCloud returns null when sync unavailable', () async {
      mockSyncService.setAvailable(false);
      final result = await storageService.forceSyncFromCloud();
      expect(result, isNull);
    });

    test('getLastSyncTime returns time from sync service', () async {
      // Initially null
      expect(await storageService.getLastSyncTime(), isNull);

      // After save
      await mockSyncService.saveTransactions([]);
      final syncTime = await storageService.getLastSyncTime();
      expect(syncTime, isNotNull);
    });

    test('clearAll clears both local and cloud in cloudSync mode', () async {
      // Setup data
      await storageService.setStorageMode(StorageMode.cloudSync);
      await storageService.saveTransactions([
        Transaction(
          id: 1,
          description: 'Test',
          amount: 50.0,
          type: 'expense',
          category: 'Materials',
          date: DateTime.now(),
        ),
      ]);

      // Clear all
      await storageService.clearAll();

      // Verify both cleared
      expect(mockSyncService.transactionCount, 0);
      final localTransactions = await storageService.loadTransactions();
      expect(localTransactions, isEmpty);
    });
  });

  group('StorageService addTransaction and deleteTransaction Tests', () {
    late StorageService storageService;
    late MockSyncService mockSyncService;

    setUp(() {
      mockSyncService = MockSyncService();
      storageService = StorageService(syncService: mockSyncService);
      SharedPreferences.setMockInitialValues({});
    });

    test('addTransaction saves locally and syncs to cloud', () async {
      await storageService.setStorageMode(StorageMode.cloudSync);

      final transaction = Transaction(
        id: 1,
        description: 'New transaction',
        amount: 100.0,
        type: 'expense',
        category: 'Venue',
        date: DateTime.now(),
      );

      await storageService.addTransaction(transaction, [transaction]);

      // Verify cloud
      expect(mockSyncService.transactionCount, 1);

      // Verify local
      await storageService.setStorageMode(StorageMode.localOnly);
      final localTransactions = await storageService.loadTransactions();
      expect(localTransactions.length, 1);
    });

    test('deleteTransaction removes locally and from cloud', () async {
      await storageService.setStorageMode(StorageMode.cloudSync);

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

      await storageService.saveTransactions(transactions);
      
      // Delete one
      await storageService.deleteTransaction(2, [transactions[0]]);

      // Verify cloud has one less
      final cloudTransactions = await mockSyncService.loadTransactions();
      expect(cloudTransactions.length, 1);
      expect(cloudTransactions[0].id, 1);

      // Verify local
      await storageService.setStorageMode(StorageMode.localOnly);
      final localTransactions = await storageService.loadTransactions();
      expect(localTransactions.length, 1);
      expect(localTransactions[0].id, 1);
    });
  });
}
