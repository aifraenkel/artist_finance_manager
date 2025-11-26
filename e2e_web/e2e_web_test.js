import puppeteer from 'puppeteer';

const TEST_URL = process.env.TEST_URL || 'http://127.0.0.1:8000';

(async () => {
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  const page = await browser.newPage();
  page.on('console', msg => {
    // Log console messages to aid debugging in CI
    try {
      console.log('[browser]', msg.type().toUpperCase(), msg.text());
    } catch (e) {
      console.log('[browser]', msg.text());
    }
  });

  await page.goto(TEST_URL, { waitUntil: 'networkidle2' });

  // Wait for Flutter to attach by looking for a known text from the app
  // Title expected from home screen
  try {
  await page.waitForFunction(() => {
    return !!document && !!document.body && document.body.innerText.includes('Project Finance Tracker');
  }, { timeout: 20000 });

  // Also ensure the spinner is removed
  const loadingGone = await page.$('.loading') === null;
  if (!loadingGone) {
    throw new Error('Spinner element still present after app load');
  }

  console.log('E2E smoke: app loaded and UI visible');
  } catch (err) {
    try {
      await page.screenshot({ path: 'screenshots/e2e_web_test_smoke.png', fullPage: true });
    } catch (_) {}
    console.error('E2E smoke failed:', err?.message || err);
    await browser.close();
    process.exit(1);
  }
  await browser.close();
})();
