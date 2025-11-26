# Arbigent E2E Tests

This directory contains end-to-end tests for the Artist Finance Manager web application using [Arbigent](https://github.com/takahirom/arbigent), an AI-powered testing framework.

## Why Arbigent?

Arbigent was chosen to replace the previous Puppeteer-based tests because:

- **Flutter Web Compatibility**: Works with Flutter's canvas-based rendering where traditional DOM-based tools struggle
- **AI-Powered**: Uses natural language to describe test scenarios, making tests more resilient to UI changes
- **Scenario Breakdown**: Complex tests are decomposed into dependent scenarios for better organization and debugging
- **Visual Assertions**: Built-in image assertions verify UI state semantically, not just pixel-by-pixel
- **Cost-Effective**: ~$0.005 per test step with GPT-4o, even cheaper with GPT-4o-mini

## Prerequisites

### 1. Install Arbigent

**macOS (via Homebrew):**
```bash
brew tap takahirom/homebrew-repo
brew install takahirom/repo/arbigent
```

**Linux/Other:**
Download the latest release from [GitHub Releases](https://github.com/takahirom/arbigent/releases)

### 2. Get an OpenAI API Key

1. Visit [OpenAI Platform](https://platform.openai.com/api-keys)
2. Create an account or sign in
3. Generate a new API key
4. Save it securely (you'll need it for configuration)

**Note**: This is separate from ChatGPT Plus subscription. API access is pay-as-you-go.

**Estimated costs**: ~$1-2/month for typical test usage

### 3. Configure API Key

Set your API key as an environment variable:

```bash
# Add to your ~/.bashrc, ~/.zshrc, or ~/.profile
export OPENAI_API_KEY="sk-your-api-key-here"
```

Or create a local settings file:

```bash
cp .arbigent/settings.yaml .arbigent/settings.local.yaml
# Edit .arbigent/settings.local.yaml and add your API key
```

## Running Tests Locally

### 1. Build and Start the Web App

```bash
# Build the Flutter web app
flutter build web --release

# Start a local web server
cd build/web
python3 -m http.server 8000
```

Keep this terminal running.

### 2. Run Arbigent Tests

In a new terminal:

```bash
# Run all test scenarios
arbigent run --project-file=arbigent/project.yaml --os=web

# Run with explicit API key (if not set in environment)
arbigent run --project-file=arbigent/project.yaml --os=web \
  --ai-type=openai --openai-api-key=$OPENAI_API_KEY

# Run specific scenario
arbigent run --project-file=arbigent/project.yaml --os=web \
  --scenario=verify_app_loads

# Run with custom test URL
TEST_URL=http://localhost:3000 arbigent run \
  --project-file=arbigent/project.yaml --os=web
```

## Test Scenarios

The test suite includes the following scenarios:

1. **verify_app_loads**: Smoke test verifying the app loads and displays the main interface
2. **check_initial_state**: Verifies all summary cards show €0.00 initially
3. **add_expense_transaction**: Tests adding an expense (Musicians, €1000)
4. **verify_expense_added**: Confirms expense appears and totals are updated
5. **add_income_transaction**: Tests adding income (Event Tickets, €2500)
6. **verify_income_and_balance**: Verifies balance calculation (€1500 = €2500 - €1000)
7. **test_form_validation**: Checks that form validation works correctly
8. **delete_transaction**: Tests transaction deletion
9. **verify_transaction_deleted**: Confirms deletion and total recalculation

All scenarios are defined in `project.yaml` with dependencies to ensure proper execution order.

## Test Results

After running tests, results are stored in:

- `arbigent-results/`: Test execution results and logs
- `arbigent-screenshots/`: Screenshots taken during test execution (especially on failures)

These directories are gitignored to keep the repository clean.

## Debugging Failed Tests

When a test fails:

1. Check the console output for the specific failure reason
2. Look at screenshots in `arbigent-screenshots/` to see the UI state
3. Review the scenario goal in `project.yaml` to understand what was expected
4. Run the specific failing scenario in isolation:
   ```bash
   arbigent run --project-file=arbigent/project.yaml --os=web \
     --scenario=failing_scenario_id
   ```

## Cost Optimization Tips

To minimize API costs:

1. **Use GPT-4o-mini** instead of GPT-4o (75% cheaper, still effective):
   ```yaml
   # In .arbigent/settings.yaml
   openai_model: gpt-4o-mini
   ```

2. **Enable caching** (remembers successful actions):
   ```yaml
   enable_caching: true
   ```

3. **Run tests selectively** during development instead of the full suite

4. **Use local testing** before CI to catch issues early

## Troubleshooting

### "API key not found"
- Ensure `OPENAI_API_KEY` is set in your environment
- Or specify it directly: `--openai-api-key=sk-...`

### "Test timeout"
- Increase timeout in `project.yaml` for specific scenarios
- Check if your web app is actually running on the expected URL
- Verify network connectivity

### "Scenario failed to find element"
- AI might need a clearer description in the goal
- Check if the UI has changed significantly
- Review screenshot to see what the AI saw

### "Connection refused"
- Ensure the web app is running (`python3 -m http.server 8000`)
- Verify the TEST_URL matches your server address

## Migration from Puppeteer

The previous Puppeteer tests (`e2e_web/`) have been replaced by this Arbigent setup because:

- **Better Flutter support**: Puppeteer struggled with Flutter's canvas rendering
- **More comprehensive testing**: Arbigent tests cover full user flows, not just page loading
- **Self-healing**: AI-based tests adapt to minor UI changes automatically
- **Better debugging**: Image assertions and detailed scenarios make failures easier to diagnose

## Further Reading

- [Arbigent GitHub](https://github.com/takahirom/arbigent)
- [Arbigent Documentation](https://github.com/takahirom/arbigent#readme)
- [Introduction to Arbigent](https://medium.com/@takahirom/introducing-arbigent-an-ai-agent-testing-framework-for-modern-applications-f43a2e01d342)
