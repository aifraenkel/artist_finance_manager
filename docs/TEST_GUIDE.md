# Testing Guide

## Overview

This project implements a comprehensive testing strategy with multiple test types running at different levels:

- **Unit Tests**: Test individual functions, classes, and business logic
- **E2E Widget Tests**: End-to-end tests in Flutter test framework (all platforms)
- **E2E Web Tests**: End-to-end tests in real browser using Playwright (web only)
- **Integration Tests**: Test complete app on real devices/simulators (mobile only)

Each test type runs as a separate CI check to provide fast, focused feedback.

## Test Structure

```
test/                                    → All tests
├── e2e_widget/                         → E2E tests using widget framework (all platforms)
│   └── app_flow_integration_test.dart
├── e2e_web/                            → E2E tests using Playwright (web only)
│   ├── tests/
│   │   ├── app-loads.spec.ts          → App loading smoke tests
│   │   └── transaction-flow.spec.ts   → Transaction flow tests
│   ├── playwright.config.ts
│   └── package.json
├── integration_test/                   → True integration tests (mobile only)
│   ├── auth_e2e_test.dart
│   └── pages/                          → Page object helpers (if needed)
│       └── auth_page.dart
├── models/                             → Model unit tests
│   └── transaction_test.dart
├── services/                           → Service unit tests
│   └── storage_service_test.dart
└── widget_test.dart                    → Basic widget tests
```

**Test Type Summary:**
- **`test/e2e_widget/`**: E2E tests in Flutter test framework (all platforms, fast)
- **`test/e2e_web/`**: E2E tests in real browser with Playwright (web only, slow)
- **`test/integration_test/`**: True integration tests on real devices (mobile only)

## Running Tests Locally

### 1. Unit and Widget Tests

Fast tests for business logic and UI components:

```bash
# Run all unit and widget tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/models/transaction_test.dart

# View coverage report (after running with --coverage)
open coverage/index.html
```

### 2. E2E Widget Tests

End-to-end user flow tests using Flutter's widget test framework (works on all platforms):

```bash
# Run all E2E widget tests
flutter test test/e2e_widget/

# Run specific test
flutter test test/e2e_widget/app_flow_integration_test.dart

# Run with verbose output
flutter test test/e2e_widget/ --verbose
```

### 3. True Integration Tests (Mobile Only)

These tests run the complete app on real devices or simulators:

```bash
# Run all integration tests
flutter test test/integration_test/

# Run on specific device
flutter test test/integration_test/ -d iPhone
flutter test test/integration_test/ -d android

# Run with verbose output
flutter test test/integration_test/ --verbose
```

**Note:** These tests use Flutter's `integration_test` package which **does not support web**. For web testing, use E2E widget tests or E2E web tests.

### 4. E2E Web Tests (Playwright)

Smoke tests against the built web app in a real browser:

**First time setup:**
```bash
cd test/e2e_web
npm install
npx playwright install chromium
```

**Run tests (automated - recommended):**
```bash
cd test/e2e_web
./run-e2e-tests.sh
```

This script automatically builds, serves, tests, and cleans up.

**Run tests (manual method):**

Terminal 1 - Build and serve:
```bash
flutter build web --release
cd build/web
python3 -m http.server 8000
```

Terminal 2 - Run tests:
```bash
cd test/e2e_web
npm test                # Run all tests
npm run test:headed     # Run with visible browser
npm run test:debug      # Interactive debugging
npm run report          # View test report
```

**With custom URL:**
```bash
E2E_BASE_URL=http://localhost:3000 npm test
```

## Test Coverage Goals

- **Target**: 80% code coverage
- **Unit Tests**: All models and services
- **Widget Tests**: All UI components
- **Integration Tests**: Critical user journeys
- **E2E Tests**: Small smoke suite (2-5 tests)

### Check Current Coverage

```bash
flutter test --coverage
lcov --summary coverage/lcov.info
```

## Writing Tests

### Unit Test Example

```dart
test('Transaction model serialization', () {
  // Arrange
  final transaction = Transaction(
    id: 123,
    description: 'Test',
    amount: 100.0,
    type: 'expense',
    category: 'Other',
    date: DateTime.now(),
  );

  // Act
  final json = transaction.toJson();
  final recreated = Transaction.fromJson(json);

  // Assert
  expect(recreated.description, 'Test');
  expect(recreated.amount, 100.0);
});
```

### Widget Test Example

```dart
testWidgets('Summary cards display correctly', (WidgetTester tester) async {
  // Build widget
  await tester.pumpWidget(
    MaterialApp(
      home: SummaryCards(
        totalIncome: 1000.0,
        totalExpenses: 500.0,
        balance: 500.0,
      ),
    ),
  );

  // Verify
  expect(find.text('Income'), findsOneWidget);
  expect(find.text('€1000.00'), findsOneWidget);
});
```

### Flutter Integration Test with Page Objects

```dart
testWidgets('User can add expense', (WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  final homePage = HomePage(tester);
  await homePage.verifyPageLoaded();

  // Add expense using page object
  await homePage.addExpense(
    category: 'Musicians',
    description: 'Band payment',
    amount: '1000',
  );

  // Verify
  homePage.verifyTransactionExists('Band payment');
  homePage.verifySummary(expenses: '€1000.00');
});
```

### Playwright E2E Test Example

```typescript
test('app loads and displays title', async ({ page }) => {
  await page.goto('/');

  await expect(page.locator('text=Project Finance Tracker'))
    .toBeVisible({ timeout: 30000 });

  await expect(page.locator('text=Income')).toBeVisible();
  await expect(page.locator('text=Expenses')).toBeVisible();
});
```

## Page Objects

The `test/integration_test/pages/` directory contains page object helpers that make tests more maintainable:

- `HomePage`: Encapsulates interactions with the home screen
  - `verifyPageLoaded()`: Check app loaded successfully
  - `addExpense()`, `addIncome()`: Add transactions
  - `deleteFirstTransaction()`: Remove a transaction
  - `verifySummary()`: Check balance calculations

Example:
```dart
final homePage = HomePage(tester);
await homePage.addExpense(
  category: 'Musicians',
  description: 'Studio time',
  amount: '500',
);
```

## CI/CD Testing

Tests run automatically in GitHub Actions as **4 separate jobs**:

### Job 1: `analyze` - Code Analysis
- Runs `dart format --set-exit-if-changed`
- Runs `flutter analyze --fatal-infos`

### Job 2: `tests-unit-widget` - Unit & Widget Tests
- Runs `flutter test --coverage`
- Generates and uploads coverage reports
- Fast feedback on core logic

### Job 3: `tests-e2e-widget` - E2E Widget Tests
- Runs `flutter test test/e2e_widget/`
- Tests complete user flows using widget test framework
- Works on all platforms (unlike true integration tests which are mobile-only)

### Job 4: `tests-e2e-web` - Browser E2E Tests
- Builds `flutter build web --release`
- Runs Playwright tests against the built app
- Final smoke test in real browser environment

All jobs run in parallel (except unit/widget and integration which wait for analyze).

## Debugging Tests

### Unit/Widget Tests

```bash
# Run with verbose output
flutter test --verbose

# Run specific test
flutter test test/models/transaction_test.dart

# Debug in VS Code
# Click "Run" or "Debug" above the test
```

### Integration Tests

```bash
# Verbose mode
flutter test test/integration_test/ --verbose

# Run on specific device
flutter test test/integration_test/ -d iPhone --verbose
```

### Playwright Tests

```bash
cd test/e2e_web

# Debug mode (opens inspector)
npm run test:debug

# Headed mode (see browser)
npm run test:headed

# Specific test file
npx playwright test tests/app-loads.spec.ts
```

## Mocking

- **Unit/Widget Tests**: Use `SharedPreferences.setMockInitialValues({})`
- **Integration Tests**: Run against real storage (cleared between tests)
- **E2E Tests**: Test against real built app with real browser storage

## Common Issues

### "No device found" for integration tests
- **Web**: Ensure Chrome is installed
- Run `flutter devices` to verify

### Integration tests fail on CI but pass locally
- Check Flutter version matches CI
- Verify all dependencies in pubspec.yaml
- Add more `pumpAndSettle()` calls for timing issues

### E2E tests timeout
- Increase timeout: `{ timeout: 60000 }`
- Check app is running and accessible
- Verify `E2E_BASE_URL` is correct

### Coverage not generating
```bash
flutter clean
flutter pub get
flutter test --coverage
```

## Notes on Testing Flutter Web

### Why Three Types of E2E/Integration Tests?

Flutter's `integration_test` package **does not support web platforms** - it only works on iOS and Android. This is a known Flutter limitation.

**Our Testing Strategy:**
- **`test/e2e_widget/`**: E2E tests using Flutter widget test framework
  - ✅ Work on ALL platforms (web, mobile, desktop)
  - ✅ Fast execution (no device/build required)
  - ✅ Test complete user flows
  - ⚠️ Run in simulated environment

- **`test/e2e_web/`**: E2E tests using Playwright browser
  - ✅ Test deployed web application
  - ✅ Real browser rendering and behavior
  - ❌ Web only (no mobile support)

- **`test/integration_test/`**: True integration tests
  - ✅ Test actual app as users experience it
  - ✅ Real platform behavior and APIs
  - ❌ Mobile only (no web support)

### Canvas Rendering and Playwright

Flutter web uses canvas-based rendering (CanvasKit). Playwright can't "see" text or elements inside the canvas. Our Playwright tests:

- Wait for canvas element to appear
- Use screenshot-based verification
- Focus on smoke tests (loads, no crashes, responsiveness)
- Avoid detailed interactions (handled by integration-style tests)

For detailed user interaction testing, use the E2E widget tests in `test/e2e_widget/`.

## Cleaning Test Artifacts

To clean all test artifacts and temporary files:

```bash
# Run the cleanup script
cd test && ./clean-test-artifacts.sh

# Or manually clean specific artifacts
rm -rf coverage/                      # Coverage reports
rm -rf build/                         # Flutter build artifacts
rm -rf test/e2e_web/test-results/     # E2E test results
rm -rf test/e2e_web/playwright-report/ # Playwright HTML reports
```

## Additional Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Playwright Documentation](https://playwright.dev)
- [Widget Testing Best Practices](https://docs.flutter.dev/cookbook/testing/widget/introduction)
