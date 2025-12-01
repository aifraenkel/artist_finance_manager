# End-to-End Authentication Tests

## Overview

The E2E tests (`__tests__/auth_flow.e2e.test.js`) validate the complete authentication flows from registration to sign-in, testing the actual Cloud Functions endpoints as they would be used by the Flutter app.

## What These Tests Do

### Registration Flow Test
1. ✅ Creates a registration request (calls `createRegistration` endpoint)
2. ✅ Retrieves the token from Firestore (simulates clicking email link)
3. ✅ Verifies the token (calls `verifyRegistrationToken` endpoint)
4. ✅ Validates Firebase Auth user creation
5. ✅ Validates Firestore user profile creation
6. ✅ Validates token is marked as completed
7. ✅ Tests token reuse protection
8. ✅ Tests duplicate registration prevention

### Sign-In Flow Test
1. ✅ Creates a sign-in request for existing user (calls `createSignInRequest` endpoint)
2. ✅ Retrieves the sign-in token from Firestore
3. ✅ Verifies the token (calls `verifyRegistrationToken` endpoint)
4. ✅ Validates `lastLoginAt` timestamp update
5. ✅ Validates no duplicate user creation
6. ✅ Tests rejection of non-existent user

### Security Tests
1. ✅ Rejects invalid token format
2. ✅ Rejects expired tokens
3. ✅ Validates required fields
4. ✅ Validates email format
5. ✅ Validates name length

## Prerequisites

### 1. Cloud Functions Deployed or Running Locally

**Option A: Test Against Deployed Functions (Recommended)**
```bash
# Make sure your functions are deployed
cd functions
npm run deploy
```

**Option B: Test Against Local Functions**
```bash
# Start functions locally (in separate terminal)
cd functions
npm start
```

### 2. Firebase Admin SDK Credentials

The tests need Firebase Admin SDK credentials to access Firestore and Firebase Auth for validation and cleanup.

Make sure you have one of:
- `GOOGLE_APPLICATION_CREDENTIALS` environment variable set
- Running in Google Cloud environment (GCP, Cloud Functions, Cloud Run)
- Firebase Admin SDK automatically authenticated

### 3. Firestore Access

Tests need read/write access to:
- `pendingRegistrations` collection
- `users` collection

## Running the Tests

### Run E2E Tests Only

```bash
cd functions
npm run test:e2e
```

This will:
- Run only the E2E tests (files matching `*.e2e.test.js`)
- Use `--runInBand` to run tests sequentially (required for E2E tests)
- Test against deployed Cloud Functions by default

### Run Against Local Functions

```bash
cd functions
FUNCTIONS_BASE_URL=http://localhost:8080 npm run test:e2e
```

### Run Unit Tests Only

```bash
cd functions
npm run test:unit
```

This runs all tests except E2E tests.

### Run All Tests

```bash
cd functions
npm test
```

This runs both unit tests and E2E tests.

## Configuration

### Environment Variables

- `FUNCTIONS_BASE_URL` - Base URL for Cloud Functions
  - Default: `https://us-central1-artist-manager-479514.cloudfunctions.net`
  - Local: `http://localhost:8080`
  - Example: `FUNCTIONS_BASE_URL=https://your-project.cloudfunctions.net npm run test:e2e`

## Test Output

The tests provide detailed console output showing each step:

```
🧪 Starting E2E Authentication Tests
📍 Functions URL: https://us-central1-artist-manager-479514.cloudfunctions.net
📍 App URL: https://artist-manager-479514.web.app

E2E Authentication Flows
  Registration Flow (New User)
    📤 Calling createRegistration...
    📥 Response from createRegistration: { status: 200, data: {...} }
    ✅ Step 1 Complete: Registration request created

    🔍 Looking for pending registration token...
    ✅ Found token: abc123...
    ✅ Step 2 Complete: Token stored in Firestore

    📤 Calling verifyRegistrationToken...
    ✅ Step 3 Complete: Token verified, Firebase user created

    ... and so on
```

## Test Data Cleanup

The tests automatically clean up test data:
- **Before tests**: Removes any existing test users/tokens
- **After tests**: Removes all created test users/tokens

Test emails use timestamps to ensure uniqueness:
```javascript
e2e-test-registration-1701234567890@example.com
e2e-test-signin-1701234567891@example.com
```

## Troubleshooting

### Tests Fail with "Function not found"

**Cause**: Cloud Functions not deployed or wrong base URL

**Solution**:
```bash
# Deploy functions first
cd functions
npm run deploy

# Or test against local functions
FUNCTIONS_BASE_URL=http://localhost:8080 npm run test:e2e
```

### Tests Fail with Authentication Errors

**Cause**: Firebase Admin SDK not authenticated

**Solution**:
```bash
# Set credentials
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"

# Or use gcloud
gcloud auth application-default login
```

### Tests Fail with "Permission Denied"

**Cause**: Service account doesn't have Firestore permissions

**Solution**: Ensure service account has:
- `roles/datastore.user` (Firestore access)
- `roles/firebase.admin` (Firebase Auth access)

### Tests Are Slow

**Cause**: E2E tests make real HTTP requests and interact with real databases

**Expected**: E2E tests take 30-60 seconds to complete

**Tip**: Run unit tests during development (`npm run test:unit`) and E2E tests before deployment

### Token Not Found in Firestore

**Cause**: Email service might not have created the pending registration

**Debug**:
1. Check function logs: `gcloud functions logs read createRegistration`
2. Check Firestore console for `pendingRegistrations` collection
3. Verify function deployed correctly

## CI/CD Integration

### GitHub Actions Example

```yaml
name: E2E Tests

on:
  push:
    branches: [main]
  pull_request:

jobs:
  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install dependencies
        run: cd functions && npm ci

      - name: Authenticate to GCP
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}

      - name: Run E2E Tests
        run: cd functions && npm run test:e2e
        env:
          FUNCTIONS_BASE_URL: ${{ secrets.FUNCTIONS_BASE_URL }}
```

## What's NOT Tested

These E2E tests focus on Cloud Functions behavior. They do **NOT** test:

1. ❌ **Email delivery** - Tests don't verify actual emails are sent (would require email service integration)
2. ❌ **Flutter app UI** - These are backend tests only
3. ❌ **Firebase Auth sign-in link validation** - Tests receive the link but don't validate it with Firebase Auth SDK
4. ❌ **Network errors/retries** - Tests assume network connectivity
5. ❌ **Rate limiting** - Tests don't verify rate limit behavior

For complete end-to-end testing including the Flutter app, see the Flutter integration tests in `/test/integration_test/`.

## Test Coverage

Current E2E test coverage:

| Flow | Coverage |
|------|----------|
| Registration (Happy Path) | ✅ 100% |
| Sign-In (Happy Path) | ✅ 100% |
| Token Validation | ✅ 100% |
| Error Handling | ✅ 80% |
| Edge Cases | ⚠️ 60% |

## Adding New E2E Tests

To add new E2E test cases:

1. Add test to `__tests__/auth_flow.e2e.test.js`
2. Follow the existing pattern:
   ```javascript
   it('Should do something', async () => {
     // Call Cloud Function
     const { status, data } = await callCloudFunction('functionName', {...});

     // Validate response
     expect(status).toBe(200);
     expect(data.success).toBe(true);

     // Validate side effects (Firestore, Firebase Auth, etc.)
     const doc = await firestore.collection('...').doc('...').get();
     expect(doc.exists).toBe(true);
   });
   ```
3. Clean up test data in `afterAll` or `afterEach`
4. Run tests: `npm run test:e2e`

## Performance Benchmarks

Expected test execution times:

- **Registration Flow**: ~15-20 seconds
- **Sign-In Flow**: ~10-15 seconds
- **Security Tests**: ~5-10 seconds
- **Total E2E Suite**: ~30-45 seconds

These times include:
- HTTP requests to Cloud Functions
- Firestore read/write operations
- Firebase Auth operations
- Cleanup operations

## Related Documentation

- [REGISTRATION_FLOW.md](../docs/REGISTRATION_FLOW.md) - Server-side registration flow details
- [AUTH_SETUP.md](../docs/AUTH_SETUP.md) - Firebase Auth configuration
- [TEST_GUIDE.md](../docs/TEST_GUIDE.md) - Complete testing documentation

## Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section above
2. Review function logs: `gcloud functions logs read <function-name>`
3. Open an issue on GitHub with test output
