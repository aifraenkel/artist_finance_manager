import puppeteer from 'puppeteer-core';

(async () => {
  // Change this path if your Chrome is elsewhere
  const chromePath = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

  const browser = await puppeteer.launch({
    headless: true,
    executablePath: chromePath,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  try {
    const page = await browser.newPage();
    const logs = [];

    page.on('console', msg => {
      const text = `${msg.type().toUpperCase()}: ${msg.text()}`;
      logs.push(text);
      console.log(text);
    });

    page.on('pageerror', err => {
      const text = `PAGE ERROR: ${err.message}`;
      logs.push(text);
      console.error(text);
    });

    page.on('requestfailed', req => {
      const text = `REQUEST FAILED: ${req.url()} (${req.failure().errorText})`;
      logs.push(text);
      console.error(text);
    });

    page.on('response', res => {
      const status = res.status();
      if (status >= 400) {
        const text = `RESPONSE ${status}: ${res.url()}`;
        logs.push(text);
        console.error(text);
      }
    });

    console.log('Opening http://127.0.0.1:8000');

    const resp = await page.goto('http://127.0.0.1:8000', {waitUntil: 'networkidle2', timeout: 20000});
    console.log('Initial response status:', resp && resp.status());

    // Wait a few seconds to capture async errors
    await new Promise((resolve) => setTimeout(resolve, 8000));

    console.log('\n=== Console / Networking Log (tail) ===');
    if (logs.length === 0) {
      console.log('No console messages captured.');
    } else {
      logs.slice(-200).forEach(l => console.log(l));
    }

    // Try to capture some DOM check: does the spinner still exist?
    const spinnerExists = await page.evaluate(() => !!document.querySelector('.spinner') || !!document.querySelector('div[role="progressbar"]'));
    console.log('\nSpinner present after 8s:', spinnerExists);

    // Also detect whether Flutter's app is attached to window.flutter
    const flutterAttached = await page.evaluate(() => !!window.flutter || !!window.flutterApp || !!document.querySelector('#flutter-root'));
    console.log('Flutter presence check:', flutterAttached);

    // Dump the first 800 chars of main.dart.js to ensure it's loaded
    // Do not navigate away from the index page; instead inspect its DOM directly.
    // Check for typical Flutter DOM elements that appear when the engine initializes.
    const hasFltGlassPane = await page.evaluate(() => !!document.querySelector('flt-glass-pane'));
    const hasFltPlatformView = await page.evaluate(() => !!document.querySelector('flt-platform-view'));
    // Count all canvas elements, including those inside shadow roots.
    const canvasCount = await page.evaluate(() => {
      function countCanvases(node) {
        let count = 0;
        if (node.nodeType === Node.ELEMENT_NODE && node.tagName.toLowerCase() === 'canvas') count++;
        // count in children
        for (const child of node.children) count += countCanvases(child);
        // count in shadowRoot if exists
        if (node.shadowRoot) count += countCanvases(node.shadowRoot);
        return count;
      }
      return countCanvases(document);
    });
    const fltChildCount = await page.evaluate(() => {
      const e = document.querySelector('flt-glass-pane');
      return e ? e.childElementCount : 0;
    });
    const spinnerVisible = await page.evaluate(() => {
      const s = document.querySelector('.spinner');
      if (!s) return false;
      const style = window.getComputedStyle(s);
      return style && style.display !== 'none' && style.visibility !== 'hidden' && s.getBoundingClientRect().height > 0;
    });
    console.log('Has <flt-glass-pane>?:', hasFltGlassPane);
    console.log('Has <flt-platform-view>?:', hasFltPlatformView);
    console.log('Canvas elements found:', canvasCount);
    console.log('Children inside <flt-glass-pane>:', fltChildCount);
    console.log('Spinner visible after 8s (computed):', spinnerVisible);
    const bodySnapshot = await page.evaluate(() => (document.body && document.body.innerHTML || '').slice(0, 1600));
    console.log('\nBody snapshot (first 1600 chars):\n', bodySnapshot);

    // Take a screenshot for visual inspection
    try {
      const outPath = '../../build/web/headless_screenshot.png';
      await page.screenshot({ path: outPath, fullPage: true });
      console.log('Saved screenshot to', outPath);
    } catch (sErr) {
      console.error('Screenshot failed:', sErr && sErr.message);
    }

  } catch (err) {
    console.error('Error during headless run:', err);
    process.exitCode = 2;
  } finally {
    await browser.close();
  }
})();
