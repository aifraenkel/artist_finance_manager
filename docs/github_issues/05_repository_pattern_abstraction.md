# Title: Repository Pattern & Data Layer Abstraction

## Labels
enhancement, architecture, backend, medium-priority

## Body

## Overview

Implement the Repository Pattern to abstract data persistence and enable easy migration from local storage to cloud backend without rewriting business logic, as required by `claude.md` section 6.

## Background

`claude.md` emphasizes:
- **Golden Rule:** "Choose the simplest solution now, but never block future scalability"
- **Persistence Abstraction:** "Easy to swap Firestore → PostgreSQL → Distributed DB"
- **Current Phase:** Simple local storage (SharedPreferences)
- **Future Phase:** Cloud backend with sync, scalable to millions of users

**Current State:** Likely direct coupling to SharedPreferences throughout the codebase.

## Requirements

### 1. Repository Pattern Implementation

Create abstract repository interfaces for all data operations:

```dart
// Abstract interface
abstract class TransactionRepository {
  Future<void> save(Transaction transaction);
  Future<Transaction?> findById(String id);
  Future<List<Transaction>> findAll();
  Future<void> delete(String id);
  Stream<List<Transaction>> watchAll();
}
```

**Benefits:**
- Business logic depends on interface, not implementation
- Easy to swap persistence technology
- Easy to mock for testing
- Single source of truth for data operations

### 2. Data Layer Architecture

```
Business Logic (Services)
    ↓ (depends on)
Repository Interface (Abstract)
    ↓ (implemented by)
LocalDataSource ← → RemoteDataSource
    ↓                     ↓
SharedPreferences    Cloud Backend (Firestore/API)
```

### 3. Implementation Phases

**Phase 1: Local Storage (Current)**
```dart
class LocalTransactionRepository implements TransactionRepository {
  LocalTransactionRepository(this._storage);
  final StorageService _storage;

  @override
  Future<void> save(Transaction transaction) async {
    final transactions = await findAll();
    transactions.add(transaction);
    await _storage.saveTransactions(transactions);
  }

  @override
  Future<List<Transaction>> findAll() async {
    return await _storage.loadTransactions();
  }

  // ... other methods
}
```

**Phase 2: Cloud Backend (Future)**
```dart
class RemoteTransactionRepository implements TransactionRepository {
  RemoteTransactionRepository(this._api);
  final ApiClient _api;

  @override
  Future<void> save(Transaction transaction) async {
    await _api.post('/transactions', transaction.toJson());
  }

  @override
  Future<List<Transaction>> findAll() async {
    final response = await _api.get('/transactions');
    return response.map((json) => Transaction.fromJson(json)).toList();
  }

  // ... other methods
}
```

**Phase 3: Hybrid (Local + Remote with Sync)**
```dart
class SyncTransactionRepository implements TransactionRepository {
  SyncTransactionRepository(this._local, this._remote, this._sync);
  final LocalTransactionRepository _local;
  final RemoteTransactionRepository _remote;
  final SyncService _sync;

  @override
  Future<void> save(Transaction transaction) async {
    // Save locally first (offline-first)
    await _local.save(transaction);

    // Queue for sync
    await _sync.queueForSync(transaction);
  }

  @override
  Future<List<Transaction>> findAll() async {
    // Return local data immediately
    return await _local.findAll();
  }

  @override
  Stream<List<Transaction>> watchAll() {
    // Listen to both local and remote changes
    return _sync.mergeStreams(
      _local.watchAll(),
      _remote.watchAll(),
    );
  }

  // ... other methods
}
```

### 4. Repository Types Needed

**Priority 1:**
- [ ] TransactionRepository
- [ ] UserRepository (for auth state)
- [ ] PreferencesRepository (from preferences system)

**Priority 2:**
- [ ] ProjectRepository (for #16 - multiple projects)
- [ ] AnalyticsRepository (for #15 - charts and analytics)
- [ ] BudgetRepository (for #17 - budget planning)

### 5. Architecture Layers

**Enforce strict layering:**

```dart
// ✅ GOOD: Business logic depends on repository interface
class TransactionService {
  TransactionService(this._repository);
  final TransactionRepository _repository;

  Future<void> addTransaction(Transaction t) async {
    if (t.amount <= 0) throw ArgumentError('Amount must be positive');
    await _repository.save(t);
  }
}

// ❌ BAD: Business logic coupled to specific storage
class TransactionService {
  final _storage = SharedPreferences.getInstance(); // Coupled!

  Future<void> addTransaction(Transaction t) async {
    // Direct SharedPreferences usage - hard to change later
  }
}
```

### 6. Dependency Injection

- [ ] Inject repositories via DI container
- [ ] Swap implementations based on environment/config
- [ ] Easy to provide mock repositories for testing

## Acceptance Criteria

- [ ] Repository interfaces defined for all data domains
- [ ] LocalRepository implementations complete
- [ ] RemoteRepository interfaces defined (implementation when backend ready)
- [ ] All services depend on repository interfaces, not concrete implementations
- [ ] No direct SharedPreferences or database calls in business logic
- [ ] Repositories injected via DI
- [ ] Comprehensive unit tests for repositories
- [ ] Mock repositories for testing services
- [ ] Documentation for repository pattern usage

## Implementation Strategy

### Phase 1: Define Interfaces
1. Identify all data operations in current code
2. Define repository interfaces
3. Document repository contracts

### Phase 2: Local Implementation
1. Create LocalTransactionRepository
2. Migrate existing storage code to repository
3. Update services to use repository interface
4. Add tests

### Phase 3: Refactor Services
1. Update all services to depend on repositories
2. Remove direct storage dependencies
3. Set up dependency injection
4. Test thoroughly

### Phase 4: Prepare for Remote
1. Define RemoteRepository interfaces
2. Create mock remote repositories
3. Design sync logic (for hybrid approach)
4. Document migration path to cloud backend

## Testing Strategy

### Unit Tests
```dart
test('LocalTransactionRepository saves transaction', () async {
  final mockStorage = MockStorageService();
  final repository = LocalTransactionRepository(mockStorage);

  await repository.save(testTransaction);

  verify(mockStorage.saveTransactions(any)).called(1);
});
```

### Integration Tests
```dart
testWidgets('Adding transaction updates UI via repository', (tester) async {
  final repository = LocalTransactionRepository(StorageService());
  final service = TransactionService(repository);

  await service.addTransaction(testTransaction);

  expect(await repository.findAll(), contains(testTransaction));
});
```

## Related Issues

- Relates to: #13 - Backend sync support (provides abstraction layer)
- Relates to: State Management Migration (repositories integrated with providers)
- Relates to: #16 - Multiple projects support (ProjectRepository)
- Relates to: Preferences System Architecture (PreferencesRepository)

## Related Files

- `lib/repositories/` (new directory)
- `lib/repositories/transaction_repository.dart` (new)
- `lib/repositories/local_transaction_repository.dart` (new)
- `lib/services/transaction_service.dart` (update)
- `lib/services/storage_service.dart` (refactor)
- `claude.md` - Section 6

## Priority

**Medium** - Important for future scalability, but works without it now

## Benefits

1. **Easy Backend Migration:** Swap implementations without changing business logic
2. **Better Testing:** Mock repositories for isolated tests
3. **Single Responsibility:** Each repository handles one data domain
4. **Consistency:** All data operations follow same pattern
5. **Flexibility:** Can combine multiple data sources (local + remote)

## Migration Effort

**Estimated effort:** Medium
- Need to refactor existing storage code
- Update all services
- Comprehensive testing required
- Can be done incrementally (one repository at a time)
