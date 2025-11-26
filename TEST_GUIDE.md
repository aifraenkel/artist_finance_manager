# Testing Guide

## Overview

This project includes comprehensive testing at multiple levels:
- **Unit Tests**: Test individual functions and classes
- **Widget Tests**: Test UI components
- **Integration Tests (E2E)**: Test complete user flows

## Running Tests

### All Unit & Widget Tests
```bash
flutter test
```

### With Coverage
```bash
flutter test --coverage
open coverage/index.html  # View coverage report
```

### Integration Tests (E2E)

#### Flutter Integration Tests (Mobile/Native)

For testing native mobile app flows using Flutter's integration_test framework:

**iOS Simulator:**
```bash
open -a Simulator
flutter test integration_test/app_test.dart -d "iPhone 15 Pro"
```

**Android Emulator:**
```bash
# Start emulator from Android Studio first
flutter test integration_test/app_test.dart -d <emulator-id>
```

**Web (Chrome driver):**
```bash
flutter test integration_test/app_test.dart -d chrome
```

#### Arbigent E2E Tests (Web - AI-Powered)

For comprehensive web application testing using AI-powered scenarios:

**Why Arbigent?**
- Specifically designed for Flutter web apps (works with canvas rendering)
- AI-based testing that adapts to UI changes
- Natural language test scenarios
- Visual assertions for UI validation

**Setup & Usage:**

See [arbigent/README.md](arbigent/README.md) for complete instructions.

Quick start:
```bash
# 1. Build and serve the web app
flutter build web --release
cd build/web && python3 -m http.server 8000 &

# 2. Configure API key (one-time setup)
export OPENAI_API_KEY="your-api-key"

# 3. Run Arbigent tests
arbigent run --project-file=arbigent/project.yaml --os=web
```

**Note:** Arbigent requires an OpenAI API key (~$1-2/month for typical usage). The integration_test approach above does not require any API keys.

## Test Structure

```
test/
├── widget_test.dart              # Main UI tests
├── models/
│   └── transaction_test.dart     # Transaction model tests
└── services/
    └── storage_service_test.dart # Storage service tests

integration_test/
└── app_test.dart                 # Flutter E2E tests (native mobile/web)

arbigent/
├── project.yaml                  # Arbigent test scenarios (web)
└── README.md                     # Arbigent setup guide
```

## Test Coverage Goals

- **Target**: 80% code coverage
- **Unit Tests**: All models and services
- **Widget Tests**: All UI components
- **E2E Tests**: Critical user journeys

## Current Test Coverage

Run to check:
```bash
flutter test --coverage
lcov --summary coverage/lcov.info
```

## Writing New Tests

### Unit Test Example
```dart
test('Description of test', () {
  // Arrange
  final service = MyService();

  // Act
  final result = service.doSomething();

  // Assert
  expect(result, expectedValue);
});
```

### Widget Test Example
```dart
testWidgets('Widget description', (WidgetTester tester) async {
  // Build widget
  await tester.pumpWidget(MyWidget());

  // Verify widget appears
  expect(find.text('Expected text'), findsOneWidget);

  // Interact
  await tester.tap(find.byType(Button));
  await tester.pump();

  // Verify result
  expect(find.text('Result'), findsOneWidget);
});
```

### Integration Test Example
```dart
testWidgets('E2E flow', (WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Complete user journey
  // ...
});
```

## CI/CD Testing

Tests automatically run on:
- Every pull request
- Every push to main/master branch

See `.github/workflows/` for configuration.

## Debugging Tests

Run specific test file:
```bash
flutter test test/models/transaction_test.dart
```

Run with verbose output:
```bash
flutter test --verbose
```

Debug in IDE:
- VS Code: Click "Run" above test
- Android Studio: Right-click test → Run

## Mocking

This project uses:
- `SharedPreferences.setMockInitialValues()` for storage mocking
- Flutter's built-in test framework

## Common Issues

**"No device found" for integration tests:**
- Web: Install Chrome
- iOS: Start simulator first
- Android: Start emulator first

**Tests fail on CI but pass locally:**
- Check Flutter version matches CI
- Verify all dependencies are in pubspec.yaml
- Check for timing issues (add more `pumpAndSettle()`)

**Coverage not generating:**
```bash
flutter test --coverage
# If fails, try:
flutter pub get
flutter clean
flutter test --coverage
```
