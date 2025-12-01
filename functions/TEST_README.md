# Cloud Functions Testing Guide

## Overview

The Cloud Functions have comprehensive unit tests that run **autonomously on localhost without requiring Firebase**. This means:

- ✅ **Fast** - Tests run in milliseconds
- ✅ **Reliable** - No network dependencies or external services
- ✅ **CI/CD Ready** - Can run in automated pipelines
- ✅ **No Firebase Required** - Firestore and email services are mocked
- ✅ **Test Business Logic** - Focus on what matters

## Running Tests

### Prerequisites

1. Node.js 20+ installed
2. Inside the `functions/` directory

### Install Dependencies

```bash
cd functions
npm install
```

This will install:
- `jest` - Test framework
- `@jest/globals` - Jest ES modules support

### Run All Tests

```bash
npm test
```

Output:
```
PASS  __tests__/registration_service.test.js
PASS  __tests__/email_templates.test.js

Test Suites: 2 passed, 2 total
Tests:       25 passed, 25 total
Snapshots:   0 total
Time:        1.234 s
```

### Run Tests in Watch Mode

Automatically re-run tests when files change:

```bash
npm run test:watch
```

### Run Tests with Coverage

Generate code coverage report:

```bash
npm run test:coverage
```

Output includes:
- Line coverage
- Branch coverage
- Function coverage
- Statement coverage

Coverage report saved to `coverage/` directory.

### Run Specific Test File

```bash
npm test registration_service
```

Or:

```bash
npm test email_templates
```

## Test Structure

### Test Files

```
functions/
├── __tests__/
│   ├── registration_service.test.js   # Tests for registration logic
│   └── email_templates.test.js        # Tests for email generation
├── registration_service.js             # Source code
├── email_templates.js                  # Source code
└── jest.config.js                      # Jest configuration
```

### What's Tested

#### `registration_service.test.js`

- ✅ Token generation (uniqueness, format)
- ✅ Registration creation (data structure, Firestore calls)
- ✅ Token verification (valid, expired, already-used)
- ✅ Token expiration (24-hour window)
- ✅ Cleanup of expired registrations
- ✅ Pending registration queries
- ✅ Registration cancellation

#### `email_templates.test.js`

- ✅ Email structure (HTML and text versions)
- ✅ Content validation (name, URL included)
- ✅ HTML validity (proper structure)
- ✅ Text version (no HTML tags)
- ✅ Special character handling
- ✅ URL with query parameters
- ✅ Different templates for registration vs sign-in

## Mocking Strategy

### Firestore Mocking

Tests use Jest mocks to simulate Firestore without connecting to actual Firebase:

```javascript
const mockFirestore = {
  collection: jest.fn(),
  batch: jest.fn(),
};
```

This allows testing business logic independently of Firebase infrastructure.

### Benefits

1. **Speed** - No network calls, tests run in < 2 seconds
2. **Isolation** - Each test is independent
3. **Determinism** - Tests always produce same results
4. **No Cleanup** - No test data left in Firebase
5. **No Costs** - No Firebase usage charges

## Coverage Goals

Aim for:
- **70%+ line coverage** (enforced in jest.config.js)
- **70%+ branch coverage**
- **70%+ function coverage**

Current coverage targets are configured in `jest.config.js`.

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Test Cloud Functions

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      - name: Install dependencies
        working-directory: functions
        run: npm install
      - name: Run tests
        working-directory: functions
        run: npm test
      - name: Check coverage
        working-directory: functions
        run: npm run test:coverage
```

## Writing New Tests

### Example Test Structure

```javascript
import { describe, it, expect, beforeEach } from '@jest/globals';

describe('My Function', () => {
  beforeEach(() => {
    // Reset mocks before each test
    jest.clearAllMocks();
  });

  it('should do something', async () => {
    // Arrange
    const input = 'test';

    // Act
    const result = await myFunction(input);

    // Assert
    expect(result).toBe('expected');
  });
});
```

### Best Practices

1. **One assertion per test** - Keep tests focused
2. **Descriptive names** - `it('should return error for invalid token')`
3. **AAA Pattern** - Arrange, Act, Assert
4. **Mock external dependencies** - Firestore, email, etc.
5. **Test edge cases** - Empty strings, null, undefined
6. **Test error handling** - Invalid inputs, expired data

## Integration Testing

For integration testing with actual Firebase:

1. Use Firebase Emulator Suite (separate from unit tests)
2. Run with `firebase emulators:start`
3. Set environment variable: `FIRESTORE_EMULATOR_HOST=localhost:8080`

**Note:** Unit tests (these tests) do NOT require the emulator.

## Troubleshooting

### "Cannot find module" Error

```bash
cd functions
npm install
```

### Tests Timeout

Check for:
- Async functions without `await`
- Missing `return` or `await` in tests
- Infinite loops

### Mock Not Working

Ensure mocks are set up **before** importing the module:

```javascript
jest.unstable_mockModule('@google-cloud/firestore', () => ({
  Firestore: jest.fn(() => mockFirestore)
}));

// Then import
const module = await import('../my-module.js');
```

### ES Modules Issues

Our code uses ES modules (`import`/`export`). Jest configuration includes:

```javascript
"test": "node --experimental-vm-modules node_modules/jest/bin/jest.js"
```

This enables ES module support.

## Performance

Tests should be fast:
- ✅ **Individual test** - < 100ms
- ✅ **Full suite** - < 5 seconds
- ✅ **With coverage** - < 10 seconds

If tests are slow:
1. Check for actual network calls (should be mocked)
2. Reduce unnecessary `setTimeout` or delays
3. Optimize mock setup

## Next Steps

1. **Add more tests** - Expand coverage as needed
2. **Integration tests** - Test with Firebase Emulator
3. **E2E tests** - Test full flow with real email service
4. **Performance tests** - Test under load

## Resources

- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [Jest ES Modules](https://jestjs.io/docs/ecmascript-modules)
- [Testing Best Practices](https://testingjavascript.com/)

## Summary

✅ **No Firebase Required** - All tests run on localhost
✅ **Fast Execution** - Complete suite in < 5 seconds
✅ **High Coverage** - 70%+ enforced
✅ **CI/CD Ready** - Easy to integrate
✅ **Easy to Maintain** - Clear structure and mocking
