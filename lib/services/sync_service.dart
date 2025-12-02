import '../models/transaction.dart';

/// Abstract interface for transaction synchronization services.
///
/// This interface defines the contract for syncing transactions across devices.
/// Implementations can use different storage backends (Firestore, REST API, etc.)
/// while maintaining the same interface, making it easy to swap implementations.
///
/// Design follows the Interface Segregation Principle (ISP) and
/// Dependency Inversion Principle (DIP) from SOLID.
abstract class SyncService {
  /// Loads all transactions for the current user from the remote storage.
  ///
  /// Returns an empty list if no transactions exist.
  /// Throws [SyncException] if the sync operation fails.
  Future<List<Transaction>> loadTransactions();

  /// Saves all transactions for the current user to the remote storage.
  ///
  /// [transactions] - The complete list of transactions to save.
  /// This replaces all existing transactions in remote storage.
  /// Throws [SyncException] if the sync operation fails.
  Future<void> saveTransactions(List<Transaction> transactions);

  /// Adds a single transaction to the remote storage.
  ///
  /// [transaction] - The transaction to add.
  /// Throws [SyncException] if the operation fails.
  Future<void> addTransaction(Transaction transaction);

  /// Deletes a single transaction from the remote storage.
  ///
  /// [transactionId] - The ID of the transaction to delete.
  /// Throws [SyncException] if the operation fails.
  Future<void> deleteTransaction(int transactionId);

  /// Clears all transactions for the current user from remote storage.
  ///
  /// Throws [SyncException] if the operation fails.
  Future<void> clearAll();

  /// Checks if the sync service is available and authenticated.
  ///
  /// Returns true if the user is authenticated and sync is available.
  Future<bool> isAvailable();

  /// Gets the last sync timestamp for the current user.
  ///
  /// Returns null if no sync has occurred yet.
  Future<DateTime?> getLastSyncTime();
}

/// Exception thrown when a sync operation fails.
///
/// Contains details about what went wrong during the sync operation.
class SyncException implements Exception {
  /// Error code for programmatic handling
  final String code;

  /// Human-readable error message
  final String message;

  /// Original exception that caused this error (if any)
  final Object? cause;

  SyncException({
    required this.code,
    required this.message,
    this.cause,
  });

  @override
  String toString() => 'SyncException($code): $message';

  /// Common error codes
  static const String notAuthenticated = 'not_authenticated';
  static const String networkError = 'network_error';
  static const String permissionDenied = 'permission_denied';
  static const String notFound = 'not_found';
  static const String unknown = 'unknown';
}
