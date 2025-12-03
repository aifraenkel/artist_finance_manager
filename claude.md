# Claude.md - Contributor Guide for LLM Contributors

**Version:** 1.1.0
**Last Updated:** 2025-11-28
**Project:** Art Finance Hub

---

## About This Document

This document serves as the **authoritative guide** for all LLM contributors (including Claude Code and future AI assistants) working on the Art Finance Hub project. Every contribution must follow these guidelines strictly to maintain code quality, architectural integrity, and long-term maintainability.

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

### What is Art Finance Hub?

**Art Finance Hub** is a multi-device, global application designed for artists to track and manage their finances across projects.

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

### Architecture Principles

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

### Code Pattern

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
    // Direct GoogleSignIn SDK usage - too coupled
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
- Support multiple languages
- Dynamic language switching without app restart

**Implementation:**

✅ **DO:**
```dart
Text(AppLocalizations.of(context).welcomeMessage)
```

❌ **DON'T:**
```dart
Text('Welcome') // Never hardcode strings
```

#### 2. Currency

**Requirements:**
- Support all major world currencies
- Real-time or cached currency conversion
- Switch currencies at any time
- Clear separation between stored canonical values and displayed values

**Architecture Pattern:**
```
Stored Value (USD cents) → Currency Service → Displayed Value (user currency)
```

**Implementation:**

✅ **DO:**
```dart
// Store in canonical currency
class Transaction {
  final int amountInCents; // Always USD cents
  final String currency;   // User's display preference
}

class CurrencyService {
  String formatAmount(int amountInCents, String targetCurrency);
  int convertAmount(int amountInCents, String from, String to);
}
```

❌ **DON'T:**
```dart
class Transaction {
  final double amount; // Which currency? How to convert?
}
Text('\$${amount}') // What if user prefers EUR?
```

#### 3. Other Preferences

Support extensible preferences: theme, date format, number format, notifications, privacy settings, and any future additions.

**Implementation Pattern:**

```dart
abstract class PreferencesService {
  Future<T?> get<T>(String key);
  Future<void> set<T>(String key, T value);
  Stream<T?> watch<T>(String key);
}
```

**Sync Requirements:**
- Store locally first (offline-first)
- Sync to backend when online
- Resolve conflicts (last-write-wins or user prompt)
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
UI Layer (Widgets, Screens)
         ↓
Business Logic (Services, Providers)
         ↓
Data Layer (Repositories, API Clients)
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

**Use for:** Business logic, services, utilities, models, converters, validators

**Characteristics:**
- **Fastest** execution (< 100ms per test)
- **Highest** coverage target (80%+)
- **Most** reliable
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

**Use for:** UI components, user interactions, layout behavior, accessibility, navigation

**Characteristics:**
- **Fast** execution (< 1s per test)
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

**Use for:** Multiple components working together, service integration, data flow between layers, API contract validation

**Characteristics:**
- **Slower** than unit/widget tests
- **Higher** confidence
- **More** realistic scenarios

#### 4. E2E Tests (MINIMIZE BUT KEEP ESSENTIAL)

**Use ONLY for:**
- Authentication flows (sign in, sign out)
- Backend connectivity smoke tests
- Persistence flow validation
- Pre-deployment sanity checks
- Critical user journeys (normal flow only)

**DO NOT use for:**
- Coverage
- Feature testing (use widget/integration tests)
- Regression testing (use unit/widget tests)

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
  await addTransaction(tester, amount: 100, currency: 'USD');
  expect(find.text('\$100.00'), findsOneWidget);

  await openSettings(tester);
  await selectCurrency(tester, 'EUR');
  await tester.pumpAndSettle();

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

---

## 9. Coding Standards for Maintainability

### Core Principles

- **Keep files small** (< 300 lines)
- **Keep classes focused** (< 200 lines)
- **Keep methods short** (< 50 lines)
- **Use descriptive names** (no abbreviations)
- **Depend on abstractions**, not concrete classes
- **Use dependency injection everywhere**
- **Avoid global mutable state**
- **Prefer simplicity over cleverness**

### Architecture Boundaries

✅ **DO:**
- Clear separation between layers (UI, Business Logic, Data)
- Use SOLID principles
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

// Named parameters for clarity
void addTransaction({
  required String description,
  required int amount,
  required DateTime date,
}) {}

// Enums for fixed sets
enum TransactionType { income, expense }
```

❌ **DON'T:**
```dart
// Avoid dynamic/Object unless necessary
dynamic getData() => '???';

// Avoid positional parameters (unless obvious)
void add(String a, int b, DateTime c) {}

// Don't use strings instead of enums
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
// Never catch and ignore
try {
  await something();
} catch (e) {
  // Silent failure - BAD!
}

// Don't return null for errors (loses error info)
Transaction? loadTransaction() {
  try {
    return repository.load();
  } catch (e) {
    return null;
  }
}
```

### Documentation

Document public APIs and complex logic. Avoid obvious comments.

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
- [ ] Documentation is updated
- [ ] No lint warnings
- [ ] Formatted with `dart format`

---

## 10. CI/CD and Deployment

### Continuous Integration (CI)

CI **must**:
1. Run on every commit to any branch
2. Run on every pull request
3. Block merge if tests fail
4. Be fast (< 10 minutes total)

### CI Pipeline Stages

1. **Code Quality Checks** - `dart analyze`, `dart format --check`
2. **Unit Tests** - Run all unit tests, generate coverage, fail if < 80%
3. **Widget Tests** - Run all widget tests
4. **Integration Tests** - Run integration test suite
5. **Build Verification** - Build web, Android APK, iOS (if on macOS)

### Continuous Deployment (CD)

#### Pre-Deployment Requirements

1. All CI stages pass
2. Run minimal E2E test suite (< 10 tests)
3. Manual approval (if required)
4. Deployment smoke test passes

#### Deployment Targets

- **Backend:** GCP Cloud Run
- **Frontend Web:** GCP Storage + Cloud CDN
- **Mobile Apps:** App Store / Play Store

#### Deployment Process

Use the deployment scripts in `scripts/`:
- `./scripts/deploy.sh` - Main deployment script
- `./scripts/rollback.sh` - Rollback if issues detected

#### Post-Deployment Verification

Smoke test critical flows:
- User can sign in
- User can view dashboard
- User can add transaction
- User can sign out

Monitor for errors and rollback if necessary.

### Cloud Portability

Code **must**:
- Work in cloud environments (no local file paths)
- Use environment variables for configuration
- Not depend on specific machine state
- Be containerizable (Docker)
- Support multiple environments (dev, staging, prod)

**Example:**
```dart
// ✅ GOOD: Use environment variables
final apiUrl = const String.fromEnvironment('API_URL',
  defaultValue: 'https://api.example.com'
);

// ❌ BAD: Hardcode URLs
final apiUrl = 'http://localhost:3000';
```

---

## 11. Repository Hygiene

### .gitignore Maintenance

The `.gitignore` **must** exclude:
- **Build outputs:** `build/`, `.dart_tool/`, `*.apk`, `*.ipa`, `*.aab`
- **IDE files:** `.vscode/`, `.idea/`, `*.swp`, `.DS_Store`
- **Credentials:** `gcp-key.json`, `.env`, `.gcp_settings` (with real values)
- **Test outputs:** `coverage/`, `test/.test_coverage.dart`, `playwright-report/`
- **Temp files:** `*.log`, `*.tmp`, `tmp/`, `temp/`
- **Generated files:** `*.g.dart`, `*.freezed.dart` (if not needed in repo)

**Rule:** If a file is generated or temporary, it should be in `.gitignore`.

Update `.gitignore` when you add new tools, build outputs, or change file structure.

### Cleanup Scripts

The repository has a cleanup script at `scripts/cleanup.sh` that removes build artifacts, test artifacts, and temp files.

Run cleanup:
- Before committing
- After switching branches
- When disk space is low
- When build artifacts are corrupted

```bash
./scripts/cleanup.sh
```

Update the cleanup script when file structure changes or new build tools are added.

### Documentation Updates

**Rule:** Documentation must stay in sync with code.

When you make changes, update:

1. **README.md** - New features, setup instructions, dependencies, architecture
2. **Architecture Docs** - New services, data flow, dependencies, deployment
3. **This File (claude.md)** - New rules, testing approach, architectural decisions

**Important:** Every time you review claude.md, critically evaluate if it can be simplified, if something is no longer relevant, or if content can be removed. Keep this file valuable and concise.

### Git Commit Standards

Use conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

**Example:**
```
feat(auth): add Google Sign-In support

Implemented Google Sign-In authentication provider with
proper error handling and token management.

Closes #123
```

**Best Practices:**
- Write clear, descriptive commit messages
- Keep commits focused (one logical change per commit)
- Reference issue numbers
- Include tests in the same commit as code

---

## 12. Project Structure and Style

### Directory Structure

```
artist_finance_manager/
├── lib/
│   ├── main.dart               # App entry point
│   ├── models/                 # Data models
│   ├── services/               # Business logic
│   │   ├── auth/
│   │   ├── transaction_service.dart
│   │   ├── currency_service.dart
│   │   └── preferences_service.dart
│   ├── providers/              # State management
│   ├── repositories/           # Data access layer
│   ├── screens/                # Full screen views
│   ├── widgets/                # Reusable UI components
│   └── utils/                  # Utilities
├── test/
│   ├── models/
│   ├── services/
│   ├── widgets/
│   ├── integration/
│   └── e2e/                    # Minimal E2E tests
├── scripts/                    # Build/deploy scripts
├── docs/                       # Documentation
└── .github/                    # GitHub Actions
```

### Layer Responsibilities

**Purpose and Example:**

```dart
// 1. Models - Pure data classes, no logic
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

// 2. Services - Business logic, no UI
class TransactionService {
  TransactionService(this._repository);
  final TransactionRepository _repository;

  Future<void> addTransaction(Transaction transaction) async {
    if (transaction.amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }
    await _repository.save(transaction);
  }
}

// 3. Repositories - Data access, abstract persistence
abstract class TransactionRepository {
  Future<void> save(Transaction transaction);
  Future<Transaction?> findById(String id);
  Future<List<Transaction>> findAll();
}

// 4. Providers - State management, connect services to UI
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

// 5. Screens - Full-screen views, orchestrate widgets
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

// 6. Widgets - Reusable UI components
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

Never hardcode values. Use configuration layers:

```dart
// Environment variables (deployment)
const apiUrl = String.fromEnvironment('API_URL');

// Config files (per environment)
final config = await loadConfig('config/prod.json');

// Remote config (runtime)
final remoteConfig = await RemoteConfig.instance.fetch();
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

This document defines the standards and practices for contributing to Art Finance Hub. All LLM contributors must follow these guidelines to maintain code quality, architectural integrity, and long-term maintainability.

**Remember:** These are not suggestions—they are requirements. Following these guidelines ensures the project remains scalable, testable, and maintainable as it grows.

**Questions?** Refer to this document first. If still unclear, ask the user.

**Changes?** Update this document when guidelines evolve.

**Version History:**
- 1.0.0 (2025-11-28): Initial version
- 1.1.0 (2025-11-28): Streamlined version - reduced redundancy, removed premature details, focused on project-specific guidance

---

*End of claude.md*
