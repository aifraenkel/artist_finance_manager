# Title: State Management Migration (Provider/Riverpod)

## Labels
enhancement, architecture, refactoring, medium-priority

## Body

## Overview

Migrate from StatefulWidget-based state management to Provider or Riverpod for better scalability, testability, and maintainability, as outlined in `claude.md` sections 6 and 12.

## Background

`claude.md` states:
- **Current Phase:** "Simple, minimal complexity" - StatefulWidget is acceptable now
- **Future Phase:** "Must scale without major rewrites"
- **Architecture Evolution:** "Consider Provider or Riverpod for multiple screens with shared state, complex state dependencies, and better testability"

**Current State:** App uses StatefulWidget with setState() - works for single screen but doesn't scale.

## Rationale for Migration

### When to Migrate

Migrate when we encounter:
- ✅ Multiple screens that share state
- ✅ Complex state dependencies between components
- ✅ Need for better testability
- ✅ State logic becoming difficult to manage

### Benefits

- **Better Separation:** UI logic separated from business logic
- **Testability:** State logic can be tested independently
- **Scalability:** Easy to share state across multiple screens
- **Performance:** Fine-grained rebuilds (only affected widgets)
- **Developer Experience:** Better debugging and state inspection

## Requirements

### 1. Choose State Management Solution

**Option A: Provider** (Flutter team recommended)
- Officially recommended by Flutter team
- Good documentation and community support
- Simpler learning curve
- Good enough for most apps

**Option B: Riverpod** (Provider's successor)
- More modern, improved API
- Better compile-time safety
- More flexible and powerful
- Steeper learning curve

**Decision:** To be determined based on team preference and app complexity.

### 2. Architecture Refactoring

**Current:**
```
HomeScreen (StatefulWidget)
  ↓ (setState)
Local State
```

**Target:**
```
HomeScreen (StatelessWidget)
  ↓ (consumes)
Provider<TransactionState>
  ↓ (uses)
TransactionService
  ↓ (uses)
TransactionRepository
```

### 3. Migration Strategy

- [ ] Identify all state in the app
- [ ] Create providers/notifiers for each state domain
- [ ] Migrate services to be provider-based
- [ ] Update widgets to consume providers
- [ ] Remove StatefulWidgets where appropriate
- [ ] Maintain backward compatibility during migration

### 4. State Domains to Migrate

**Priority 1:**
- [ ] Transaction state (list of transactions, add/delete)
- [ ] Summary state (total income, expenses, balance)
- [ ] Authentication state (user, auth status)

**Priority 2:**
- [ ] Preferences state (from preferences system)
- [ ] Theme state
- [ ] Navigation state
- [ ] Loading/error states

## Technical Design

### Example: Transaction Provider

**With Provider:**
```dart
class TransactionProvider extends ChangeNotifier {
  TransactionProvider(this._service);
  final TransactionService _service;

  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  Future<void> addTransaction(Transaction transaction) async {
    await _service.addTransaction(transaction);
    _transactions.add(transaction);
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    _transactions = await _service.loadTransactions();
    notifyListeners();
  }
}
```

**Using in Widget:**
```dart
class TransactionList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    return ListView.builder(
      itemCount: provider.transactions.length,
      itemBuilder: (context, index) {
        return TransactionCard(transaction: provider.transactions[index]);
      },
    );
  }
}
```

### Example: Riverpod Alternative

```dart
final transactionProvider = StateNotifierProvider<TransactionNotifier, List<Transaction>>((ref) {
  final service = ref.watch(transactionServiceProvider);
  return TransactionNotifier(service);
});

class TransactionNotifier extends StateNotifier<List<Transaction>> {
  TransactionNotifier(this._service) : super([]);
  final TransactionService _service;

  Future<void> addTransaction(Transaction transaction) async {
    await _service.addTransaction(transaction);
    state = [...state, transaction];
  }
}
```

## Acceptance Criteria

- [ ] State management solution chosen (Provider or Riverpod)
- [ ] All state domains migrated to providers
- [ ] Widgets updated to use providers (no more setState for shared state)
- [ ] Better separation between UI and business logic
- [ ] All tests passing
- [ ] Test coverage maintained or improved
- [ ] Documentation updated
- [ ] Team trained on new state management approach

## Implementation Strategy

### Phase 1: Setup & Planning
1. Evaluate Provider vs. Riverpod
2. Make decision and document rationale
3. Add dependencies to pubspec.yaml
4. Create migration plan

### Phase 2: Infrastructure
1. Set up provider infrastructure
2. Create base providers/notifiers
3. Set up dependency injection with providers
4. Update main.dart with providers

### Phase 3: Migration (Incremental)
1. Start with transaction state
2. Migrate authentication state
3. Migrate preferences state
4. Migrate remaining state domains
5. Test thoroughly at each step

### Phase 4: Cleanup & Documentation
1. Remove unnecessary StatefulWidgets
2. Clean up old state management code
3. Update documentation
4. Create examples for future features

## Testing Strategy

- [ ] Unit tests for all providers/notifiers
- [ ] Widget tests using ProviderScope/ProviderContainer
- [ ] Integration tests for complete flows
- [ ] Performance testing (ensure no regressions)

## Related Issues

- Relates to: Preferences System Architecture (state management integration)
- Relates to: Repository Pattern (#repository-pattern-data-layer-abstraction)
- Relates to: #19 Dark mode (theme state)
- Relates to: #13 Backend sync (sync state management)

## Related Files

- `lib/providers/` (new directory)
- `lib/screens/home_screen.dart` (migrate)
- `lib/widgets/*.dart` (update to consume providers)
- `lib/main.dart` (add provider setup)
- `pubspec.yaml` (add provider/riverpod dependency)
- `claude.md` - Sections 6, 12

## Priority

**Medium** - Important for scaling, but current StatefulWidget approach works for now

## Migration Effort

**Estimated effort:** Medium
- Small app currently (single screen)
- Can be done incrementally
- Low risk with good testing

## Resources

- [Provider Package](https://pub.dev/packages/provider)
- [Riverpod Package](https://pub.dev/packages/riverpod)
- [Flutter State Management Guide](https://docs.flutter.dev/development/data-and-backend/state-mgmt/intro)
