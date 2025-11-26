import puppeteer from 'puppeteer';

const TEST_URL = process.env.TEST_URL || 'http://127.0.0.1:8000';

(async () => {
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  const page = await browser.newPage();

  await page.goto(TEST_URL, { waitUntil: 'networkidle2' });

  // Wait until the Flutter app has rendered the main title
  try {
  await page.waitForFunction(() => document.body.innerText.includes('Project Finance Tracker'), { timeout: 20000 });

  // Check that summary cards exist
  const requiredLabels = ['Income', 'Expenses', 'Balance'];
  for (const label of requiredLabels) {
    const exists = await page.evaluate(l => document.body.innerText.includes(l), label);
    if (!exists) {
      throw new Error(`Missing summary label: ${label}`);
    }
  }

  console.log('E2E summary: summary cards visible with labels');
  } catch (err) {
    try { await page.screenshot({ path: 'screenshots/e2e_web_test_summary.png', fullPage: true }); } catch(_) {}
    console.error('E2E summary failed:', err?.message || err);
    await browser.close();
    process.exit(1);
  }
  await browser.close();
})();
