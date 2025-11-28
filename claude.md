# Claude.md - Contributor Guide for LLM Contributors

**Version:** 1.0.0
**Last Updated:** 2025-11-28
**Project:** Artist Finance Manager

---

## About This Document

This document serves as the **authoritative guide** for all LLM contributors (including Claude Code and future AI assistants) working on the Artist Finance Manager project. Every contribution must follow these guidelines strictly to maintain code quality, architectural integrity, and long-term maintainability.

**Key Principle:** This guide is not a suggestion—it is a requirement. All LLM contributors must treat this document as the source of truth for how to work on this codebase.

---

## Table of Contents

1. [Project Identity](#1-project-identity)
2. [Cross-Platform UI Consistency](#2-cross-platform-ui-consistency)
3. [Multi-User Global Product](#3-multi-user-global-product)
4. [Authentication Architecture](#4-authentication-architecture)
5. [User Preferences System](#5-user-preferences-system)
6. [Architecture and Scaling Requirements](#6-architecture-and-scaling-requirements)
7. [Testing Philosophy](#7-testing-philosophy)
8. [Test-Driven Development (TDD/ATDD)](#8-test-driven-development-tddatdd)
9. [Coding Standards for Maintainability](#9-coding-standards-for-maintainability)
10. [CI/CD and Deployment](#10-cicd-and-deployment)
11. [Repository Hygiene](#11-repository-hygiene)
12. [Project Structure and Style](#12-project-structure-and-style)
13. [Explicit Instructions for Claude Code](#13-explicit-instructions-for-claude-code)

---

## 1. Project Identity

### What is Artist Finance Manager?

**Artist Finance Manager** is a multi-device, global application designed for artists to track and manage their finances across projects.

### Technology Stack

- **Frontend:** Flutter (Web, Android, iOS)
- **Backend:** Google Cloud Platform (Cloud Run)
- **Database:** Initially simple storage, architected for future scaling
- **Deployment:** GCP Cloud Run, GCP Storage/Hosting

### Design Philosophy

- **Current Phase:** Simple, minimal complexity
- **Future Phase:** Must scale without major rewrites
- **Key Rule:** Choose the simplest solution now, but never block future scalability

### Target Users

- Artists worldwide
- All experience levels
- All device types
- All languages and currencies

---

## 2. Cross-Platform UI Consistency

### Platform Support

The app **must** behave identically across:

- **Web** (Desktop and Mobile browsers)
- **iOS** (iPhone and iPad)
- **Android** (Phone and Tablet)

### UI Requirements

✅ **DO:**
- Use Flutter's platform-adaptive widgets where appropriate
- Test all features on all three platforms
- Ensure responsive layouts work on all screen sizes
- Maintain consistent behavior across platforms
- Use platform-agnostic abstractions for platform-specific features

❌ **DON'T:**
- Create platform-specific UI logic unless absolutely necessary
- Use hardcoded pixel values
- Assume screen sizes or capabilities
- Build features that only work on one platform

### Testing Cross-Platform Features

Every UI feature must have:
1. **Widget tests** that validate behavior
2. **Visual regression tests** where applicable
3. **Manual testing checklist** for each platform before merging

---

## 3. Multi-User Global Product

### Global Scale Requirements

The app must support:

- **Many users worldwide** (future millions of users)
- **Multiple time zones** and date formats
- **Multiple currencies** and number formats
- **Multiple languages** and text directions (LTR/RTL)

### User Experience Principles

1. **Simplicity First**
   - Minimize steps to complete any task
   - Clear, obvious UI elements
   - No hidden features or complex workflows

2. **High Accessibility**
   - Full screen reader support
   - Keyboard navigation
   - High contrast modes
   - Scalable text
   - Color-blind friendly palette

3. **Low Friction**
   - Fast load times
   - Instant feedback
   - Offline-first architecture
   - Auto-save everything
   - No unnecessary confirmations

### Implementation Rules

✅ **DO:**
- Design for offline-first, sync later
- Use semantic HTML for web accessibility
- Test with screen readers
- Support keyboard shortcuts
- Provide clear error messages in user's language

❌ **DON'T:**
- Assume users have fast internet
- Block UI while loading
- Use images for text
- Require complex multi-step workflows
- Make assumptions about user knowledge

---

## 4. Authentication Architecture

### Supported Authentication Methods

Must support (now or future):

1. **Google Sign-In** (Priority 1)
2. **Apple Sign-In** (Priority 1)
3. **Email + Password** (Priority 2)
4. **Future providers** (must be easy to add)

### Architecture Requirements

#### Decoupling Principles

The authentication system **must**:

1. **Decouple provider implementations**
   - Each auth provider is a separate, swappable module
   - No direct dependencies on provider SDKs in business logic
   - Use abstract interfaces for all auth operations

2. **Use dependency injection**
   - Auth services injected via DI container
   - Easy to mock for testing
   - Easy to swap providers

3. **Separate UI from mechanics**
   - Auth UI is purely presentational
   - Business logic in separate service layer
   - No auth logic in widgets

#### File Structure

```
lib/
  services/
    auth/
      auth_service.dart              # Abstract interface
      auth_service_impl.dart         # Concrete implementation
      providers/
        google_auth_provider.dart
        apple_auth_provider.dart
        email_auth_provider.dart
  models/
    user.dart                        # User model
    auth_state.dart                  # Auth state model
  widgets/
    auth/
      sign_in_button.dart            # Reusable auth UI
      auth_screen.dart               # Auth screen
```

#### Testing Requirements

Every auth feature must have:

1. **Unit tests** for auth service logic
2. **Widget tests** for auth UI
3. **Integration tests** for auth flow
4. **E2E tests** for complete auth journey (minimal, only smoke tests)

#### Code Example

```dart
// ✅ GOOD: Abstract interface
abstract class AuthService {
  Future<User> signIn(AuthProvider provider);
  Future<void> signOut();
  Stream<AuthState> get authStateChanges;
}

// ✅ GOOD: Provider abstraction
abstract class AuthProvider {
  Future<AuthCredential> authenticate();
}

// ❌ BAD: Direct provider coupling
class AuthService {
  Future<User> signInWithGoogle() {
    // Direct GoogleSignIn SDK usage
  }
}
```

---

## 5. User Preferences System

### Overview

Each user must be able to configure preferences that:
- Persist across devices
- Sync automatically
- Update UI reactively
- Work offline-first with eventual sync

### Required Preferences

#### 1. Language

**Requirements:**
- All user-facing text must be fully localizable
- **Zero hardcoded strings** in UI code
- Support multiple languages (English, Spanish, French, etc.)
- Dynamic language switching without app restart
- Translation files for all supported languages

**Implementation Rules:**

✅ **DO:**
```dart
// Use localization
Text(AppLocalizations.of(context).welcomeMessage)

// Or with intl package
Text(Intl.message('Welcome', name: 'welcomeMessage'))
```

❌ **DON'T:**
```dart
// Never hardcode strings
Text('Welcome')
Text("Add Transaction")
```

**Testing:**
- Tests must catch any hardcoded strings
- Tests must validate all translation keys exist
- Tests must ensure no missing translations

#### 2. Currency

**Requirements:**
- Support all major world currencies
- Real-time or cached currency conversion
- Switch currencies at any time
- UI updates reactively when currency changes
- Clear separation between stored canonical values and displayed values

**Architecture:**

```
Stored Value (canonical) → Currency Service → Displayed Value (user preference)
        USD                                           EUR, JPY, GBP, etc.
```

**Implementation Rules:**

✅ **DO:**
```dart
// Store amounts in a canonical currency (e.g., USD cents)
class Transaction {
  final int amountInCents; // Always USD
  final String currency;   // User's display preference
}

// Convert for display
class CurrencyService {
  String formatAmount(int amountInCents, String targetCurrency);
  int convertAmount(int amountInCents, String fromCurrency, String toCurrency);
}
```

❌ **DON'T:**
```dart
// Don't store amounts in user's currency only
class Transaction {
  final double amount; // Which currency? How to convert?
}

// Don't hardcode currency symbols
Text('\$${amount}') // What if user prefers EUR?
```

**Testing:**
- Unit tests for currency conversion
- Widget tests for currency formatting
- Integration tests for preference changes

#### 3. Other Preferences

The preferences system must support:

- **Theme** (light/dark/system)
- **Date format** (MM/DD/YYYY vs DD/MM/YYYY vs ISO)
- **Number format** (commas vs periods for decimals)
- **Notification settings**
- **Privacy settings**
- **Any future preferences** (extensible system)

**Architecture Requirements:**

```dart
// ✅ GOOD: Extensible preferences system
abstract class PreferencesService {
  Future<T?> get<T>(String key);
  Future<void> set<T>(String key, T value);
  Stream<T?> watch<T>(String key);
}

// ✅ GOOD: Reactive preferences
class PreferencesProvider extends ChangeNotifier {
  Future<void> setLanguage(String languageCode) async {
    await _prefsService.set('language', languageCode);
    notifyListeners(); // UI updates automatically
  }
}
```

**Sync Requirements:**
- Preferences stored locally first (offline-first)
- Synced to backend when online
- Conflicts resolved (last-write-wins or user prompt)
- No data loss if sync fails

---

## 6. Architecture and Scaling Requirements

### Current Phase: Simple Architecture

**Goals:**
- Minimal deployment complexity
- Single instance frontend
- Single instance backend
- Simple persistence (local storage → Firestore → etc.)

**Allowed:**
- Monolithic Flutter app
- Simple Cloud Run backend
- Firestore or similar NoSQL database
- Minimal infrastructure

### Future Phase: Scalable Architecture

**Goals:**
- Horizontal scaling of frontend and backend
- Millions of users
- High availability
- Multi-region support
- Easy migration of persistence layer

**Requirements:**

1. **Stateless Backend**
   - No session state on backend
   - All state in database or client
   - Easy to scale horizontally

2. **Persistence Abstraction**
   - Easy to swap Firestore → PostgreSQL → Distributed DB
   - Repository pattern for data access
   - No direct database calls in business logic

3. **Frontend/Backend Decoupling**
   - Clean API contracts
   - No tight coupling
   - Easy to scale independently

4. **Dependency Injection**
   - All services injected
   - Easy to swap implementations
   - Easy to test with mocks

### The Golden Rule

> **Choose the simplest solution now, but never block future scalability.**

**Examples:**

✅ **GOOD:**
- Use Firestore now, but abstract behind `TransactionRepository`
- Use single Cloud Run instance, but make backend stateless
- Use simple auth now, but design auth service for multiple providers

❌ **BAD:**
- Hardcode Firestore calls throughout codebase
- Store session state in backend memory
- Couple UI directly to specific auth SDK

### Architecture Boundaries

```
┌─────────────────────────────────────────────────┐
│                 UI Layer                        │
│  (Widgets, Screens, Presentational Components) │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│              Business Logic                     │
│  (Services, Providers, State Management)        │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│              Data Layer                         │
│  (Repositories, API Clients, Local Storage)     │
└─────────────────────────────────────────────────┘
```

**Each layer must:**
- Be independently testable
- Not skip layers (UI can't call Repository directly)
- Use interfaces for dependencies
- Be replaceable without affecting other layers

---

## 7. Testing Philosophy

### Testing Pyramid

```
         ╱ ╲
        ╱ E2E╲         ← Minimal, only critical flows
       ╱───────╲
      ╱         ╲
     ╱Integration╲     ← Moderate, test layer boundaries
    ╱─────────────╲
   ╱               ╲
  ╱  Widget Tests   ╲  ← Heavy use, most important for Flutter
 ╱───────────────────╲
╱                     ╲
──────Unit Tests────── ← Heaviest use, fastest feedback
```

### Test Type Priorities

#### 1. Unit Tests (MAXIMIZE)

**Use for:**
- Business logic
- Services
- Utilities
- Models
- Converters
- Validators

**Characteristics:**
- **Fastest** execution
- **Highest** coverage
- **Most** reliable
- **Easiest** to maintain
- **Zero** external dependencies

**Example:**
```dart
test('CurrencyService converts USD to EUR correctly', () {
  final service = CurrencyService(exchangeRates: mockRates);
  final result = service.convert(100, 'USD', 'EUR');
  expect(result, equals(85));
});
```

#### 2. Widget Tests (MAXIMIZE)

**Use for:**
- UI components
- User interactions
- Layout behavior
- Accessibility
- Navigation

**Characteristics:**
- **Fast** execution
- **Essential** for Flutter apps
- **Best** ROI for UI testing
- **No** need for real devices

**Example:**
```dart
testWidgets('AddTransactionButton shows dialog when tapped', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.tap(find.byType(AddTransactionButton));
  await tester.pumpAndSettle();
  expect(find.byType(TransactionDialog), findsOneWidget);
});
```

#### 3. Integration Tests (MODERATE)

**Use for:**
- Multiple components working together
- Service integration
- Data flow between layers
- API contract validation

**Characteristics:**
- **Slower** than unit/widget tests
- **Higher** confidence
- **More** realistic scenarios

**Example:**
```dart
test('TransactionService saves transaction and updates repository', () async {
  final service = TransactionService(repository: mockRepo);
  await service.addTransaction(transaction);
  verify(mockRepo.save(transaction)).called(1);
  expect(service.transactions, contains(transaction));
});
```

#### 4. E2E Tests (MINIMIZE BUT KEEP ESSENTIAL)

**Use ONLY for:**
- Authentication flows (sign in, sign out)
- Backend connectivity smoke tests
- Persistence flow validation
- Pre-deployment sanity checks
- Critical user journeys

**DO NOT use for:**
- Coverage
- Feature testing (use widget/integration tests)
- Regression testing (use unit/widget tests)

**Characteristics:**
- **Slowest** execution
- **Most** brittle
- **Expensive** to maintain
- **Essential** for confidence

**Example scenarios:**
```
E2E Test: Complete Auth Flow
1. User opens app
2. User clicks "Sign in with Google"
3. User completes Google auth
4. User sees dashboard
5. User signs out
```

### Testing Goals

1. **Fast, reliable iterative testing**
   - Unit tests run in < 10 seconds
   - Widget tests run in < 30 seconds
   - Full test suite runs in < 5 minutes

2. **High coverage through unit + widget tests**
   - Target: 80%+ code coverage from unit tests
   - Target: 90%+ widget coverage from widget tests

3. **Zero brittle or expensive tests**
   - No flaky tests
   - No slow tests in CI
   - No tests that break on cosmetic changes

4. **E2E is for sanity, not coverage**
   - < 10 E2E tests total
   - Each E2E test must be essential
   - E2E tests run before deployment only

5. **Maintainable test suite for long-term velocity**
   - Tests are easy to read and understand
   - Tests are easy to update when code changes
   - Tests provide clear failure messages

### Test Quality Standards

✅ **GOOD Tests:**
- Fast (< 100ms for unit, < 1s for widget)
- Isolated (no shared state between tests)
- Deterministic (same result every time)
- Clear (obvious what's being tested)
- Focused (one concept per test)

❌ **BAD Tests:**
- Slow (> 1s for unit, > 10s for widget)
- Flaky (fails randomly)
- Unclear (what does this test?)
- Coupled (depends on other tests)
- Overly complex (testing too much at once)

---

## 8. Test-Driven Development (TDD/ATDD)

### Mandatory TDD Process

All code contributions **must** follow Test-Driven Development:

#### The TDD Cycle (Red-Green-Refactor)

```
1. RED:    Write a failing test
     ↓
2. GREEN:  Write minimal code to pass
     ↓
3. REFACTOR: Improve code quality
     ↓
   Repeat
```

#### Step-by-Step Process

1. **Write the test first**
   - Before any implementation code
   - Test describes desired behavior
   - Test fails (red)

2. **Write minimal code to pass**
   - Only enough to make test pass
   - Don't over-engineer
   - Test passes (green)

3. **Refactor**
   - Improve code quality
   - Remove duplication
   - Improve names
   - All tests still pass

4. **Repeat**
   - Next test
   - Next feature

### Acceptance Test-Driven Development (ATDD)

Before implementing any new feature:

1. **Define acceptance criteria**
   - What does "done" look like?
   - What are the edge cases?
   - What are the success/failure scenarios?

2. **Write acceptance tests**
   - High-level tests that validate acceptance criteria
   - May be integration or E2E tests
   - Must be automated

3. **Implement with TDD**
   - Use TDD cycle for implementation
   - Acceptance tests guide development
   - Done when acceptance tests pass

### Example: Adding Currency Conversion Feature

#### 1. Define Acceptance Criteria

```
Feature: Currency Conversion
  As a user
  I want to see transactions in my preferred currency
  So that I can understand my finances in familiar terms

Acceptance Criteria:
  ✓ User can select preferred currency
  ✓ All transaction amounts display in selected currency
  ✓ Currency conversion uses current exchange rates
  ✓ UI updates immediately when currency changes
```

#### 2. Write Acceptance Test

```dart
testWidgets('User can change currency and see updated amounts', (tester) async {
  await tester.pumpWidget(MyApp());

  // Add transaction in USD
  await addTransaction(tester, amount: 100, currency: 'USD');
  expect(find.text('\$100.00'), findsOneWidget);

  // Change to EUR
  await openSettings(tester);
  await selectCurrency(tester, 'EUR');
  await tester.pumpAndSettle();

  // Verify conversion
  expect(find.text('€85.00'), findsOneWidget);
});
```

#### 3. Implement with TDD

```dart
// Test 1: Currency service converts amounts
test('convert returns correct EUR amount for USD input', () {
  final service = CurrencyService(rates: {'EUR': 0.85});
  expect(service.convert(100, 'USD', 'EUR'), equals(85));
});

// Implement minimal code...

// Test 2: Currency service throws on invalid currency
test('convert throws on unknown currency', () {
  final service = CurrencyService(rates: {});
  expect(() => service.convert(100, 'USD', 'XXX'), throwsException);
});

// Implement...

// Continue TDD cycle...
```

### Rules for TDD

✅ **DO:**
- Write test first, always
- Write smallest possible test
- See test fail before making it pass
- Commit test and implementation together
- Use TDD for all new code
- Use TDD when fixing bugs (write test that reproduces bug first)

❌ **DON'T:**
- Write implementation without test
- Write test after implementation
- Skip TDD "because it's faster" (it's not)
- Write tests that don't fail first
- Write overly complex tests

### TDD Benefits

- **Better design:** Forces you to think about API before implementation
- **Higher confidence:** Tests prove code works
- **Living documentation:** Tests show how code should be used
- **Faster debugging:** Tests catch bugs immediately
- **Refactoring safety:** Tests allow confident refactoring

---

## 9. Coding Standards for Maintainability

### File Size and Complexity

✅ **DO:**
- Keep files under 300 lines
- Keep classes under 200 lines
- Keep methods under 50 lines
- Split large files into smaller modules

❌ **DON'T:**
- Create 1000+ line files
- Create god classes
- Create methods with 100+ lines

### Naming Conventions

✅ **DO:**
```dart
// Classes: PascalCase
class TransactionService {}

// Variables: camelCase
final userName = 'John';

// Constants: lowerCamelCase
const maxRetries = 3;

// Private: _leadingUnderscore
final _privateField = 'secret';

// Descriptive names
class UserAuthenticationService {} // Clear
final isAuthenticated = true;      // Clear
```

❌ **DON'T:**
```dart
// Abbreviations
class TxnSvc {}          // What is this?
final usr = 'John';      // Unclear

// Single letters (except loops)
final a = true;          // What does 'a' mean?

// Hungarian notation
final strName = 'John';  // Not Dart style
```

### Architecture Boundaries

✅ **DO:**
- Clear separation between layers (UI, Business Logic, Data)
- Use dependency injection everywhere
- Depend on abstractions, not concrete classes
- Keep modules loosely coupled

❌ **DON'T:**
- Mix UI and business logic
- Create circular dependencies
- Use global mutable state
- Create tight coupling between modules

### Type Safety

✅ **DO:**
```dart
// Strong typing
String getName() => 'John';
List<Transaction> getTransactions() => [];

// Use named parameters for clarity
void addTransaction({
  required String description,
  required int amount,
  required DateTime date,
}) {}

// Use enums for fixed sets
enum TransactionType { income, expense }
```

❌ **DON'T:**
```dart
// Dynamic/Object unless necessary
dynamic getData() => '???';

// Positional parameters (unless obvious)
void add(String a, int b, DateTime c) {} // Hard to understand

// String constants instead of enums
const type = 'income'; // Error-prone
```

### Dependency Injection

✅ **DO:**
```dart
// Constructor injection
class TransactionService {
  TransactionService(this._repository);
  final TransactionRepository _repository;
}

// Interface-based dependencies
abstract class TransactionRepository {
  Future<void> save(Transaction t);
}

// Testable with mocks
final service = TransactionService(MockRepository());
```

❌ **DON'T:**
```dart
// Service locator anti-pattern
class TransactionService {
  final _repository = GetIt.I<TransactionRepository>(); // Hard to test
}

// Direct instantiation
class TransactionService {
  final _repository = FirestoreRepository(); // Coupled
}
```

### State Management

✅ **DO:**
- Use immutable data models
- Use ChangeNotifier/Provider for simple state
- Use Riverpod/Bloc for complex state
- Avoid global mutable state

❌ **DON'T:**
- Use global variables for state
- Mutate objects directly
- Create state management spaghetti

### Error Handling

✅ **DO:**
```dart
// Use exceptions for exceptional cases
if (amount < 0) {
  throw ArgumentError('Amount must be positive');
}

// Use Result types for expected failures
sealed class Result<T> {
  const Result();
}
class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}
class Failure<T> extends Result<T> {
  const Failure(this.error);
  final Exception error;
}

// Handle errors gracefully in UI
try {
  await service.save(transaction);
} on NetworkException {
  showSnackBar('Network error, will retry');
} catch (e) {
  showSnackBar('Unexpected error');
  logError(e);
}
```

❌ **DON'T:**
```dart
// Catch and ignore
try {
  await something();
} catch (e) {
  // Silent failure - BAD!
}

// Return null for errors
Transaction? loadTransaction() {
  try {
    return repository.load();
  } catch (e) {
    return null; // Lost error information
  }
}
```

### Documentation

✅ **DO:**
```dart
/// Loads a transaction by [id] from the repository.
///
/// Throws [NotFoundException] if transaction doesn't exist.
/// Throws [NetworkException] if network unavailable.
Future<Transaction> loadTransaction(String id) async {
  // Implementation
}

// Document complex logic
// Convert amount to cents to avoid floating point errors
final amountInCents = (amount * 100).round();
```

❌ **DON'T:**
```dart
// Obvious comments
// Set name
name = 'John';

// Outdated comments
// TODO: Fix this later (from 2020)

// No documentation for public APIs
Future<Transaction> load(String id) async {
  // What does this do? What can go wrong?
}
```

### Avoid Premature Abstraction

✅ **DO:**
- Start simple
- Abstract when you have 2-3 concrete cases
- Prefer duplication over wrong abstraction

❌ **DON'T:**
- Create abstractions "just in case"
- Over-engineer simple features
- Create complex inheritance hierarchies

### Code Quality Checklist

Before submitting code, verify:

- [ ] All tests pass
- [ ] New code has tests
- [ ] Test coverage > 80%
- [ ] No hardcoded strings (all localized)
- [ ] No magic numbers (use named constants)
- [ ] No duplicate code
- [ ] Clear, descriptive names
- [ ] Proper error handling
- [ ] Documentation for public APIs
- [ ] No lint warnings
- [ ] Formatted with `dart format`

---

## 10. CI/CD and Deployment

### Continuous Integration (CI)

#### CI Pipeline Requirements

CI **must**:

1. **Run on every commit** to any branch
2. **Run on every pull request**
3. **Block merge if tests fail**
4. **Be fast** (< 10 minutes total)

#### CI Pipeline Stages

```
┌──────────────────────────────────────┐
│  1. Code Quality Checks              │
│     - dart analyze                   │
│     - dart format --check            │
│     - Check for TODO/FIXME           │
└──────────┬───────────────────────────┘
           │
┌──────────▼───────────────────────────┐
│  2. Unit Tests                       │
│     - Run all unit tests             │
│     - Generate coverage report       │
│     - Fail if coverage < 80%         │
└──────────┬───────────────────────────┘
           │
┌──────────▼───────────────────────────┐
│  3. Widget Tests                     │
│     - Run all widget tests           │
│     - Test on multiple screen sizes  │
└──────────┬───────────────────────────┘
           │
┌──────────▼───────────────────────────┐
│  4. Integration Tests                │
│     - Run integration test suite     │
└──────────┬───────────────────────────┘
           │
┌──────────▼───────────────────────────┐
│  5. Build Verification               │
│     - Build web                      │
│     - Build Android APK              │
│     - Build iOS (if on macOS)        │
└──────────────────────────────────────┘
```

### Continuous Deployment (CD)

#### Pre-Deployment Requirements

Before deploying to production:

1. **All CI stages pass**
2. **Run minimal E2E test suite** (< 10 tests)
3. **Manual approval** (if required)
4. **Deployment smoke test** passes

#### Deployment Targets

- **Backend:** GCP Cloud Run
- **Frontend Web:** GCP Storage + Cloud CDN
- **Mobile Apps:** App Store / Play Store

#### Deployment Process

```bash
# 1. Run pre-deployment checks
./scripts/pre-deploy-check.sh

# 2. Run E2E smoke tests
flutter test test/e2e/

# 3. Deploy backend
./scripts/deploy-backend.sh

# 4. Deploy frontend
./scripts/deploy-frontend.sh

# 5. Run post-deployment smoke tests
./scripts/smoke-test.sh
```

#### Post-Deployment Verification

After deployment:

1. **Smoke test critical flows**
   - User can sign in
   - User can view dashboard
   - User can add transaction
   - User can sign out

2. **Monitor for errors**
   - Check error logs
   - Check performance metrics
   - Verify no alerts fired

3. **Rollback if necessary**
   - Use `./scripts/rollback.sh` if issues detected

### Cloud Portability

Code **must**:

- Work in cloud environments (no local file paths)
- Use environment variables for configuration
- Not depend on specific machine state
- Be containerizable (Docker)
- Support multiple environments (dev, staging, prod)

### Environment Configuration

✅ **DO:**
```dart
// Use environment variables
final apiUrl = const String.fromEnvironment('API_URL',
  defaultValue: 'https://api.example.com'
);

// Use config files
final config = await loadConfig('config/${environment}.json');
```

❌ **DON'T:**
```dart
// Hardcode URLs
final apiUrl = 'http://localhost:3000';

// Use absolute paths
final dataPath = '/Users/me/data';
```

---

## 11. Repository Hygiene

### .gitignore Maintenance

#### What to Ignore

The `.gitignore` **must** exclude:

1. **Build Outputs**
   - `build/`
   - `.dart_tool/`
   - `.flutter-plugins`
   - `.flutter-plugins-dependencies`
   - `*.apk`, `*.ipa`, `*.aab`

2. **IDE Files**
   - `.vscode/`
   - `.idea/`
   - `*.swp`, `*.swo`
   - `.DS_Store`

3. **Credentials**
   - `gcp-key.json`
   - `.env`
   - `.gcp_settings` (with real values)
   - Any files containing secrets

4. **Test Outputs**
   - `coverage/`
   - `test/.test_coverage.dart`
   - `test_driver/`
   - `playwright-report/`

5. **Temp Files**
   - `*.log`
   - `*.tmp`
   - `tmp/`
   - `temp/`

6. **Generated Files**
   - `*.g.dart` (if not needed in repo)
   - `*.freezed.dart`

#### Updating .gitignore

When you:
- Add new tools → Update `.gitignore`
- Add new build outputs → Update `.gitignore`
- Change file structure → Update `.gitignore`

**Rule:** If a file is generated or temporary, it should be in `.gitignore`.

### Cleanup Scripts

#### Cleanup Script Requirements

The repository **must** have a cleanup script at `scripts/cleanup.sh` that:

1. **Removes build artifacts**
   ```bash
   rm -rf build/
   rm -rf .dart_tool/
   flutter clean
   ```

2. **Removes test artifacts**
   ```bash
   rm -rf coverage/
   rm -rf test/e2e_web/playwright-report/
   ```

3. **Removes temp files**
   ```bash
   rm -f *.log
   rm -rf tmp/
   ```

4. **Is safe to run** (doesn't delete source code or important files)

#### When to Update Cleanup Script

Update `scripts/cleanup.sh` when:
- New build tools are added
- New test frameworks are added
- New temp directories are created
- File structure changes

#### Running Cleanup

Developers should run cleanup:
- Before committing
- After switching branches
- When disk space is low
- When build artifacts are corrupted

```bash
./scripts/cleanup.sh
```

### Documentation Updates

#### When Code Changes, Update Docs

**Rule:** Documentation must stay in sync with code.

When you make changes, update:

1. **README.md**
   - New features
   - Changed setup instructions
   - Updated dependencies
   - Changed architecture

2. **Architecture Docs**
   - New services
   - Changed data flow
   - New dependencies
   - Changed deployment process

3. **API Documentation**
   - New endpoints
   - Changed contracts
   - Deprecated APIs

4. **This File (claude.md)**
   - New coding rules
   - Changed testing approach
   - New architectural decisions
   - Changed contribution guidelines

#### Documentation Standards

Documentation must:
- Be up-to-date (no outdated information)
- Be clear and concise
- Include examples
- Be formatted consistently
- Be spell-checked

### Git Commit Standards

#### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(auth): add Google Sign-In support

Implemented Google Sign-In authentication provider with
proper error handling and token management.

Closes #123
```

```
fix(currency): handle invalid exchange rates gracefully

Previously, invalid rates caused app to crash. Now we
show user-friendly error and use cached rates.

Fixes #456
```

#### Commit Best Practices

✅ **DO:**
- Write clear, descriptive commit messages
- Keep commits focused (one logical change per commit)
- Reference issue numbers
- Include tests in the same commit as code

❌ **DON'T:**
- Write vague messages ("fix stuff", "update")
- Create giant commits with many unrelated changes
- Commit broken code
- Commit without tests

---

## 12. Project Structure and Style

### Directory Structure

```
artist_finance_manager/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/                      # Data models
│   │   ├── transaction.dart
│   │   ├── user.dart
│   │   └── preferences.dart
│   ├── services/                    # Business logic
│   │   ├── auth/
│   │   │   ├── auth_service.dart
│   │   │   └── providers/
│   │   ├── transaction_service.dart
│   │   ├── currency_service.dart
│   │   └── preferences_service.dart
│   ├── providers/                   # State management
│   │   ├── auth_provider.dart
│   │   └── transaction_provider.dart
│   ├── repositories/                # Data access layer
│   │   ├── transaction_repository.dart
│   │   └── user_repository.dart
│   ├── screens/                     # Full screen views
│   │   ├── home_screen.dart
│   │   ├── auth_screen.dart
│   │   └── settings_screen.dart
│   ├── widgets/                     # Reusable UI components
│   │   ├── transaction_list.dart
│   │   └── transaction_card.dart
│   └── utils/                       # Utilities
│       ├── formatters.dart
│       └── validators.dart
├── test/
│   ├── models/                      # Model tests
│   ├── services/                    # Service tests
│   ├── widgets/                     # Widget tests
│   ├── integration/                 # Integration tests
│   └── e2e/                         # E2E tests (minimal)
├── scripts/                         # Build/deploy scripts
│   ├── deploy.sh
│   ├── cleanup.sh
│   └── setup-gcp.sh
├── docs/                            # Additional documentation
├── .github/                         # GitHub Actions workflows
└── pubspec.yaml                     # Dependencies
```

### Layer Responsibilities

#### 1. Models (`lib/models/`)

**Purpose:** Pure data classes, no logic

```dart
class Transaction {
  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
  });

  final String id;
  final String description;
  final int amount;
  final DateTime date;
}
```

#### 2. Services (`lib/services/`)

**Purpose:** Business logic, no UI

```dart
class TransactionService {
  TransactionService(this._repository);
  final TransactionRepository _repository;

  Future<void> addTransaction(Transaction transaction) async {
    // Validation
    if (transaction.amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }
    // Save
    await _repository.save(transaction);
  }
}
```

#### 3. Repositories (`lib/repositories/`)

**Purpose:** Data access, abstract persistence

```dart
abstract class TransactionRepository {
  Future<void> save(Transaction transaction);
  Future<Transaction?> findById(String id);
  Future<List<Transaction>> findAll();
}

class FirestoreTransactionRepository implements TransactionRepository {
  // Firestore-specific implementation
}
```

#### 4. Providers (`lib/providers/`)

**Purpose:** State management, connect services to UI

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
}
```

#### 5. Screens (`lib/screens/`)

**Purpose:** Full-screen views, orchestrate widgets

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transactions')),
      body: TransactionList(),
      floatingActionButton: AddTransactionButton(),
    );
  }
}
```

#### 6. Widgets (`lib/widgets/`)

**Purpose:** Reusable UI components

```dart
class TransactionCard extends StatelessWidget {
  const TransactionCard({required this.transaction});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(transaction.description),
        trailing: Text('\$${transaction.amount}'),
      ),
    );
  }
}
```

### Dependency Rules

1. **UI depends on Business Logic**
   - Screens/Widgets → Providers/Services ✓
   - Providers/Services → Screens/Widgets ✗

2. **Business Logic depends on Data**
   - Services → Repositories ✓
   - Repositories → Services ✗

3. **Always use abstractions**
   - Services → Repository interface ✓
   - Services → Concrete repository ✗

### Configuration Management

#### Use Layers for Configuration

```dart
// 1. Environment variables (deployment)
const apiUrl = String.fromEnvironment('API_URL');

// 2. Config files (per environment)
final config = await loadConfig('config/prod.json');

// 3. Remote config (runtime)
final remoteConfig = await RemoteConfig.instance.fetch();
```

#### Never Hardcode

❌ **DON'T:**
```dart
final apiUrl = 'https://api.example.com';
final apiKey = 'secret-key-123';
```

✅ **DO:**
```dart
final apiUrl = Config.instance.apiUrl;
final apiKey = await SecureStorage.read('api_key');
```

---

## 13. Explicit Instructions for Claude Code

### Mandatory Rules for All Contributions

As an LLM contributor to this project, you **must**:

#### 1. Follow This File Strictly

- Treat this document as law, not suggestion
- Do not deviate from these guidelines without explicit user approval
- If guidelines conflict with user request, raise the issue immediately
- Update this file when guidelines change

#### 2. Always Write Tests First (TDD)

- Write test before implementation, every time
- Never commit code without tests
- Use TDD cycle: Red → Green → Refactor
- Write acceptance tests before starting features

#### 3. Enforce Modularity and Testability

- Keep files small (< 300 lines)
- Use dependency injection everywhere
- Depend on abstractions, not concrete classes
- Make everything easy to mock and test

#### 4. Never Break CI

- Run tests locally before committing
- Ensure all tests pass
- Fix test failures immediately
- Never commit code that doesn't pass tests

#### 5. Prefer Clarity Over Cleverness

- Write simple, obvious code
- Avoid premature optimization
- Avoid premature abstraction
- Make code easy for future LLMs to understand and modify

#### 6. Update Documentation Automatically

When you change code, automatically update:
- README.md (if user-facing changes)
- Architecture docs (if structure changes)
- API docs (if contracts change)
- This file (if contribution rules change)

#### 7. Maintain Repository Hygiene

- Update `.gitignore` when adding new tools/outputs
- Update `scripts/cleanup.sh` when file structure changes
- Never commit credentials or secrets
- Keep working directory clean

#### 8. Enforce Localization

- Never hardcode user-facing strings
- Always use localization keys
- Verify translation keys exist for all strings
- Test with multiple languages

#### 9. Enforce Type Safety

- Use strong typing everywhere
- Avoid `dynamic` and `Object` unless necessary
- Use named parameters for clarity
- Use enums for fixed sets of values

#### 10. Enforce Error Handling

- Handle all errors gracefully
- Never silently catch and ignore errors
- Provide user-friendly error messages
- Log errors for debugging

### Code Review Checklist

Before submitting any code, verify:

- [ ] **Tests written first** (TDD followed)
- [ ] **All tests pass** (unit, widget, integration)
- [ ] **Test coverage > 80%**
- [ ] **No hardcoded strings** (all localized)
- [ ] **No magic numbers** (use named constants)
- [ ] **Dependency injection used** (no direct instantiation)
- [ ] **Types are strong** (no dynamic/Object)
- [ ] **Error handling present** (no silent failures)
- [ ] **Documentation updated** (README, docs, this file)
- [ ] **No lint warnings** (dart analyze clean)
- [ ] **Code formatted** (dart format)
- [ ] **.gitignore updated** (if needed)
- [ ] **Cleanup script updated** (if needed)
- [ ] **No credentials committed**
- [ ] **Cross-platform tested** (web, iOS, Android)
- [ ] **Accessibility considered** (screen readers, keyboard)

### When Uncertain

If you're uncertain about anything:

1. **Ask the user** for clarification
2. **Refer to this document** for guidance
3. **Look at existing code** for patterns
4. **Prefer simpler solution** over complex one
5. **Write test first** to clarify requirements

### Continuous Improvement

This document will evolve. When you notice:

- Missing guidelines
- Conflicting guidelines
- Outdated guidelines
- Unclear guidelines

**Suggest updates** to keep this document useful and accurate.

---

## Appendix: Quick Reference

### Common Commands

```bash
# Run tests
flutter test                          # All tests
flutter test test/models/             # Specific directory
flutter test --coverage               # With coverage

# Format code
dart format lib/ test/

# Analyze code
dart analyze

# Clean build artifacts
flutter clean
./scripts/cleanup.sh

# Deploy
./scripts/deploy.sh

# Run E2E tests
flutter test test/e2e/
```

### Common Patterns

#### Creating a New Service

1. Define interface in `lib/services/`
2. Write tests in `test/services/`
3. Implement service using TDD
4. Add to DI container
5. Document in architecture docs

#### Adding a New Feature

1. Write acceptance criteria
2. Write acceptance tests
3. Implement with TDD
4. Write integration tests
5. Update documentation
6. Test on all platforms

#### Fixing a Bug

1. Write test that reproduces bug
2. Fix bug using TDD
3. Ensure all tests pass
4. Document fix in commit message

---

## Conclusion

This document defines the standards and practices for contributing to Artist Finance Manager. All LLM contributors must follow these guidelines to maintain code quality, architectural integrity, and long-term maintainability.

**Remember:** These are not suggestions—they are requirements. Following these guidelines ensures the project remains scalable, testable, and maintainable as it grows.

**Questions?** Refer to this document first. If still unclear, ask the user.

**Changes?** Update this document when guidelines evolve.

**Version History:**
- 1.0.0 (2025-11-28): Initial version

---

*End of claude.md*
