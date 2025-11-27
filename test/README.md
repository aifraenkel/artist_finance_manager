# Testing Guide

This directory contains all tests for the Artist Finance Manager application. Tests are organized by type and execution environment.

## Test Directory Structure

```
test/
├── e2e_widget/            # E2E tests using widget test framework (all platforms)
├── e2e_web/               # E2E tests using Playwright browser (web only)
├── integration_test/      # True integration tests on real devices (mobile only)
├── models/                # Unit tests
├── services/              # Unit tests
└── widget_test.dart       # Basic widget tests
```

## Test Types

### 1. E2E Widget Tests (`test/e2e_widget/`)

**What:** End-to-end tests using Flutter's widget test framework
**Environment:** Flutter test framework (simulated)
**Platforms:** ✅ All (iOS, Android, Web, Desktop)
**Speed:** Fast

These tests simulate complete user journeys from start to finish using Flutter's widget testing framework. They use `tester.pumpWidget()` to instantiate the app and mock dependencies like `SharedPreferences`.

**Advantages:**
- Run on all platforms including web
- Fast execution (no device/simulator required)
- Test complete user flows end-to-end
- Easy to debug and maintain
- Cross-platform compatibility

**Constraints:**
- Runs in simulated environment (not production build)
- Some platform-specific behaviors may differ from real devices

**Run command:**
```bash
flutter test test/e2e_widget/
```

**Example use cases:**
- Complete user flows (add transaction → verify balance → delete transaction)
- Multi-step form interactions
- Navigation flows
- State management across screens

---

### 2. E2E Web Tests (`test/e2e_web/`)

**What:** End-to-end tests using Playwright in a real browser
**Environment:** Real browser (Chromium)
**Platforms:** ✅ Web only
**Speed:** Slowest

These tests run the deployed web application in a real browser environment using Playwright. They validate that the app works correctly in actual browser environments with real rendering and JavaScript execution.

**Advantages:**
- Tests actual browser rendering
- Validates deployed web application
- Catches browser-specific issues
- Real browser APIs and behaviors

**Constraints:**
- **Web only** (not for mobile/desktop)
- Slower execution (requires build + server)
- Flutter web uses canvas rendering, limiting element inspection
- Requires Node.js and Playwright setup

**Run commands:**
```bash
# Quick automated run (recommended)
cd test/e2e_web
./run-e2e-tests.sh

# Manual run
flutter build web --release
cd build/web && python3 -m http.server 8000 &
cd test/e2e_web && npm test
```

**Example use cases:**
- Smoke tests (app loads, no crashes)
- Browser compatibility validation
- Deployed application verification
- Visual regression testing

---

### 3. Integration Tests (`test/integration_test/`)

**What:** True integration tests running on real devices/simulators
**Environment:** Real device or simulator
**Platforms:** ✅ iOS, Android | ❌ Web
**Speed:** Medium

These tests use Flutter's `integration_test` package and run your complete app in a real environment. They call `app.main()` to launch the actual application with all its services and dependencies.

**Advantages:**
- Tests the actual app as users experience it
- Real platform behavior and APIs
- Catches platform-specific issues
- Tests actual device performance

**Constraints:**
- **Cannot run on web** (Flutter integration_test limitation)
- Requires device/simulator
- Slower than widget tests
- More complex setup

**Run commands:**
```bash
# iOS
flutter test test/integration_test/ -d iPhone

# Android
flutter test test/integration_test/ -d android

# All connected devices
flutter test test/integration_test/
```

**Example use cases:**
- Mobile-specific user flows
- Platform API validation
- Performance testing on real hardware
- Device-specific behavior verification

---

## Quick Reference

| Test Type | Location | Platforms | Speed | Use For |
|-----------|----------|-----------|-------|---------|
| E2E Widget | `test/e2e_widget/` | All | Fast | User flows (simulated) |
| E2E Web | `test/e2e_web/` | Web | Slow | Browser smoke tests |
| Integration | `test/integration_test/` | Mobile | Medium | Real device testing |

## Running All Tests

```bash
# Run all Flutter tests (e2e_widget + unit + widget)
flutter test

# Run E2E widget tests (all platforms)
flutter test test/e2e_widget/

# Run integration tests (mobile only, requires device)
flutter test test/integration_test/

# Run E2E web tests (web only)
cd test/e2e_web && ./run-e2e-tests.sh
```

## CI/CD

All test types run automatically in CI:
- Widget tests run on every push
- Integration tests run on mobile platform builds
- E2E tests run after successful web builds

See `.github/workflows/` for CI configuration.

## Best Practices

1. **Start with widget integration tests** - They're fast and cover most scenarios
2. **Use integration tests for mobile-specific features** - When you need real platform APIs
3. **Use E2E tests sparingly** - Focus on critical smoke tests for web deployment
4. **Keep tests independent** - Each test should set up and tear down its own state
5. **Mock external dependencies** - In widget tests, mock APIs and storage

## Common Issues

### Integration tests fail on web
**Solution:** Integration tests don't support web. Use widget integration tests instead.

### E2E tests timeout
**Solution:** Ensure app is built and served on port 8000 before running tests.

### SharedPreferences errors in tests
**Solution:** Add `SharedPreferences.setMockInitialValues({});` in `setUp()`.

## Cleaning Test Artifacts

To clean all test artifacts and build files:

```bash
# From test/ directory
./clean-test-artifacts.sh

# From project root
./test/clean-test-artifacts.sh
```

This removes:
- Coverage reports
- Test results
- E2E reports
- Build artifacts
- Temporary files

## Additional Resources

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Playwright Documentation](https://playwright.dev/)
