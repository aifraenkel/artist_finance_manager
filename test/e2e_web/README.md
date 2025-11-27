# E2E Web Tests with Playwright

This directory contains browser-based end-to-end (E2E) tests using Playwright for the web version of the application.

## Purpose

These tests verify the application works correctly in a real browser environment:
- App loads and renders correctly
- Main UI elements are visible and accessible
- Basic smoke tests for critical user flows

## Setup

1. Install dependencies:
   ```bash
   cd test/e2e_web
   npm install
   ```

2. Install Playwright browsers:
   ```bash
   npx playwright install chromium
   ```

## Running Tests

### Quick Start (Recommended)

Use the automated script that builds, serves, tests, and cleans up:

```bash
cd test/e2e_web
./run-e2e-tests.sh
```

This script will:
1. Build the Flutter web app
2. Start a local server on port 8000
3. Run the Playwright tests
4. Stop the server automatically

### Manual Method

If you prefer to run steps manually:

**Terminal 1 - Build and serve the app:**
```bash
# From project root
flutter build web --release
cd build/web
python3 -m http.server 8000
```

**Terminal 2 - Run tests:**
```bash
cd test/e2e_web
npm test
```

**Important:** Keep Terminal 1 running while tests execute in Terminal 2.

### With custom base URL

```bash
E2E_BASE_URL=http://localhost:3000 npm test
```

### Other test commands

```bash
# Run in headed mode (see browser)
npm run test:headed

# Debug tests
npm run test:debug

# View test report
npm run report
```

## Test Structure

- `tests/app-loads.spec.ts` - Tests for app loading and initial rendering
- `tests/transaction-flow.spec.ts` - Tests for basic transaction functionality

## Notes on Testing Flutter Web

Flutter web apps use canvas-based rendering, which can make them challenging to test with traditional browser automation tools. These tests primarily use:

- Text-based selectors (works well with Flutter's default rendering)
- Generous timeouts for Flutter initialization
- Smoke tests rather than detailed interaction testing

For detailed user interaction testing, prefer:
- E2E widget tests (`test/e2e_widget/`) for cross-platform end-to-end testing
- Flutter integration tests (`test/integration_test/`) for mobile device testing
- Unit and widget tests for component-level testing

## CI Integration

These tests run automatically in CI as a separate job after the Flutter web build completes.
