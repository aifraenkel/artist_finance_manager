# Title: User Preferences System Architecture

## Labels
enhancement, architecture, preferences, medium-priority

## Body

## Overview

Implement a comprehensive, extensible user preferences system that supports cross-device synchronization, offline-first behavior, and reactive UI updates, as mandated by `claude.md` section 5.

## Background

`claude.md` section 5 describes a complete preferences architecture that goes beyond individual features like dark mode (#19) or multi-currency (#20). The system must:
- Persist across devices
- Sync automatically
- Update UI reactively
- Work offline-first with eventual sync

## Requirements

### 1. Core Preferences Service

Create an abstract, extensible preferences service:

```dart
abstract class PreferencesService {
  Future<T?> get<T>(String key);
  Future<void> set<T>(String key, T value);
  Stream<T?> watch<T>(String key);
}
```

**Features:**
- [ ] Type-safe get/set operations
- [ ] Reactive streams for UI updates
- [ ] Support for all primitive types and custom objects
- [ ] JSON serialization for complex types
- [ ] Validation and constraints

### 2. Supported Preferences

**Current preferences (Priority 1):**
- [ ] Language (locale)
- [ ] Currency (display currency)
- [ ] Theme (light/dark/high-contrast)
- [ ] Date format
- [ ] Number format
- [ ] Time zone

**Future preferences (Priority 2):**
- [ ] Notification preferences
- [ ] Privacy settings
- [ ] Default transaction categories
- [ ] Auto-save interval
- [ ] Data export format preferences

### 3. Offline-First with Sync

**Local Storage:**
- [ ] Store preferences locally first (SharedPreferences/Hive)
- [ ] Immediate persistence on change
- [ ] No blocking on network operations

**Cloud Sync (when backend ready):**
- [ ] Automatic sync when online
- [ ] Conflict resolution strategy (last-write-wins or user prompt)
- [ ] No data loss if sync fails
- [ ] Retry logic with exponential backoff
- [ ] Sync status indicators

### 4. Reactive UI Updates

- [ ] Preferences changes trigger UI updates automatically
- [ ] Use streams/providers for reactive updates
- [ ] No manual refresh required
- [ ] Efficient updates (only affected widgets rebuild)

### 5. Dependency Injection

- [ ] Inject PreferencesService via DI container
- [ ] Easy to mock for testing
- [ ] Swappable implementations (local vs. cloud)
- [ ] No direct dependencies on concrete implementations

### 6. Migration & Versioning

- [ ] Schema versioning for preferences
- [ ] Migration logic for schema changes
- [ ] Backward compatibility
- [ ] Safe defaults for missing preferences

## Technical Design

### Architecture

```
UI Layer (Widgets)
    ↓ (watches preference changes)
PreferencesProvider (State Management)
    ↓ (uses)
PreferencesService (Abstract Interface)
    ↓ (implements)
LocalPreferencesService ← → RemotePreferencesService
    ↓                           ↓
SharedPreferences          Cloud Storage (Firestore/Backend)
```

### Code Examples

**Setting a preference:**
```dart
await preferencesService.set('currency', 'EUR');
```

**Getting a preference:**
```dart
final currency = await preferencesService.get<String>('currency');
```

**Watching for changes (reactive):**
```dart
preferencesService.watch<String>('theme').listen((theme) {
  // Update UI automatically
});
```

**In a widget:**
```dart
StreamBuilder<String>(
  stream: preferencesService.watch<String>('currency'),
  builder: (context, snapshot) {
    final currency = snapshot.data ?? 'USD';
    return Text('Currency: $currency');
  },
)
```

## Acceptance Criteria

- [ ] PreferencesService interface defined
- [ ] Local storage implementation complete
- [ ] All required preferences supported
- [ ] Reactive UI updates working
- [ ] Preferences persist across app restarts
- [ ] Type-safe API
- [ ] Comprehensive unit tests
- [ ] Integration tests for preferences flow
- [ ] Documentation for adding new preferences
- [ ] Cloud sync ready (interface defined, implementation when backend ready)

## Implementation Strategy

### Phase 1: Foundation
1. Define PreferencesService abstract interface
2. Implement LocalPreferencesService (SharedPreferences)
3. Set up dependency injection
4. Add unit tests

### Phase 2: Core Preferences
1. Implement language preference
2. Implement currency preference
3. Implement theme preference
4. Add date/number format preferences

### Phase 3: Reactive UI
1. Integrate with state management (Provider/Riverpod)
2. Create PreferencesProvider
3. Update widgets to watch preferences
4. Test reactive updates

### Phase 4: Sync Preparation
1. Define RemotePreferencesService interface
2. Implement conflict resolution logic
3. Add sync status tracking
4. Prepare for backend integration

## Related Issues

- #19 - Dark mode (uses theme preference)
- #20 - Multi-currency support (uses currency preference)
- Relates to: i18n system (uses language preference)
- Blocked by: #13 - Backend sync support (for cloud sync)

## Related Files

- `lib/services/preferences_service.dart` (new)
- `lib/services/local_preferences_service.dart` (new)
- `lib/providers/preferences_provider.dart` (new)
- `lib/models/preferences.dart` (new)
- `claude.md` - Section 5

## Priority

**Medium-High** - Foundation for #19, #20, and i18n features

## Dependencies

- Blocked by: None (can start immediately)
- Blocks: #19 (Dark mode), #20 (Multi-currency), i18n system
