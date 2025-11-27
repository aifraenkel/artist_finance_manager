import { test, expect } from '@playwright/test';

/**
 * Flutter Web Transaction Flow Tests
 *
 * Note: These tests are limited because Flutter web uses canvas rendering.
 * We focus on smoke testing: verifying the app stays responsive and doesn't crash.
 *
 * For detailed user interaction testing, use Flutter integration tests (integration_test/).
 */

test.describe('Transaction Flow Smoke Tests', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate and wait for Flutter canvas to be ready
    await page.goto('/');
    await page.waitForSelector('canvas', { state: 'attached', timeout: 30000 });
    await page.waitForTimeout(3000);
  });

  test('app maintains rendering after user interaction', async ({ page }) => {
    // Take initial screenshot
    const before = await page.screenshot();
    expect(before.length).toBeGreaterThan(5000);

    // Simulate user interaction (click middle of screen)
    await page.mouse.click(640, 360);
    await page.waitForTimeout(500);

    // Verify app is still rendered
    const after = await page.screenshot();
    expect(after.length).toBeGreaterThan(5000);
  });

  test('app handles viewport resize without crashing', async ({ page }) => {
    // Start with desktop size
    await page.setViewportSize({ width: 1280, height: 720 });
    await page.waitForTimeout(500);
    let screenshot = await page.screenshot();
    expect(screenshot.length).toBeGreaterThan(5000);

    // Resize to mobile
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(500);
    screenshot = await page.screenshot();
    expect(screenshot.length).toBeGreaterThan(5000);

    // Resize back
    await page.setViewportSize({ width: 1280, height: 720 });
    await page.waitForTimeout(500);
    screenshot = await page.screenshot();
    expect(screenshot.length).toBeGreaterThan(5000);
  });

  test('multiple interactions do not cause crashes', async ({ page }) => {
    const errors: string[] = [];

    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });

    // Perform several clicks
    await page.mouse.click(400, 300);
    await page.waitForTimeout(200);

    await page.mouse.click(640, 400);
    await page.waitForTimeout(200);

    await page.mouse.click(400, 600);
    await page.waitForTimeout(200);

    // Verify app still renders
    const screenshot = await page.screenshot();
    expect(screenshot.length).toBeGreaterThan(5000);

    // Check for critical errors
    const criticalErrors = errors.filter(err =>
      !err.includes('favicon') && !err.includes('404') && !err.includes('manifest')
    );
    expect(criticalErrors.length).toBeLessThan(3);
  });

  test('visual consistency - app renders stable content', async ({ page }) => {
    // Take two screenshots with a small delay
    const screenshot1 = await page.screenshot();
    await page.waitForTimeout(1000);
    const screenshot2 = await page.screenshot();

    // Sizes should be very similar (within 10% - allows for minor timing differences)
    const sizeDiff = Math.abs(screenshot1.length - screenshot2.length);
    const maxDiff = screenshot1.length * 0.10;

    expect(sizeDiff).toBeLessThan(maxDiff);
  });
});
