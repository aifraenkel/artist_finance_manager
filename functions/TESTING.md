# Cloud Functions Testing Guide

## Quick Start

### Run All Tests
```bash
cd functions
npm test
```

### Run Unit Tests Only
```bash
npm run test:unit
```

### Run E2E Tests Only
```bash
npm run test:e2e
```

## Test Types

### 1. Unit Tests (`__tests__/*.test.js`)
- Fast, isolated tests with mocked dependencies
- Test business logic in isolation
- No external dependencies (Firestore, Firebase Auth mocked)
- **Run time**: ~2-5 seconds

**Example**: `registration_service.test.js`
- Tests token generation
- Tests token verification logic
- Tests cleanup logic

### 2. E2E Tests (`__tests__/*.e2e.test.js`)
- Test complete user flows
- Call actual Cloud Function HTTP endpoints
- Interact with real Firestore and Firebase Auth
- Simulate user actions (clicking email links)
- **Run time**: ~30-45 seconds

**Example**: `auth_flow.e2e.test.js`
- Tests registration flow (8 steps)
- Tests sign-in flow (6 steps)
- Tests security validations

## Test Structure

```
functions/
├── __tests__/
│   ├── registration_service.test.js    # Unit tests
│   ├── email_templates.test.js         # Unit tests
│   └── auth_flow.e2e.test.js          # E2E tests (NEW!)
├── jest.config.js                      # Jest configuration
├── package.json                        # Test scripts
├── TESTING.md                          # This file
└── README_E2E_TESTS.md                # Detailed E2E docs
```

## npm Scripts

| Command | Description |
|---------|-------------|
| `npm test` | Run all tests (unit + E2E) |
| `npm run test:unit` | Run unit tests only |
| `npm run test:e2e` | Run E2E tests only |
| `npm run test:watch` | Run tests in watch mode |
| `npm run test:coverage` | Run tests with coverage report |

## E2E Test Details

The E2E tests simulate complete authentication flows:

### Registration Flow (New User)
```
User → createRegistration → Email with token
     → Click link (simulated by getting token from Firestore)
     → verifyRegistrationToken → Firebase user created
     → User authenticated ✓
```

### Sign-In Flow (Existing User)
```
User → createSignInRequest → Email with token
     → Click link
     → verifyRegistrationToken → lastLoginAt updated
     → User authenticated ✓
```

**What's validated:**
- ✅ HTTP endpoint responses
- ✅ Firestore data structure
- ✅ Firebase Auth user creation
- ✅ Token lifecycle (pending → completed)
- ✅ Security (token reuse, expiration, validation)

## Running E2E Tests

### Against Deployed Functions (Default)
```bash
npm run test:e2e
```

### Against Local Functions
```bash
# Terminal 1: Start functions locally
npm start

# Terminal 2: Run E2E tests
FUNCTIONS_BASE_URL=http://localhost:8080 npm run test:e2e
```

### Custom Functions URL
```bash
FUNCTIONS_BASE_URL=https://your-region-your-project.cloudfunctions.net npm run test:e2e
```

## Prerequisites for E2E Tests

1. **Cloud Functions**: Deployed or running locally
2. **Firebase Admin SDK**: Authenticated (for cleanup)
3. **Firestore Access**: Read/write permissions

See [README_E2E_TESTS.md](./README_E2E_TESTS.md) for detailed setup.

## Test Coverage

### Current Coverage

| Component | Unit Tests | E2E Tests |
|-----------|-----------|-----------|
| Token Generation | ✅ | ✅ |
| Token Verification | ✅ | ✅ |
| Registration Flow | ⚠️ Partial | ✅ Complete |
| Sign-In Flow | ❌ | ✅ Complete |
| Token Cleanup | ✅ | ⚠️ Partial |
| Email Templates | ✅ | ❌ |
| Error Handling | ✅ | ✅ |

### What's NOT Tested
- Actual email delivery (SMTP)
- Flutter app UI
- Network failures/retries
- Rate limiting
- Firebase Auth link validation (client-side)

## Continuous Integration

### Example GitHub Actions
```yaml
- name: Run Unit Tests
  run: cd functions && npm run test:unit

- name: Run E2E Tests
  run: cd functions && npm run test:e2e
  env:
    FUNCTIONS_BASE_URL: ${{ secrets.FUNCTIONS_BASE_URL }}
```

## Debugging Tests

### View detailed output
```bash
npm test -- --verbose
```

### Run specific test file
```bash
npm test -- auth_flow.e2e.test.js
```

### Run specific test case
```bash
npm test -- -t "Should create registration request"
```

### Debug with Node Inspector
```bash
node --inspect-brk --experimental-vm-modules node_modules/jest/bin/jest.js
```

## Best Practices

### Unit Tests
✅ DO:
- Mock external dependencies
- Test edge cases and error handling
- Keep tests fast (< 100ms each)
- Test business logic in isolation

❌ DON'T:
- Make network requests
- Access real databases
- Depend on test order

### E2E Tests
✅ DO:
- Test happy path flows
- Clean up test data
- Use unique test data (timestamps)
- Run sequentially (`--runInBand`)
- Add console.log for debugging

❌ DON'T:
- Test every edge case (use unit tests)
- Leave test data in production
- Rely on external services (email delivery)

## Troubleshooting

### "Cannot find module"
```bash
cd functions
npm install
```

### "Firebase Admin not initialized"
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"
```

### "Function not found" (E2E tests)
```bash
# Deploy functions first
npm run deploy

# Or test locally
npm start
FUNCTIONS_BASE_URL=http://localhost:8080 npm run test:e2e
```

### "Permission denied" (E2E tests)
Ensure service account has:
- `roles/datastore.user`
- `roles/firebase.admin`

### Tests are flaky
E2E tests may be flaky due to:
- Network latency
- Firestore eventual consistency
- Firebase Auth delays

**Solution**: E2E tests run sequentially (`--runInBand`) to minimize flakiness

## Related Documentation

- [README_E2E_TESTS.md](./README_E2E_TESTS.md) - Detailed E2E test documentation
- [../docs/REGISTRATION_FLOW.md](../docs/REGISTRATION_FLOW.md) - Registration flow architecture
- [../docs/TEST_GUIDE.md](../docs/TEST_GUIDE.md) - Complete testing guide for entire project

## Support

For questions or issues:
1. Check this documentation
2. Review test output and logs
3. Open GitHub issue with:
   - Test output
   - Function logs
   - Expected vs actual behavior
