/**
 * Playwright Fixture with Automatic Error Monitoring
 *
 * This fixture extends the base Playwright test with automatic console error
 * and exception monitoring. Every test that imports from this file gets error
 * monitoring without any explicit opt-in — the `auto: true` option ensures
 * the fixture runs even if the test does not destructure `errorMonitor`.
 *
 * @example Basic usage (auto error monitoring, no explicit reference needed):
 * ```typescript
 * import { test, expect } from './fixtures/error-monitoring';
 *
 * test('my test', async ({ page }) => {
 *   await page.goto('/my-page');
 *   await page.getByRole('button').click();
 *   // errorMonitor.assertNoErrors() runs automatically after the test
 * });
 * ```
 *
 * @example Accessing the monitor to ignore expected errors:
 * ```typescript
 * test('handles error gracefully', async ({ page, errorMonitor }) => {
 *   errorMonitor.addIgnoredPattern('Expected error message');
 *   await page.goto('/page-that-logs-error');
 *   // Auto-assertion ignores the expected error
 * });
 * ```
 *
 * @example Manual mid-test assertion:
 * ```typescript
 * test('multi-step test', async ({ page, errorMonitor }) => {
 *   await page.goto('/step-1');
 *   errorMonitor.assertNoErrors('after step 1');
 *
 *   await page.goto('/step-2');
 *   errorMonitor.assertNoErrors('after step 2');
 *   // Final auto-assertion still runs at end
 * });
 * ```
 */

import { test as base, expect } from '@playwright/test';
import { ErrorMonitor, ErrorMonitorOptions, createErrorMonitor } from '../helpers/error-monitor';

/**
 * Extended test fixtures including error monitoring
 */
export type ErrorMonitoringFixtures = {
  /**
   * ErrorMonitor instance that automatically captures console errors
   * and uncaught exceptions. Auto-asserts no errors after each test.
   *
   * With `auto: true`, this fixture runs for every test even if you
   * do not explicitly reference `errorMonitor` in the test function.
   */
  errorMonitor: ErrorMonitor;

  /**
   * Options to customize error monitoring behavior.
   * Override in individual tests or test.describe blocks via `test.use()`.
   */
  errorMonitorOptions: ErrorMonitorOptions;
};

/**
 * Extended Playwright test with error monitoring fixture.
 *
 * Import this instead of `@playwright/test` to get automatic
 * runtime error detection in your tests.
 */
export const test = base.extend<ErrorMonitoringFixtures>({
  // Allow customization of error monitor options per test
  // eslint-disable-next-line no-empty-pattern
  errorMonitorOptions: [{}, { option: true }],

  // auto: true ensures this fixture runs for EVERY test, even if the test
  // function does not destructure `errorMonitor`. This is the key difference
  // from a standard fixture — no opt-in required.
  errorMonitor: [async ({ page, errorMonitorOptions }, use) => {
    const monitor = createErrorMonitor(page, errorMonitorOptions);

    // Make monitor available to test
    await use(monitor);

    // Auto-assert no errors after test completes
    // This runs even if the test itself doesn't explicitly check for errors
    monitor.assertNoErrors();
  }, { auto: true }],
});

// Re-export expect for convenience
export { expect };

// Re-export ErrorMonitor class and factory for advanced usage
export { ErrorMonitor, createErrorMonitor } from '../helpers/error-monitor';
export type { ErrorMonitorOptions, CapturedError } from '../helpers/error-monitor';
