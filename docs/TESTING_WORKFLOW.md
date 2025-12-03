# Test Workflow Documentation

## Overview

This project uses a comprehensive test workflow system that runs all tests in parallel for every pull request and push to main/master branches.

## Workflow Structure

### Main Test Workflow: `test-all.yml`

This workflow is triggered on:
- Pull requests to `main` or `master` branches
- Pushes to `main` or `master` branches

#### Test Jobs (Run in Parallel)

1. **Flutter Unit & Widget Tests** (`flutter-unit-widget-tests`)
   - Runs all Flutter unit and widget tests
   - Excludes integration tests using `--exclude-tags=integration`
   - Generates code coverage reports
   - Uploads coverage artifacts

2. **Flutter Integration Tests** (`flutter-integration-tests`)
   - Runs integration tests tagged with `integration`
   - Conditionally executes based on presence of integration test files
   - Located in `test/integration_test/`

3. **Cloud Functions Unit Tests** (`functions-unit-tests`)
   - Runs Node.js/Jest unit tests for Cloud Functions
   - Excludes E2E tests (files ending in `.e2e.test.js`)
   - Generates code coverage using Jest
   - Located in `functions/__tests__/`

4. **Cloud Functions E2E Tests** (`functions-e2e-tests`)
   - Runs end-to-end tests for Cloud Functions
   - Only runs files matching `*.e2e.test.js`
   - Conditionally executes based on presence of E2E test files
   - Located in `functions/__tests__/`

#### Test Summary Job

The `test-summary` job runs after all test jobs complete (even if some fail) and:

1. Downloads all coverage artifacts
2. Generates a comprehensive test summary including:
   - Status of each test suite (✅ Passed, ❌ Failed, ⏭️ Skipped)
   - Code coverage reports for both Flutter and Cloud Functions
   - Overall test result
3. Posts/updates a comment on the PR with the test summary
4. Fails the workflow if any required tests failed

## Test Coverage Reporting

### Flutter Coverage
- Generated using `flutter test --coverage`
- Processed with `lcov` to create summaries
- Coverage files stored in `coverage/lcov.info`

### Cloud Functions Coverage
- Generated using Jest's built-in coverage
- Coverage summary in JSON format
- Includes coverage thresholds defined in `jest.config.js`

## How Tests Block PR Merges

1. Each test job must complete successfully (or be skipped if no tests exist)
2. The `test-summary` job aggregates results and fails if any test failed
3. GitHub branch protection rules should require the `Test Summary & PR Comment` check to pass
4. Failed tests will prevent PR merges automatically

### Setting Up Branch Protection

To enforce test passing before merging PRs, repository administrators should configure branch protection rules:

1. Go to **Settings** → **Branches** in your GitHub repository
2. Add a branch protection rule for `main` and/or `master`
3. Enable **Require status checks to pass before merging**
4. Search for and select these required checks:
   - `Test Summary & PR Comment` (from test-all.yml)
   - `Analyze & Format Check` (from flutter-ci.yml - optional but recommended)
5. Enable **Require branches to be up to date before merging** (recommended)
6. Save the branch protection rule

Once configured, PRs cannot be merged until all required status checks pass.

## Relationship with Other Workflows

### `flutter-ci.yml`
- Handles code analysis and formatting checks
- Keeps cross-platform tests (macOS, Windows) for platform-specific validation
- No longer runs unit/widget/integration tests (moved to `test-all.yml`)

### `code-quality.yml`
- Runs AI code review, dependency review, and security scans
- Operates independently of test workflows

### `deploy-gcp.yml`
- Runs after successful CI on main branch
- Performs deployment to Google Cloud Platform
- Runs production E2E tests against deployed service

## Running Tests Locally

### Flutter Tests
```bash
# All unit and widget tests with coverage
flutter test --coverage --exclude-tags=integration

# Integration tests only
flutter test --tags=integration

# Specific test file
flutter test test/services/storage_service_test.dart
```

### Cloud Functions Tests
```bash
cd functions

# All tests
npm test

# Unit tests only
npm run test:unit

# E2E tests only
npm run test:e2e

# With coverage
npm run test:coverage
```

## Adding New Tests

### Flutter Tests
1. Add test files to appropriate directories under `test/`
2. Use `_test.dart` suffix for test files
3. Tag integration tests with `@Tags(['integration'])`
4. Tests automatically run in CI on next push

### Cloud Functions Tests
1. Add test files to `functions/__tests__/`
2. Use `.test.js` suffix for unit tests
3. Use `.e2e.test.js` suffix for E2E tests
4. Tests automatically run in CI on next push

## Troubleshooting

### Tests Pass Locally But Fail in CI
- Check for environment-specific dependencies
- Ensure all required secrets/environment variables are configured
- Review CI logs for specific error messages

### Coverage Thresholds Not Met
- Check `jest.config.js` for Cloud Functions coverage thresholds
- Add more tests to improve coverage
- Review uncovered code paths in coverage reports

### Test Summary Not Appearing on PR
- Ensure the workflow has `pull-requests: write` permission
- Check that the bot user has access to comment on PRs
- Review workflow logs for the `Comment PR with test results` step

## Best Practices

1. **Write tests before code** - Follow TDD principles
2. **Keep tests fast** - Use mocks and stubs appropriately
3. **Test isolation** - Each test should be independent
4. **Clear test names** - Use descriptive names that explain what's being tested
5. **Maintain coverage** - Keep coverage high to ensure code quality
6. **Tag appropriately** - Use tags to organize test suites (e.g., `integration`, `e2e`)
