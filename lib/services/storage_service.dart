import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import 'observability_service.dart';
import 'sync_service.dart';

/// Storage mode for the application.
///
/// - [localOnly]: Data is stored only on the local device.
/// - [cloudSync]: Data is synced to the cloud for cross-device access.
enum StorageMode {
  localOnly,
  cloudSync,
}

/// Service for managing transaction storage.
///
/// This service provides a unified interface for storing transactions both
/// locally (SharedPreferences) and in the cloud (via [SyncService]).
///
/// Features:
/// - **Local-first**: Transactions are always stored locally for offline access
/// - **Cloud sync**: When enabled, transactions are synced to the cloud
/// - **Fallback behavior**: If cloud sync fails, local storage is used
/// - **Project-scoped**: Transactions are stored per project
///
/// The [SyncService] implementation can be swapped to use different backends
/// (Firestore, REST API, etc.) without changing this class.
class StorageService {
  static const String _keyPrefix = 'project-finances-';
  static const String _syncModeKey = 'storage_sync_mode';
  final ObservabilityService _observability = ObservabilityService();

  /// Current project ID for scoping transactions
  String? _currentProjectId;

  /// Optional sync service for cloud storage.
  /// Set this to enable cloud sync functionality.
  SyncService? syncService;

  /// Current storage mode.
  /// Defaults to [StorageMode.localOnly].
  StorageMode _storageMode = StorageMode.localOnly;

  /// Gets the current storage mode.
  StorageMode get storageMode => _storageMode;

  /// Creates a new StorageService.
  ///
  /// [syncService] - Optional sync service for cloud storage.
  /// [projectId] - Optional project ID to scope transactions.
  StorageService({this.syncService, String? projectId})
      : _currentProjectId = projectId;

  /// Set the current project ID for scoping transactions.
  void setProjectId(String projectId) {
    _currentProjectId = projectId;
  }

  /// Get the storage key for the current project.
  String get _key {
    if (_currentProjectId == null) {
      throw StateError(
          'Project ID is not set. Accessing storage without a project ID can lead to data corruption. This should only happen during migration.');
    }
    return '$_keyPrefix$_currentProjectId';
  }

  /// Initializes the storage service and loads the saved storage mode.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_syncModeKey);
    if (savedMode == 'cloudSync') {
      _storageMode = StorageMode.cloudSync;
    } else {
      _storageMode = StorageMode.localOnly;
    }
  }

  /// Sets the storage mode.
  ///
  /// When switching to [StorageMode.cloudSync], triggers an initial sync
  /// to upload local data to the cloud.
  Future<void> setStorageMode(StorageMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _syncModeKey,
      mode == StorageMode.cloudSync ? 'cloudSync' : 'localOnly',
    );
    _storageMode = mode;
  }

  /// Checks if cloud sync is available.
  ///
  /// Returns true if a sync service is configured and the user is authenticated.
  Future<bool> isSyncAvailable() async {
    if (syncService == null) {
      return false;
    }
    try {
      return await syncService!.isAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Load transactions from storage.
  ///
  /// In [StorageMode.cloudSync], attempts to load from cloud first,
  /// falling back to local storage if unavailable.
  /// In [StorageMode.localOnly], loads from local storage only.
  Future<List<Transaction>> loadTransactions() async {
    try {
      // In cloud sync mode, try to load from cloud first
      if (_storageMode == StorageMode.cloudSync && syncService != null) {
        try {
          final isSyncAvailable = await syncService!.isAvailable();
          if (isSyncAvailable) {
            final cloudTransactions = await syncService!.loadTransactions();
            // Update local cache with cloud data
            await _saveToLocalStorage(cloudTransactions);
            return cloudTransactions;
          }
        } catch (e, stackTrace) {
          _observability.trackError(
            e,
            stackTrace: stackTrace,
            context: {
              'operation': 'load_transactions_cloud',
              'storage_key': _key
            },
          );
          // Fall through to local storage
        }
      }

      // Load from local storage
      return await _loadFromLocalStorage();
    } catch (e, stackTrace) {
      _observability.trackError(
        e,
        stackTrace: stackTrace,
        context: {'operation': 'load_transactions', 'storage_key': _key},
      );
      return [];
    }
  }

  /// Save transactions to storage.
  ///
  /// Always saves to local storage first, then syncs to cloud if enabled.
  Future<void> saveTransactions(List<Transaction> transactions) async {
    // Always save locally first (local-first approach)
    await _saveToLocalStorage(transactions);

    // Sync to cloud if enabled
    if (_storageMode == StorageMode.cloudSync && syncService != null) {
      try {
        final isSyncAvailable = await syncService!.isAvailable();
        if (isSyncAvailable) {
          await syncService!.saveTransactions(transactions);
        }
      } catch (e, stackTrace) {
        _observability.trackError(
          e,
          stackTrace: stackTrace,
          context: {
            'operation': 'save_transactions_cloud',
            'storage_key': _key,
            'transaction_count': transactions.length.toString(),
          },
        );
        // Local save succeeded, cloud sync failed - acceptable in local-first model
      }
    }
  }

  /// Adds a single transaction.
  ///
  /// This is more efficient than saving all transactions when only adding one.
  Future<void> addTransaction(
      Transaction transaction, List<Transaction> allTransactions) async {
    // Save all transactions locally
    await _saveToLocalStorage(allTransactions);

    // Sync to cloud if enabled
    if (_storageMode == StorageMode.cloudSync && syncService != null) {
      try {
        final isSyncAvailable = await syncService!.isAvailable();
        if (isSyncAvailable) {
          await syncService!.addTransaction(transaction);
        }
      } catch (e, stackTrace) {
        _observability.trackError(
          e,
          stackTrace: stackTrace,
          context: {
            'operation': 'add_transaction_cloud',
            'transaction_id': transaction.id.toString(),
          },
        );
      }
    }
  }

  /// Deletes a single transaction.
  ///
  /// This is more efficient than saving all transactions when only deleting one.
  Future<void> deleteTransaction(
      int transactionId, List<Transaction> remainingTransactions) async {
    // Save remaining transactions locally
    await _saveToLocalStorage(remainingTransactions);

    // Sync deletion to cloud if enabled
    if (_storageMode == StorageMode.cloudSync && syncService != null) {
      try {
        final isSyncAvailable = await syncService!.isAvailable();
        if (isSyncAvailable) {
          await syncService!.deleteTransaction(transactionId);
        }
      } catch (e, stackTrace) {
        _observability.trackError(
          e,
          stackTrace: stackTrace,
          context: {
            'operation': 'delete_transaction_cloud',
            'transaction_id': transactionId.toString(),
          },
        );
      }
    }
  }

  /// Clear all data (useful for testing and account deletion).
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);

    // Clear cloud data if sync is enabled
    if (_storageMode == StorageMode.cloudSync && syncService != null) {
      try {
        final isSyncAvailable = await syncService!.isAvailable();
        if (isSyncAvailable) {
          await syncService!.clearAll();
        }
      } catch (e, stackTrace) {
        _observability.trackError(
          e,
          stackTrace: stackTrace,
          context: {'operation': 'clear_all_cloud'},
        );
      }
    }
  }

  /// Forces a sync from local storage to cloud.
  ///
  /// Useful when enabling sync for the first time or after offline changes.
  /// Returns true if sync was successful, false otherwise.
  Future<bool> forceSyncToCloud() async {
    if (syncService == null) {
      return false;
    }

    try {
      final isSyncAvailable = await syncService!.isAvailable();
      if (!isSyncAvailable) {
        return false;
      }

      final localTransactions = await _loadFromLocalStorage();
      await syncService!.saveTransactions(localTransactions);
      return true;
    } catch (e, stackTrace) {
      _observability.trackError(
        e,
        stackTrace: stackTrace,
        context: {'operation': 'force_sync_to_cloud'},
      );
      return false;
    }
  }

  /// Forces a sync from cloud to local storage.
  ///
  /// Useful when logging in on a new device.
  /// Returns the transactions loaded from cloud, or null if sync failed.
  Future<List<Transaction>?> forceSyncFromCloud() async {
    if (syncService == null) {
      return null;
    }

    try {
      final isSyncAvailable = await syncService!.isAvailable();
      if (!isSyncAvailable) {
        return null;
      }

      final cloudTransactions = await syncService!.loadTransactions();
      await _saveToLocalStorage(cloudTransactions);
      return cloudTransactions;
    } catch (e, stackTrace) {
      _observability.trackError(
        e,
        stackTrace: stackTrace,
        context: {'operation': 'force_sync_from_cloud'},
      );
      return null;
    }
  }

  /// Gets the last sync time from the cloud.
  Future<DateTime?> getLastSyncTime() async {
    if (syncService == null) {
      return null;
    }

    try {
      return await syncService!.getLastSyncTime();
    } catch (e) {
      return null;
    }
  }

  // Private methods for local storage operations

  Future<List<Transaction>> _loadFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Transaction.fromJson(json)).toList();
  }

  Future<void> _saveToLocalStorage(List<Transaction> transactions) async {
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
          'operation': 'save_transactions_local',
          'storage_key': _key,
          'transaction_count': transactions.length.toString(),
        },
      );
    }
  }
}
