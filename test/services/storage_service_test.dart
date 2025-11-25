import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_finance_manager/models/transaction.dart';
import 'package:artist_finance_manager/services/storage_service.dart';

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
}
