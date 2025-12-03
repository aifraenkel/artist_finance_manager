# Backend Sync Guide

This guide explains how the backend synchronization feature works in the Art Finance Hub app.

## Overview

The app uses a **local-first architecture** with optional cloud synchronization. This means:

1. **Transactions are always saved locally first** - ensuring fast, responsive UI
2. **When authenticated, data syncs to the cloud** - enabling cross-device access
3. **Offline changes sync when connectivity is restored** - seamless offline experience

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                      HomeScreen                              │
│                         │                                    │
│                         ▼                                    │
│                  StorageService                              │
│                    /         \                               │
│                   /           \                              │
│                  ▼             ▼                             │
│         SharedPreferences    SyncService (interface)         │
│           (local)                 │                          │
│                                   ▼                          │
│                          FirestoreSyncService                │
│                                   │                          │
│                                   ▼                          │
│                           Cloud Firestore                    │
└─────────────────────────────────────────────────────────────┘
```

### Storage Modes

| Mode | Description | When Used |
|------|-------------|-----------|
| `localOnly` | Data stored only on device | Unauthenticated users |
| `cloudSync` | Data synced to cloud | Authenticated users |

### Data Isolation

Each user's transactions are stored in a separate Firestore subcollection:

```
users/{userId}/transactions/{transactionId}
```

Firestore security rules ensure users can only access their own data:

```javascript
match /users/{userId}/transactions/{transactionId} {
  allow read, write: if request.auth.uid == userId;
}
```

## Usage

### For Users

1. **Without Authentication**: Data is stored locally only
2. **With Authentication**: 
   - Data automatically syncs to cloud
   - Use the sync button (↻) to manually refresh from cloud
   - Access your data from any device

### For Developers

#### Basic Usage

```dart
// Create storage service with sync support
final syncService = FirestoreSyncService();
final storageService = StorageService(syncService: syncService);
await storageService.initialize();

// Enable cloud sync (typically when user is authenticated)
await storageService.setStorageMode(StorageMode.cloudSync);

// Load transactions (will sync from cloud if in cloudSync mode)
final transactions = await storageService.loadTransactions();

// Save transactions (saves locally and syncs to cloud)
await storageService.saveTransactions(transactions);
```

#### Efficient Single Operations

```dart
// Add single transaction (more efficient than saving all)
await storageService.addTransaction(newTransaction, allTransactions);

// Delete single transaction
await storageService.deleteTransaction(transactionId, remainingTransactions);
```

#### Manual Sync Operations

```dart
// Force upload local data to cloud
final success = await storageService.forceSyncToCloud();

// Force download cloud data to local
final transactions = await storageService.forceSyncFromCloud();
```

## Testing

### Unit Tests

Tests are located in `test/services/`:

- `sync_service_test.dart` - Tests for SyncService interface
- `storage_service_test.dart` - Tests for StorageService with mock sync

Run tests:
```bash
flutter test test/services/
```

### Testing with Mock

Use `MockSyncService` for testing without Firebase:

```dart
final mockSyncService = MockSyncService();
final storageService = StorageService(syncService: mockSyncService);

// Configure mock behavior
mockSyncService.setAvailable(true);
mockSyncService.setShouldThrowOnSave(false);
```

## Migration Guide

If you need to migrate to a different backend:

### 1. Export Data from Firestore

Use Firebase Admin SDK or Cloud Functions:

```javascript
const admin = require('firebase-admin');

async function exportUserTransactions(userId) {
  const snapshot = await admin.firestore()
    .collection('users')
    .doc(userId)
    .collection('transactions')
    .get();
  
  return snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  }));
}
```

### 2. Create New SyncService Implementation

```dart
class RestApiSyncService implements SyncService {
  @override
  Future<List<Transaction>> loadTransactions() async {
    // Implement REST API call
  }

  // Implement other methods...
}
```

### 3. Update App Configuration

```dart
// Switch to new implementation
final syncService = RestApiSyncService();
final storageService = StorageService(syncService: syncService);
```

## Troubleshooting

### Sync Issues

| Issue | Solution |
|-------|----------|
| Sync not working | Check authentication status |
| Permission denied | Verify Firestore rules are deployed |
| Network error | Check internet connection |
| Data not appearing | Use manual sync button to refresh |

### Debug Logging

Enable debug logging in `FirestoreSyncService`:

```dart
// Errors are logged via ObservabilityService
_observability.trackError(
  e,
  context: {'operation': 'sync_operation'},
);
```

## Security Considerations

1. **Data Isolation**: Firestore rules enforce user-level access
2. **Encrypted Transit**: All data encrypted via HTTPS
3. **Encrypted at Rest**: Firebase encrypts stored data
4. **Token Validation**: Authentication required for sync operations
5. **Field Validation**: Firestore rules validate data structure

## API Reference

### SyncService Interface

| Method | Description |
|--------|-------------|
| `loadTransactions()` | Load all transactions from cloud |
| `saveTransactions(List<Transaction>)` | Save all transactions to cloud |
| `addTransaction(Transaction)` | Add single transaction |
| `deleteTransaction(int)` | Delete single transaction |
| `clearAll()` | Clear all transactions |
| `isAvailable()` | Check if sync is available |
| `getLastSyncTime()` | Get last sync timestamp |

### StorageService

| Method | Description |
|--------|-------------|
| `initialize()` | Initialize and load saved settings |
| `setStorageMode(StorageMode)` | Set local-only or cloud-sync mode |
| `isSyncAvailable()` | Check if cloud sync is available |
| `loadTransactions()` | Load from local or cloud |
| `saveTransactions(List<Transaction>)` | Save to local and cloud |
| `forceSyncToCloud()` | Upload local data to cloud |
| `forceSyncFromCloud()` | Download cloud data to local |
