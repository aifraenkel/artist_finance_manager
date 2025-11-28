import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import 'observability_service.dart';

class StorageService {
  static const String _key = 'project-finances';
  final ObservabilityService _observability = ObservabilityService();

  // Load transactions from local storage
  Future<List<Transaction>> loadTransactions() async {
    try {
      // start loadTransactions
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_key);

      if (jsonString == null || jsonString.isEmpty) {
        // no stored json
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      final result = jsonList.map((json) => Transaction.fromJson(json)).toList();
      // parsed transactions
      return result;
    } catch (e, stackTrace) {
      // error loading transactions: $e
      _observability.trackError(
        e,
        stackTrace: stackTrace,
        context: {'operation': 'load_transactions', 'storage_key': _key},
      );
      return [];
    }
  }

  // Save transactions to local storage
  Future<void> saveTransactions(List<Transaction> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = transactions.map((t) => t.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await prefs.setString(_key, jsonString);
    } catch (e, stackTrace) {
      _observability.trackError(
        e,
        stackTrace: stackTrace,
        context: {
          'operation': 'save_transactions',
          'storage_key': _key,
          'transaction_count': transactions.length.toString(),
        },
      );
      print('Error saving transactions: $e');
    }
  }

  // Clear all data (useful for testing)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
