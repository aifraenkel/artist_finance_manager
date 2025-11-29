# Update for Issue #13: Add backend sync support

## Current Description
"Enable state storage and data synchronization thought devices. The BE should be build on top of GCP. That's my prefered cloud provider."

## Suggested Enhanced Description

---

## Overview

Enable cross-device data synchronization with offline-first architecture, built on Google Cloud Platform (GCP), as specified in `claude.md` section 6.

## Background

`claude.md` emphasizes:
- **Offline-First:** "Store locally first, sync to backend when online"
- **No Data Loss:** "No data loss if sync fails"
- **Conflict Resolution:** "last-write-wins or user prompt"
- **Auto-Save:** "Auto-save everything"
- **Stateless Backend:** Backend must be horizontally scalable

**Current State:** App uses local storage only (SharedPreferences). Data doesn't sync across devices.

## Requirements

### 1. Offline-First Architecture

**Data Flow:**
```
User Action
    ↓
1. Save locally FIRST (immediate)
2. Queue for sync (background)
3. Sync to backend when online
4. Update from backend periodically
5. Resolve conflicts if needed
```

**Key Principles:**
- [ ] Local changes are immediate (no blocking on network)
- [ ] App fully functional offline
- [ ] Sync happens in background
- [ ] No data loss if sync fails
- [ ] Retry failed syncs with exponential backoff

### 2. Backend Architecture (GCP)

**Technology Stack:**

**Backend:**
- [ ] **Cloud Run** - Stateless backend service (horizontally scalable)
- [ ] **Firestore** - NoSQL database (initial phase)
- [ ] **PostgreSQL** - Relational database (future migration, if needed)
- [ ] **Cloud Storage** - File storage (for receipt photos)
- [ ] **Firebase Auth** - Authentication (or Cloud Identity Platform)

**Why this stack:**
- Stateless backend (required by claude.md)
- Horizontal scaling ready
- Easy to swap Firestore → PostgreSQL later
- All GCP-native services

**API Design:**
- RESTful API or GraphQL
- JWT authentication
- Versioned API endpoints
- Rate limiting
- Error handling

### 3. Sync Logic

**Conflict Resolution Strategies:**

**Option A: Last-Write-Wins (Simple)**
```dart
// Always use most recent timestamp
if (remote.updatedAt > local.updatedAt) {
  return remote;  // Server wins
} else {
  return local;   // Local wins
}
```

**Option B: User Prompt (Complex but safer)**
```dart
// Show user both versions and let them choose
if (hasConflict(local, remote)) {
  showConflictDialog(local, remote);
  // User picks which version to keep
}
```

**Recommended:** Start with Last-Write-Wins, add User Prompt for critical data later.

**Sync Triggers:**
- [ ] Automatic sync every N minutes (when online)
- [ ] Sync on app foreground (when user opens app)
- [ ] Manual sync button
- [ ] Sync after local changes (debounced)

### 4. Data Models for Sync

Update models to support sync metadata:

```dart
class Transaction {
  final String id;  // UUID
  final int amountInCents;
  final String description;
  final DateTime createdAt;

  // Sync metadata
  final DateTime updatedAt;  // Last modification time
  final String deviceId;     // Which device created/updated
  final bool synced;         // Has it been synced to server?
  final int syncVersion;     // Version number for conflict resolution
}
```

### 5. Repository Pattern Integration

Use Repository Pattern (separate issue) for clean sync architecture:

```dart
// Abstract interface
abstract class TransactionRepository {
  Future<void> save(Transaction t);
  Future<List<Transaction>> findAll();
  Stream<List<Transaction>> watchAll();
}

// Hybrid implementation (local + remote)
class SyncTransactionRepository implements TransactionRepository {
  SyncTransactionRepository(this._local, this._remote, this._sync);

  final LocalTransactionRepository _local;
  final RemoteTransactionRepository _remote;
  final SyncService _sync;

  @override
  Future<void> save(Transaction t) async {
    // 1. Save locally first (offline-first)
    await _local.save(t);

    // 2. Queue for sync
    await _sync.queueForSync(t);

    // 3. Sync in background
    _sync.syncInBackground();
  }

  @override
  Stream<List<Transaction>> watchAll() {
    // Listen to both local and remote changes
    return _sync.mergeStreams(
      _local.watchAll(),
      _remote.watchAll(),
    );
  }
}
```

### 6. Sync Service

Create dedicated sync service:

```dart
abstract class SyncService {
  /// Queue item for sync
  Future<void> queueForSync(Syncable item);

  /// Trigger sync now
  Future<void> syncNow();

  /// Sync in background
  void syncInBackground();

  /// Get sync status
  Stream<SyncStatus> get syncStatus;

  /// Resolve conflict
  Future<void> resolveConflict(Conflict conflict, Resolution resolution);
}

enum SyncStatus {
  idle,
  syncing,
  error,
  conflictNeedsResolution,
}
```

### 7. Backend API Endpoints

**Required endpoints:**

```
POST   /api/v1/transactions          - Create transaction
GET    /api/v1/transactions          - List all user's transactions
GET    /api/v1/transactions/:id      - Get specific transaction
PUT    /api/v1/transactions/:id      - Update transaction
DELETE /api/v1/transactions/:id      - Delete transaction
POST   /api/v1/sync                  - Batch sync
GET    /api/v1/sync/status           - Get sync status
```

**Sync endpoint (efficient batch sync):**
```dart
POST /api/v1/sync
{
  "lastSyncTime": "2024-01-15T10:30:00Z",
  "changes": [
    {"id": "123", "action": "create", "data": {...}},
    {"id": "456", "action": "update", "data": {...}},
    {"id": "789", "action": "delete"}
  ]
}

Response:
{
  "serverChanges": [
    {"id": "111", "action": "create", "data": {...}},
  ],
  "conflicts": [
    {"id": "123", "local": {...}, "remote": {...}}
  ],
  "syncTime": "2024-01-15T10:35:00Z"
}
```

### 8. Security

- [ ] JWT authentication for all API calls
- [ ] User can only access their own data (row-level security)
- [ ] HTTPS only (TLS encryption)
- [ ] Rate limiting to prevent abuse
- [ ] Input validation and sanitization
- [ ] GDPR compliance (data export, deletion)

### 9. Monitoring & Observability

- [ ] Log all sync operations
- [ ] Track sync success/failure rates
- [ ] Monitor sync latency
- [ ] Alert on sync failures
- [ ] Grafana dashboards for sync metrics

## Acceptance Criteria

- [ ] Backend deployed on GCP Cloud Run
- [ ] Firestore database configured
- [ ] API endpoints implemented
- [ ] Authentication working (Firebase Auth)
- [ ] Offline-first sync implemented
- [ ] Local changes save immediately
- [ ] Background sync working
- [ ] Conflict resolution working (last-write-wins)
- [ ] No data loss on sync failures
- [ ] Retry logic with exponential backoff
- [ ] Sync status visible to user
- [ ] Manual sync button working
- [ ] Cross-device sync tested
- [ ] Security implemented (JWT, HTTPS)
- [ ] Documentation for backend API
- [ ] Deployment scripts updated

## Implementation Strategy

### Phase 1: Backend Foundation (Week 1-2)
1. Set up GCP project
2. Create Cloud Run service
3. Set up Firestore database
4. Implement authentication
5. Create API endpoints
6. Deploy to GCP

### Phase 2: Offline-First Frontend (Week 3-4)
1. Implement SyncService
2. Add sync metadata to models
3. Update repositories for sync
4. Implement local-first save logic
5. Add sync queue

### Phase 3: Sync Logic (Week 5-6)
1. Implement background sync
2. Add conflict resolution (last-write-wins)
3. Implement retry logic
4. Add sync status UI
5. Test cross-device sync

### Phase 4: Polish & Production (Week 7-8)
1. Add manual sync button
2. Implement sync indicators
3. Error handling and logging
4. Security hardening
5. Performance testing
6. Documentation

## Testing Strategy

- [ ] Unit tests for sync logic
- [ ] Integration tests for offline-first behavior
- [ ] End-to-end tests for cross-device sync
- [ ] Test conflict resolution
- [ ] Test sync failures and retries
- [ ] Load testing backend
- [ ] Security testing

## Related Issues

- Depends on: Repository Pattern & Data Layer Abstraction
- Relates to: User Preferences System (sync preferences)
- Relates to: #20 - Multi-currency (sync exchange rates)
- Relates to: #31 - User consent (GDPR compliance)

## Related Files

- `backend/` (new directory for backend code)
- `lib/services/sync_service.dart` (new)
- `lib/repositories/sync_transaction_repository.dart` (new)
- `lib/models/transaction.dart` (add sync metadata)
- `scripts/deploy-backend.sh` (new)
- `claude.md` - Section 6

## Priority

**High** - Critical for multi-device users and scaling

## Resources

- [GCP Cloud Run](https://cloud.google.com/run)
- [Firestore](https://firebase.google.com/docs/firestore)
- [Firebase Auth](https://firebase.google.com/docs/auth)
- [Offline-First Architecture](https://www.infoq.com/articles/offline-first-architecture/)
