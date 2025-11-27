# End-to-End Tests with Stagehand

This directory contains AI-powered end-to-end tests for the Artist Finance Manager web application using [Stagehand](https://github.com/browserbase/stagehand), an open-source browser automation framework.

## Why Stagehand?

- **Natural Language**: Write test actions in plain English instead of complex selectors
- **AI-Powered**: Uses OpenAI GPT-4o-mini for intelligent UI interaction
- **Self-Healing**: Automatically adapts to minor UI changes
- **Cost-Effective**: Caching reduces API costs by ~90%
- **Works with Flutter Web**: Handles canvas-based rendering seamlessly

## Prerequisites

### 1. Install Dependencies

```bash
cd e2e
npm install
```

### 2. Get an OpenAI API Key

1. Visit [OpenAI Platform](https://platform.openai.com/api-keys)
2. Create an account or sign in
3. Generate a new API key
4. Save it securely

**Cost Estimate**: ~$0.50-2/month for typical test usage (with caching enabled)

### 3. Configure API Key

Set your OpenAI API key as an environment variable:

```bash
# Add to your ~/.bashrc, ~/.zshrc, or ~/.profile
export OPENAI_API_KEY="sk-your-api-key-here"

# Or create a .env file in the e2e directory
echo "OPENAI_API_KEY=sk-your-api-key-here" > .env
```

## Running Tests

### Run All Tests

```bash
# 1. Build and serve the Flutter web app (in project root)
flutter build web --release
cd build/web
python3 -m http.server 8000 &

# 2. Run tests (in e2e directory)
cd ../../e2e
npm test
```

### Run Tests with Browser Visible (Headed Mode)

Useful for debugging:

```bash
npm run test:headed
```

### Run Tests in Watch Mode

Auto-rerun tests when files change:

```bash
npm run test:watch
```

### Run Specific Test File

```bash
npm test -- finance-tracker.test.ts
```

### Custom Test URL

If your app is running on a different port:

```bash
TEST_URL=http://localhost:3000 npm test
```

## Test Structure

### Test Files

```
e2e/
├── finance-tracker.test.ts  # Main E2E test suite
├── package.json             # Dependencies
├── tsconfig.json           # TypeScript configuration
├── jest.config.js          # Jest test runner config
└── README.md               # This file
```

### Test Scenarios

The test suite covers:

1. **App Loading**: Verifies the app loads and shows initial €0.00 state
2. **Complete User Flow**: Add expense → Add income → Verify balance → Delete transaction
3. **Form Validation**: Tests that empty form submission shows errors
4. **Category Switching**: Verifies Income/Expense category switching works
5. **Multiple Transactions**: Tests adding and displaying multiple transactions

## Writing New Tests

Stagehand uses natural language for test actions:

```typescript
import { Stagehand } from '@browserbasehq/stagehand';

// Initialize Stagehand
const stagehand = new Stagehand({
  env: 'LOCAL',
  modelName: 'gpt-4o-mini',
  enableCaching: true,
  modelClientOptions: {
    apiKey: process.env.OPENAI_API_KEY
  }
});

await stagehand.init();

// Navigate
await stagehand.page.goto('http://localhost:8000');

// Perform actions with natural language
await stagehand.page.act('click the Musicians category');
await stagehand.page.act('enter "Band payment" in the description field');
await stagehand.page.act('type "1000" in the amount field');
await stagehand.page.act('click the Add button');

// Extract information
const balance = await stagehand.page.extract('What is the balance amount?');
expect(balance).toContain('1500');

// Cleanup
await stagehand.close();
```

### Best Practices

1. **Be Descriptive**: Clear, detailed prompts work better than vague ones
2. **Break Down Steps**: Complex actions should be split into smaller steps
3. **Verify State**: Use `extract()` to verify UI state after actions
4. **Use Caching**: Enable caching to save costs (already enabled by default)
5. **Handle Timing**: Stagehand waits automatically, but complex UIs may need explicit waits

## Cost Optimization

### Current Configuration (Optimized)

- **Model**: `gpt-4o-mini` (75% cheaper than gpt-4o)
- **Caching**: Enabled (90% cost reduction on repeated actions)
- **Estimated Cost**: ~$0.01-0.02 per test run

### Monthly Cost Estimate

- **100 test runs/month**: ~$0.50-2
- **500 test runs/month**: ~$2-10

### Further Optimization

**Use even cheaper model** (if quality is acceptable):
```typescript
modelName: 'gpt-3.5-turbo' // Even cheaper, but less capable
```

**Run tests selectively**:
```bash
# Only run specific tests during development
npm test -- --testNamePattern="App loads"
```

**Cache aggressively**:
```typescript
enableCaching: true  // Already enabled
```

## Troubleshooting

### "OpenAI API key not found"

**Solution**: Ensure `OPENAI_API_KEY` is set:
```bash
echo $OPENAI_API_KEY  # Should print your key
export OPENAI_API_KEY="sk-..."
```

### "Test timeout"

**Cause**: AI processing can be slow on first run

**Solutions**:
- Increase timeout in `jest.config.js` (currently 120s)
- Enable caching (already enabled)
- Subsequent runs will be much faster

### "Cannot connect to http://localhost:8000"

**Solution**: Ensure Flutter web app is running:
```bash
cd ../build/web
python3 -m http.server 8000
```

### Tests fail but manual testing works

**Possible causes**:
- AI misunderstood the UI
- Timing issues (Flutter still loading)
- UI changed significantly

**Solutions**:
- Make prompts more specific
- Add explicit waits
- Run in headed mode to see what's happening: `npm run test:headed`

### High API costs

**Solutions**:
- Verify caching is enabled (check `enableCaching: true`)
- Use `gpt-4o-mini` instead of `gpt-4o`
- Run tests less frequently during development
- Use watch mode to avoid re-running all tests

## CI/CD Integration

### GitHub Actions Example

Add to `.github/workflows/e2e-tests.yml`:

```yaml
name: E2E Tests (Stagehand)

on:
  pull_request:
    branches: [ main, master ]
  push:
    branches: [ main, master ]

jobs:
  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable

      - name: Build Flutter web
        run: flutter build web --release

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install E2E dependencies
        run: |
          cd e2e
          npm install

      - name: Start web server
        run: |
          cd build/web
          python3 -m http.server 8000 &
          echo $! > ../../server.pid

      - name: Run E2E tests
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          cd e2e
          npm test

      - name: Stop web server
        if: always()
        run: kill $(cat server.pid) || true
```

**Important**: Add `OPENAI_API_KEY` to your GitHub repository secrets.

## Comparison with Other Approaches

| Aspect | Stagehand | Puppeteer | Playwright | Selenium |
|--------|-----------|-----------|------------|----------|
| **Natural Language** | ✅ Yes | ❌ No | ❌ No | ❌ No |
| **AI-Powered** | ✅ Yes | ❌ No | ⚠️ Optional | ❌ No |
| **Self-Healing** | ✅ Yes | ❌ No | ❌ No | ❌ No |
| **Flutter Web** | ✅ Good | ⚠️ Limited | ⚠️ Limited | ⚠️ Limited |
| **Maintenance** | ⭐ Very Low | ⭐⭐⭐ High | ⭐⭐ Medium | ⭐⭐⭐ High |
| **Cost** | ~$0.50-2/mo | Free | Free | Free |

## Further Reading

- [Stagehand GitHub](https://github.com/browserbase/stagehand)
- [Stagehand Documentation](https://docs.stagehand.dev/)
- [OpenAI API Pricing](https://openai.com/api/pricing/)
- [Jest Documentation](https://jestjs.io/)

## Support

For issues with:
- **Stagehand**: [GitHub Issues](https://github.com/browserbase/stagehand/issues)
- **This implementation**: Contact the team or create an issue in this repository
