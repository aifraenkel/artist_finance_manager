# Title: Deployment Smoke Test Automation

## Labels
testing, ci-cd, deployment, low-priority

## Body

## Overview

Implement automated post-deployment smoke tests to verify critical user flows after deployment, with automatic rollback on failure, as required by `claude.md` section 10.

## Background

`claude.md` section 10 (CI/CD and Deployment) requires:
- "Run minimal E2E test suite (< 10 tests)" before deployment
- "Post-deployment verification" smoke tests
- "Monitor for errors and rollback if necessary"

**Smoke Test Goals:**
- Verify app loads successfully
- Verify critical flows work
- Catch deployment issues immediately
- Enable safe, confident deployments

## Requirements

### 1. Pre-Deployment Smoke Tests

Minimal E2E tests that must pass before deployment:

**Required tests (< 10 total):**
- [ ] App loads without errors
- [ ] User can sign in
- [ ] User can view dashboard
- [ ] User can add a transaction
- [ ] User can delete a transaction
- [ ] User can sign out
- [ ] App works on web
- [ ] App works on mobile (iOS/Android)

**Characteristics:**
- Fast (< 5 minutes total)
- Reliable (no flaky tests)
- Critical flows only
- Run in CI before deployment

### 2. Post-Deployment Verification

Automated tests that run against production immediately after deployment:

```bash
# Post-deployment smoke test
./scripts/smoke-test.sh https://app.example.com

# Expected output:
# ✅ App loads
# ✅ Authentication works
# ✅ Dashboard displays
# ✅ Add transaction works
# ✅ Delete transaction works
# ✅ Sign out works
#
# Smoke tests PASSED - Deployment verified
```

**On failure:**
- Alert team immediately
- Trigger automatic rollback
- Log failure details
- Create incident report

### 3. Smoke Test Implementation

**Option A: Playwright (Web)**
```typescript
// smoke-tests/critical-flow.spec.ts
test('critical user journey', async ({ page }) => {
  // 1. App loads
  await page.goto(process.env.APP_URL);
  await expect(page.locator('h1')).toContainText('Finance Tracker');

  // 2. Sign in
  await page.click('text=Sign In');
  await page.fill('[name=email]', 'test@example.com');
  await page.fill('[name=password]', 'password');
  await page.click('button[type=submit]');

  // 3. View dashboard
  await expect(page.locator('text=Dashboard')).toBeVisible();

  // 4. Add transaction
  await page.click('text=Add Transaction');
  await page.fill('[name=amount]', '100');
  await page.click('button[type=submit]');
  await expect(page.locator('text=$100')).toBeVisible();

  // 5. Sign out
  await page.click('text=Sign Out');
  await expect(page.locator('text=Sign In')).toBeVisible();
});
```

**Option B: Flutter Integration Tests**
```dart
// smoke_test/critical_flow_test.dart
testWidgets('critical user journey', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // 1. App loads
  expect(find.text('Finance Tracker'), findsOneWidget);

  // 2. Sign in
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
  // ... authentication flow

  // 3. View dashboard
  expect(find.text('Dashboard'), findsOneWidget);

  // 4. Add transaction
  await tester.tap(find.text('Add Transaction'));
  await tester.enterText(find.byKey(Key('amount')), '100');
  await tester.tap(find.text('Submit'));
  await tester.pumpAndSettle();
  expect(find.text('\$100'), findsOneWidget);

  // 5. Sign out
  await tester.tap(find.text('Sign Out'));
  await tester.pumpAndSettle();
  expect(find.text('Sign In'), findsOneWidget);
});
```

### 4. Rollback Mechanism

Automated rollback on smoke test failure:

```bash
#!/bin/bash
# scripts/deploy-with-verification.sh

echo "🚀 Deploying to production..."
./scripts/deploy.sh

if [ $? -eq 0 ]; then
  echo "✅ Deployment successful"

  echo "🧪 Running smoke tests..."
  ./scripts/smoke-test.sh $PROD_URL

  if [ $? -eq 0 ]; then
    echo "✅ Smoke tests passed - Deployment verified!"
    exit 0
  else
    echo "❌ Smoke tests failed - Rolling back..."
    ./scripts/rollback.sh
    exit 1
  fi
else
  echo "❌ Deployment failed"
  exit 1
fi
```

### 5. Monitoring & Alerting

- [ ] Send alerts on smoke test failures (Slack, email, PagerDuty)
- [ ] Log all smoke test results
- [ ] Track smoke test success rate over time
- [ ] Create dashboards for deployment health

### 6. Deployment Checklist

Automated checklist that runs post-deployment:

```markdown
## Post-Deployment Checklist

### Automated Checks
- [x] App loads without errors
- [x] No console errors
- [x] API endpoints responding
- [x] Authentication working
- [x] Database connection healthy
- [x] Critical user flows working

### Manual Checks (if automated passes)
- [ ] Check Grafana for error spikes
- [ ] Review recent user reports
- [ ] Spot check a few features
- [ ] Verify mobile apps still working

### Rollback Decision
- If any automated check fails → Automatic rollback
- If manual checks reveal issues → Manual rollback
```

## Acceptance Criteria

- [ ] Pre-deployment smoke test suite (< 10 tests)
- [ ] Post-deployment verification script
- [ ] Automatic rollback on smoke test failure
- [ ] Smoke tests run in CI before deployment
- [ ] Smoke tests run against production after deployment
- [ ] Alerts configured for failures
- [ ] Documentation for smoke test process
- [ ] Smoke test results logged and tracked

## Implementation Strategy

### Phase 1: Identify Critical Flows
1. List all critical user journeys
2. Prioritize top 5-10 flows
3. Define success criteria for each
4. Document test scenarios

### Phase 2: Implement Smoke Tests
1. Create smoke test framework
2. Write tests for critical flows
3. Test against staging environment
4. Ensure tests are fast and reliable

### Phase 3: CI Integration
1. Add smoke tests to CI pipeline
2. Run before deployment gate
3. Block deployment on failure
4. Configure notifications

### Phase 4: Post-Deployment Verification
1. Create post-deployment verification script
2. Implement rollback mechanism
3. Test rollback process
4. Set up monitoring and alerts

## Testing Strategy

**Test the smoke tests:**
- [ ] Run smoke tests against staging
- [ ] Verify they catch real issues
- [ ] Ensure no false positives
- [ ] Test rollback mechanism
- [ ] Verify alerts work

## Related Issues

- #21 - Real E2E tests for web (smoke tests are subset)
- #22 - Integration tests for web
- Relates to: CI/CD pipeline configuration

## Related Files

- `scripts/deploy-with-verification.sh` (new)
- `scripts/smoke-test.sh` (new)
- `scripts/rollback.sh` (update)
- `test/smoke/` (new directory)
- `.github/workflows/deploy.yml` (update)
- `claude.md` - Section 10

## Priority

**Low-Medium** - Important for production confidence, but can deploy without it initially

**When to prioritize:**
- Before public launch
- After experiencing deployment issues
- When deploying frequently
- When multiple people deploy

## Benefits

1. **Confidence:** Deploy with confidence knowing critical flows work
2. **Fast Feedback:** Catch deployment issues immediately
3. **Safety Net:** Automatic rollback prevents user-facing issues
4. **Accountability:** Clear verification before deployment is "done"

## Resources

- [Smoke Testing Best Practices](https://martinfowler.com/bliki/SyntheticMonitoring.html)
- [Playwright](https://playwright.dev/) - for web smoke tests
- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)

## Example Deployment Flow

```
1. Code merged to main
2. CI runs all tests
3. Pre-deployment smoke tests run
   ├─ If fail: Block deployment
   └─ If pass: Continue
4. Deploy to production
5. Post-deployment smoke tests run
   ├─ If fail: Automatic rollback + alert
   └─ If pass: Deployment verified ✅
6. Monitor production metrics
```
