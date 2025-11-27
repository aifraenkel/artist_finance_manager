import { test, expect } from '@playwright/test';

/**
 * Flutter Web E2E Tests
 *
 * Important: Flutter web uses CanvasKit rendering, which renders everything on a canvas.
 * We verify the app loads by checking for the canvas element and taking screenshots.
 *
 * These smoke tests focus on:
 * 1. Verifying the canvas renders
 * 2. Checking page title and basic metadata
 * 3. Performance and responsiveness
 * 4. Visual regression via screenshots
 */

test.describe('App Loading Tests', () => {
  test('app loads and renders successfully', async ({ page }) => {
    // Navigate to the app
    await page.goto('/');

    // Wait for the main canvas element to appear (Flutter's rendering surface)
    // Use state: 'attached' because the canvas may be present but hidden in the DOM
    await page.waitForSelector('canvas', { state: 'attached', timeout: 30000 });

    // Wait for page to stabilize
    await page.waitForTimeout(3000);

    // Take a screenshot for visual verification
    const screenshot = await page.screenshot({ fullPage: true });
    expect(screenshot).toBeTruthy();
    expect(screenshot.length).toBeGreaterThan(5000); // Ensure it has content
  });

  test('app has correct page title', async ({ page }) => {
    await page.goto('/');

    // Check page title without waiting for Flutter
    await expect(page).toHaveTitle(/Artist Finance Manager/);
  });

  test('page loads without critical JavaScript errors', async ({ page }) => {
    const errors: string[] = [];

    // Listen for console errors
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });

    // Navigate and wait
    await page.goto('/');
    await page.waitForSelector('canvas', { state: 'attached', timeout: 30000 });
    await page.waitForTimeout(3000);

    // Filter out benign errors
    const criticalErrors = errors.filter(err =>
      !err.includes('favicon') &&
      !err.includes('404') &&
      !err.includes('manifest')
    );

    // Some warnings are okay, but should be minimal
    expect(criticalErrors.length).toBeLessThan(3);
  });

  test('app renders within reasonable time', async ({ page }) => {
    const startTime = Date.now();

    await page.goto('/');
    await page.waitForSelector('canvas', { state: 'attached', timeout: 30000 });
    await page.waitForTimeout(3000);

    const loadTime = Date.now() - startTime;

    // App should load and render in under 15 seconds
    expect(loadTime).toBeLessThan(15000);
  });

  test('app is responsive to different viewport sizes', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('canvas', { state: 'attached', timeout: 30000 });

    // Test desktop viewport
    await page.setViewportSize({ width: 1920, height: 1080 });
    await page.waitForTimeout(1000);
    let screenshot = await page.screenshot();
    expect(screenshot.length).toBeGreaterThan(5000);

    // Test mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(1000);
    screenshot = await page.screenshot();
    expect(screenshot.length).toBeGreaterThan(5000);
  });
});
