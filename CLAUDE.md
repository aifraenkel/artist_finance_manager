# CLAUDE.md - AI Assistant Guide

**Artist Finance Manager - Codebase Guide for AI Assistants**
Last Updated: 2025-11-26

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Codebase Structure](#codebase-structure)
3. [Development Workflows](#development-workflows)
4. [Key Conventions](#key-conventions)
5. [Testing Strategy](#testing-strategy)
6. [Common Development Tasks](#common-development-tasks)
7. [Build & Deployment](#build--deployment)
8. [Important Patterns](#important-patterns)
9. [DO's and DON'Ts](#dos-and-donts)

---

## Project Overview

**Tech Stack:** Flutter 3.x + Dart 3.0+
**Architecture:** Model-View-Service (simple state management with setState)
**Platforms:** iOS, Android, Web
**Storage:** SharedPreferences (local-only, no backend)
**Purpose:** Finance tracking app for artists to manage project income/expenses

### Core Features
- Add/delete transactions (income/expense)
- Dynamic category system (7 expense, 3 income categories)
- Real-time summary calculations (income, expenses, balance)
- Responsive UI (mobile-first design with tablet/desktop support)
- Local data persistence with JSON serialization
- Cross-platform with single codebase

---

## Codebase Structure

```
artist_finance_manager/
├── lib/                          # Main application code
│   ├── main.dart                 # App entry point (theme, MaterialApp setup)
│   ├── models/
│   │   └── transaction.dart      # Data model with JSON serialization
│   ├── services/
│   │   └── storage_service.dart  # SharedPreferences wrapper
│   ├── screens/
│   │   └── home_screen.dart      # Main UI screen (state management)
│   └── widgets/
│       ├── summary_cards.dart    # Income/Expense/Balance display
│       ├── transaction_form.dart # Add transaction form with validation
│       └── transaction_list.dart # Transaction history list
├── test/                         # Unit and widget tests
│   ├── widget_test.dart          # Main UI flow tests (6 test cases)
│   ├── models/
│   │   └── transaction_test.dart # Model serialization tests
│   └── services/
│       └── storage_service_test.dart # Storage logic tests
├── integration_test/
│   └── app_test.dart             # E2E user journey tests
├── e2e_web/
│   ├── e2e_web_test.js           # Puppeteer browser automation
│   └── package.json              # Node.js dependencies
├── android/                      # Android platform code
├── ios/                          # iOS platform code
├── web/                          # Web platform code
├── .github/workflows/            # CI/CD pipelines
│   ├── flutter-ci.yml            # Multi-platform testing + coverage
│   ├── code-quality.yml          # AI review, security scanning
│   └── e2e-tests.yml             # Mobile E2E (currently disabled)
├── pubspec.yaml                  # Dependencies and project config
├── analysis_options.yaml         # Linter rules
├── README.md                     # User-facing documentation
├── SETUP_GUIDE.md                # Setup instructions
└── TEST_GUIDE.md                 # Testing documentation
```

### File Size Reference
- `main.dart`: ~50 lines
- `transaction.dart`: ~42 lines
- `storage_service.dart`: ~48 lines
- `home_screen.dart`: ~172 lines
- `summary_cards.dart`: ~186 lines
- `transaction_form.dart`: ~248 lines
- `transaction_list.dart`: ~253 lines

---

## Development Workflows

### Local Development Setup

```bash
# 1. Install dependencies
flutter pub get

# 2. Verify Flutter installation
flutter doctor

# 3. Run on different platforms
flutter run -d chrome           # Web (best for rapid development)
flutter run -d "iPhone 15 Pro"  # iOS simulator
flutter run -d <android-device> # Android emulator/device

# 4. Hot reload during development (automatic)
# Press 'r' for hot reload, 'R' for hot restart, 'q' to quit
```

### Testing Workflow

```bash
# Run all unit and widget tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests (requires running app)
flutter test integration_test/app_test.dart

# Run web E2E tests
flutter build web --release
cd build/web && python3 -m http.server 8000 &
cd e2e_web && npm test
```

### Git Workflow

**Branch Structure:**
- Main branch: `main` (production-ready)
- Feature branches: `claude/claude-md-<session-id>` (AI-generated)
- PR-based workflow with GitHub Actions checks

**Commit Standards:**
- Descriptive messages explaining "why" not "what"
- Follow conventional commits when possible
- All commits trigger CI/CD pipeline

**Pre-merge Requirements:**
- All tests passing (Linux, macOS, Windows)
- Code coverage maintained
- Linter checks passing
- Security scan passing

---

## Key Conventions

### Dart/Flutter Code Style

#### Naming Conventions
```dart
// Class names: PascalCase
class TransactionForm extends StatefulWidget { }

// Private properties/methods: _camelCase
void _handleSubmit() { }
final List<Transaction> _transactions = [];

// Public properties/methods: camelCase
void addTransaction(Transaction transaction) { }

// Constants: lowerCamelCase (or UPPER_SNAKE_CASE for top-level)
const String storageKey = 'project-finances';
const double _borderRadius = 12.0;

// Widget keys for testing: snake_case with Key suffix
const Key('add_transaction_button')
const Key('description_field')
```

#### Code Organization
```dart
// 1. Imports (dart: packages first, then flutter:, then third-party, then relative)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

// 2. Class declaration
class MyWidget extends StatefulWidget {
  // 3. Constructor
  const MyWidget({Key? key}) : super(key: key);

  // 4. Override createState
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

// 5. State class
class _MyWidgetState extends State<MyWidget> {
  // 6. Properties (public then private)
  final List<Item> items = [];
  late TextEditingController _controller;

  // 7. Lifecycle methods
  @override
  void initState() { }

  @override
  void dispose() { }

  // 8. Event handlers (private)
  void _handleTap() { }

  // 9. Helper methods (private)
  Widget _buildCard() { }

  // 10. Build method (last)
  @override
  Widget build(BuildContext context) { }
}
```

### State Management Pattern

**Use `setState` for simple state updates:**
```dart
void _addTransaction(Transaction transaction) {
  setState(() {
    _transactions.add(transaction);
  });
  _saveTransactions();
}
```

**Computed properties for derived state:**
```dart
double get _totalIncome {
  return _transactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);
}
```

### Responsive Design Patterns

**Use LayoutBuilder for breakpoints:**
```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 800) {
      return _buildDesktopLayout();
    }
    return _buildMobileLayout();
  },
)
```

**Standard breakpoints:**
- Mobile portrait: < 600px (single column)
- Tablet/Desktop: >= 600px (multi-column)
- Wide screens: > 800px (constrained max-width 1200px)

### Widget Testability

**Always add keys to interactive elements:**
```dart
ElevatedButton(
  key: const Key('add_transaction_button'),
  onPressed: _handleSubmit,
  child: const Text('Add Transaction'),
)

DropdownButtonFormField(
  key: const Key('category_dropdown'),
  // ... other properties
)
```

**Key naming convention:**
- Use descriptive snake_case names
- Suffix with element type when needed
- Examples: `description_field`, `amount_field`, `delete_button_0`

---

## Testing Strategy

### Test Pyramid

```
     /\         E2E Tests (Puppeteer)
    /  \        - Web browser automation
   /____\       - Screenshot verification
  /      \      Integration Tests (Flutter)
 /        \     - Complete user journeys
/__________\    - Multi-step workflows
/            \  Unit & Widget Tests
/              \ - Model logic
/________________\ - Service operations
                   - Widget rendering
                   - Form validation
```

### Test Coverage Requirements
- Target: 80% minimum coverage
- All new features must include tests
- Critical paths must have integration tests

### Test File Organization

**Mirror source structure:**
```
lib/models/transaction.dart → test/models/transaction_test.dart
lib/services/storage_service.dart → test/services/storage_service_test.dart
lib/main.dart → test/widget_test.dart
```

### Testing Patterns

#### AAA Pattern (Arrange-Act-Assert)
```dart
test('should calculate total income correctly', () {
  // Arrange
  final transactions = [
    Transaction(/* ... income transaction ... */),
    Transaction(/* ... income transaction ... */),
  ];

  // Act
  final total = calculateTotalIncome(transactions);

  // Assert
  expect(total, equals(3500.0));
});
```

#### Widget Testing with Keys
```dart
testWidgets('should add transaction when form submitted', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();

  // Find elements by key
  final categoryDropdown = find.byKey(const Key('category_dropdown'));
  final descriptionField = find.byKey(const Key('description_field'));
  final amountField = find.byKey(const Key('amount_field'));
  final submitButton = find.byKey(const Key('add_transaction_button'));

  // Interact
  await tester.tap(categoryDropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Venue').last);
  await tester.pumpAndSettle();

  await tester.enterText(descriptionField, 'Test expense');
  await tester.enterText(amountField, '1000');

  await tester.tap(submitButton);
  await tester.pumpAndSettle();

  // Verify
  expect(find.text('Test expense'), findsOneWidget);
});
```

#### Mock SharedPreferences
```dart
import 'package:shared_preferences/shared_preferences.dart';

setUp(() {
  SharedPreferences.setMockInitialValues({});
});

test('should load transactions from storage', () async {
  SharedPreferences.setMockInitialValues({
    'project-finances': jsonEncode([/* ... */])
  });

  final service = StorageService();
  final transactions = await service.loadTransactions();

  expect(transactions.length, 2);
});
```

### E2E Testing (Web)

**Puppeteer test structure:**
```javascript
const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.goto('http://127.0.0.1:8000', {
    waitUntil: 'networkidle2',
    timeout: 30000
  });

  await new Promise(resolve => setTimeout(resolve, 10000));
  await page.screenshot({ path: 'screenshots/screenshot.png', fullPage: true });

  const content = await page.content();
  console.assert(content.includes('Project Finance Tracker'), 'Title not found');

  await browser.close();
})();
```

---

## Common Development Tasks

### Adding a New Transaction Category

**1. Update categories in `transaction_form.dart`:**
```dart
final Map<String, List<String>> _categories = {
  'expense': [
    'Venue', 'Musicians', 'Food & Drinks', 'Materials/Clothes',
    'Book Printing', 'Podcast', 'New Category', 'Other'  // Add here
  ],
  'income': [
    'Book Sales', 'Event Tickets', 'Other'
  ],
};
```

**2. Add test coverage in `widget_test.dart`:**
```dart
testWidgets('should show new category in dropdown', (WidgetTester tester) async {
  // Test that new category appears and can be selected
});
```

### Adding a New Field to Transaction Model

**1. Update `models/transaction.dart`:**
```dart
class Transaction {
  final int id;
  final String description;
  final double amount;
  final String type;
  final String category;
  final DateTime date;
  final String? notes;  // New field

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.notes,  // Add to constructor
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'amount': amount,
    'type': type,
    'category': category,
    'date': date.toIso8601String(),
    'notes': notes,  // Add to serialization
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      description: json['description'],
      amount: json['amount'],
      category: json['category'],
      type: json['type'],
      date: DateTime.parse(json['date']),
      notes: json['notes'],  // Add to deserialization
    );
  }
}
```

**2. Update `transaction_form.dart` to include new field input**

**3. Update `transaction_list.dart` to display new field**

**4. Add migration logic if needed for existing data**

**5. Update tests:**
- `test/models/transaction_test.dart` (serialization)
- `test/widget_test.dart` (form input)
- `integration_test/app_test.dart` (E2E flow)

### Adding a New Widget

**1. Create file in `lib/widgets/new_widget.dart`:**
```dart
import 'package:flutter/material.dart';

class NewWidget extends StatelessWidget {
  const NewWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Widget implementation
    );
  }
}
```

**2. Create test file `test/widgets/new_widget_test.dart`:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:artist_finance_manager/widgets/new_widget.dart';

void main() {
  testWidgets('NewWidget should render correctly', (WidgetTester tester) async {
    // Test implementation
  });
}
```

**3. Import and use in parent widget**

### Updating Dependencies

```bash
# Check for outdated packages
flutter pub outdated

# Update specific package
# Edit pubspec.yaml, then:
flutter pub get

# Update all packages to latest compatible versions
flutter pub upgrade

# After updating, run all tests
flutter test
flutter test integration_test/app_test.dart
```

**Always test after dependency updates:**
1. Run unit/widget tests
2. Run integration tests
3. Test on all platforms (web, iOS, Android)
4. Check for deprecation warnings
5. Update CI/CD if needed

---

## Build & Deployment

### Development Builds

```bash
# Debug build (hot reload enabled)
flutter run -d chrome           # Web
flutter run -d ios              # iOS
flutter run -d android          # Android

# Profile build (performance profiling)
flutter run --profile -d <device>
```

### Production Builds

```bash
# Web (static hosting)
flutter build web --release
# Output: build/web/ (deploy to Firebase, Netlify, Vercel, etc.)

# Android APK (direct installation)
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Android App Bundle (Google Play Store)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab

# iOS (App Store)
flutter build ios --release
# Then open ios/Runner.xcworkspace in Xcode for signing/upload
```

### Build Artifacts (gitignored)
- `build/` - All build outputs
- `.dart_tool/` - Dart tooling cache
- `e2e_web/node_modules/` - Node dependencies
- `e2e_web/screenshots/` - E2E screenshots
- `.flutter-plugins`, `.flutter-plugins-dependencies` - Plugin metadata

### Platform-Specific Configuration

**Android:** `android/app/build.gradle`
- Application ID: `com.artist.finance_manager`
- Min SDK: 21 (Android 5.0+)
- Target/Compile SDK: 34 (Android 14)

**iOS:** `ios/Runner/Info.plist`
- Bundle Identifier: `com.artist.financeManager`
- Min iOS Version: 12.0+

**Web:** `web/index.html`
- Custom loading spinner with gradient
- Meta tags for mobile web app capability
- Theme color: #2563EB (blue)

---

## Important Patterns

### Error Handling

**Storage Service Pattern (graceful degradation):**
```dart
Future<List<Transaction>> loadTransactions() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(storageKey);

    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Transaction.fromJson(json)).toList();
  } catch (e) {
    print('Error loading transactions: $e');
    return []; // Graceful degradation
  }
}
```

**User Feedback Pattern:**
```dart
void _handleDelete(int index) async {
  final transaction = _transactions[index];

  // Confirmation dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Transaction'),
      content: const Text('Are you sure?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    setState(() {
      _transactions.removeAt(index);
    });
    _saveTransactions();

    // User feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction deleted')),
    );
  }
}
```

### Form Validation

**Required field validation:**
```dart
TextFormField(
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a description';
    }
    return null;
  },
)
```

**Numeric validation:**
```dart
TextFormField(
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
  ],
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }
    return null;
  },
)
```

### Responsive Layout

**Constrained max-width pattern:**
```dart
Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 1200),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Content
        ],
      ),
    ),
  ),
)
```

**Adaptive columns:**
```dart
LayoutBuilder(
  builder: (context, constraints) {
    return constraints.maxWidth > 600
        ? Row(
            children: [
              Expanded(child: widget1),
              const SizedBox(width: 16),
              Expanded(child: widget2),
            ],
          )
        : Column(
            children: [
              widget1,
              const SizedBox(height: 16),
              widget2,
            ],
          );
  },
)
```

### JSON Serialization

**Model pattern:**
```dart
class Transaction {
  // Properties
  final int id;
  final String description;
  final double amount;

  // Constructor
  Transaction({required this.id, required this.description, required this.amount});

  // To JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'amount': amount,
  };

  // From JSON (factory constructor)
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      description: json['description'],
      amount: json['amount'],
    );
  }
}
```

### DateTime Handling

**ID generation:**
```dart
final id = DateTime.now().millisecondsSinceEpoch;
```

**Formatting:**
```dart
import 'package:intl/intl.dart';

final dateFormat = DateFormat('MMM d, yyyy');
final timeFormat = DateFormat('h:mm a');

final dateStr = dateFormat.format(transaction.date);  // "Nov 26, 2025"
final timeStr = timeFormat.format(transaction.date);  // "3:45 PM"
```

---

## DO's and DON'Ts

### DO ✓

#### Code Quality
- **Use const constructors** whenever possible for performance
- **Add keys to all interactive widgets** for testability
- **Follow AAA pattern** in tests (Arrange-Act-Assert)
- **Write descriptive commit messages** explaining "why" not "what"
- **Handle errors gracefully** with try-catch and fallback values
- **Validate user input** before processing
- **Use type-safe null handling** with Dart's null safety features

#### Development Workflow
- **Run tests before committing** (`flutter test`)
- **Test on multiple platforms** (web, iOS, Android) for new features
- **Check `flutter doctor`** after environment changes
- **Use hot reload** during development (press 'r' in terminal)
- **Keep dependencies up to date** (check with `flutter pub outdated`)

#### UI/UX
- **Design mobile-first** then scale up for larger screens
- **Use LayoutBuilder** for responsive breakpoints
- **Provide user feedback** with SnackBars for actions
- **Show confirmation dialogs** for destructive actions
- **Maintain consistent spacing** (12px, 16px, 24px)

#### Testing
- **Mirror source structure** in test files
- **Mock external dependencies** (SharedPreferences, etc.)
- **Test complete user journeys** in integration tests
- **Use key-based element finding** in widget tests
- **Verify both success and error cases**

### DON'T ✗

#### Code Quality
- **Don't use print() in production code** (remove debug prints)
- **Don't ignore linter warnings** (fix them or add suppressions with comments)
- **Don't skip error handling** in async operations
- **Don't use hard-coded values** (define constants)
- **Don't mix business logic with UI code** (keep services separate)

#### State Management
- **Don't use global state** for this app (setState is sufficient)
- **Don't mutate state outside setState()** (causes UI sync issues)
- **Don't store derived values in state** (use getters instead)
- **Don't forget to dispose controllers** (TextEditingController, etc.)

#### Testing
- **Don't skip tests** for new features
- **Don't use arbitrary waits** in tests (use `pumpAndSettle()` instead)
- **Don't test implementation details** (test behavior, not internals)
- **Don't share state between tests** (use setUp/tearDown)

#### Development Workflow
- **Don't commit without running tests**
- **Don't push directly to main** (use PRs)
- **Don't ignore CI/CD failures** (fix before merging)
- **Don't add large files to git** (check .gitignore)
- **Don't skip code review** for significant changes

#### Dependencies
- **Don't add unnecessary dependencies** (keep app lightweight)
- **Don't use deprecated packages** (check pub.dev for alternatives)
- **Don't update all dependencies at once** (update incrementally and test)

---

## Troubleshooting Common Issues

### Flutter Not Found
```bash
# Add to PATH (macOS/Linux)
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

### iOS Build Fails
```bash
cd ios
pod install
pod update
cd ..
flutter clean
flutter pub get
flutter run -d ios
```

### Android Build Fails
```bash
# Clear build cache
flutter clean
cd android
./gradlew clean
cd ..

# Rebuild
flutter pub get
flutter run -d android
```

### Web Build Fails
```bash
flutter clean
flutter pub get
flutter build web --release
```

### Tests Failing
```bash
# Clear test cache
flutter clean
flutter pub get

# Run tests with verbose output
flutter test --verbose

# Run specific test file
flutter test test/path/to/test_file.dart
```

### SharedPreferences Not Working
```dart
// Ensure mock is set up in tests
setUp(() {
  SharedPreferences.setMockInitialValues({});
});

// Verify instance is initialized
final prefs = await SharedPreferences.getInstance();
```

---

## CI/CD Pipeline Overview

### GitHub Actions Workflows

**`flutter-ci.yml` - Main CI Pipeline**
- **Linux**: Analyze, format check, lint, unit tests, coverage upload
- **macOS**: Analyzer + unit tests
- **Windows**: Analyzer + unit tests
- **Integration/Web**: Build web release, run Puppeteer E2E tests
- **Coverage**: Generate lcov reports, upload to Codecov
- **Artifacts**: Upload E2E screenshots

**`code-quality.yml` - Quality Checks**
- **CodeRabbit**: AI-powered code review on PRs
- **Dependency Review**: Automated dependency vulnerability scanning
- **Trivy Security Scan**: Container/code security analysis with SARIF output

**Triggers:**
- Push to any branch
- Pull requests to main
- Manual workflow dispatch

**Required Checks:**
- All tests pass (Linux, macOS, Windows)
- Linter passes
- Code coverage maintained
- Security scan passes
- Web E2E tests pass

---

## Additional Resources

### Documentation Files
- `README.md` - User-facing project overview and setup
- `SETUP_GUIDE.md` - Detailed setup instructions
- `TEST_GUIDE.md` - Testing documentation and strategies
- `CLAUDE.md` - This file (AI assistant guide)

### External References
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Widget Catalog](https://docs.flutter.dev/development/ui/widgets)
- [SharedPreferences Plugin](https://pub.dev/packages/shared_preferences)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)

### Project-Specific Links
- Repository: `https://github.com/aifraenkel/artist_finance_manager`
- Issues: Use GitHub Issues for bug reports and feature requests
- CI/CD: GitHub Actions (check `.github/workflows/`)

---

## Quick Reference Commands

```bash
# Development
flutter run -d chrome                  # Run on web
flutter run -d ios                     # Run on iOS
flutter run -d android                 # Run on Android

# Testing
flutter test                           # Unit/widget tests
flutter test --coverage                # With coverage
flutter test integration_test/app_test.dart  # Integration tests

# Build
flutter build web --release            # Web build
flutter build apk --release            # Android APK
flutter build ios --release            # iOS build

# Maintenance
flutter clean                          # Clean build artifacts
flutter pub get                        # Install dependencies
flutter pub outdated                   # Check for updates
flutter doctor                         # Check environment

# Analysis
flutter analyze                        # Run static analysis
dart format lib test                   # Format code
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-11-26 | Initial comprehensive documentation |

---

**Note to AI Assistants:** This guide is maintained to reflect the current state of the codebase. When making significant architectural changes, please update this document accordingly. Focus on maintaining the simple, testable architecture that makes this codebase easy to understand and modify.
