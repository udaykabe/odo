# GTI E2E Testing Resources

Reusable E2E testing infrastructure for Playwright projects.

## Contents

### helpers/error-monitor.ts

ErrorMonitor class that captures console errors and uncaught exceptions during E2E tests.

**Features:**
- Captures `console.error` and `pageerror` events
- Built-in ignored patterns for common framework noise (React, Vite, Next.js, WebSocket)
- Regex pattern support for broader matching
- `assertNoErrors()` method for test assertions
- `addIgnoredPattern()` with method chaining
- Customizable ignore patterns (per-test or per-describe)

### fixtures/error-monitoring.ts

Playwright fixture that auto-applies error monitoring to **every** test using `auto: true`.

**Features:**
- Runs automatically for every test — no explicit opt-in required
- Auto-asserts no errors after each test
- Drop-in replacement for `@playwright/test` imports
- Customizable options via `test.use()`

### smoke-setup.ts

Playwright `globalSetup` script for smoke test projects. Verifies the backend is running and healthy before any smoke tests execute.

**Features:**
- Configurable backend URL and health endpoint
- Retry logic with clear failure messages
- Actionable startup instructions on failure

## Usage

### 1. Copy to Your Project

Copy these files to your project's e2e directory:
```bash
cp -r .claude/skills/orchestrating-agents/resources/e2e/helpers/ <project-e2e-dir>/helpers/
cp -r .claude/skills/orchestrating-agents/resources/e2e/fixtures/ <project-e2e-dir>/fixtures/
cp .claude/skills/orchestrating-agents/resources/e2e/smoke-setup.ts <project-e2e-dir>/smoke-setup.ts
```

### 2. Update Test Imports

Replace:
```typescript
import { test, expect } from '@playwright/test';
```

With:
```typescript
import { test, expect } from './fixtures/error-monitoring';
```

### 3. Tests Auto-Fail on Console Errors

Because the fixture uses `auto: true`, every test gets error monitoring without any changes to the test function signature. You do **not** need to destructure `errorMonitor` unless you want to add ignored patterns or assert mid-test.

```typescript
// This test gets automatic error monitoring — no explicit opt-in:
test('dashboard loads', async ({ page }) => {
  await page.goto('/dashboard');
  await expect(page.getByRole('heading')).toBeVisible();
  // assertNoErrors() runs automatically after this test
});

// Opt in to the monitor only when you need to customize it:
test('handles known error', async ({ page, errorMonitor }) => {
  errorMonitor.addIgnoredPattern('Expected deprecation warning');
  await page.goto('/legacy-page');
});
```

### 4. Wire Up Smoke Setup

In your `playwright.config.ts`, point the smoke project to the globalSetup script:

```typescript
{
  name: 'smoke',
  testMatch: /smoke.*\.spec\.ts/,
  globalSetup: './e2e/smoke-setup.ts',
  use: { baseURL: 'http://localhost:3000' },
  timeout: 60000,
}
```

## Customizing Ignore Patterns

### Framework-Specific vs Project-Specific

The default ignored patterns in `error-monitor.ts` cover common framework noise (React, Vite, Next.js). When you adopt the template:

1. **Remove patterns for frameworks you don't use.** If your project doesn't use Next.js, delete the Next.js section from DEFAULT_IGNORED_PATTERNS.

2. **Add project-specific patterns via options, not by editing defaults.** Library-specific errors (e.g., Sigma.js canvas errors, D3 rendering warnings) should be added through `ignoredPatterns` in your project's fixture or individual tests.

```typescript
// Per-describe: all tests in this block ignore graph library errors
test.describe('Graph visualization', () => {
  test.use({
    errorMonitorOptions: {
      ignoredPatterns: [
        'Cannot read properties of null',  // Canvas not mounted yet
        /sigma/i,                           // Sigma.js internal errors
      ],
    },
  });

  test('renders graph', async ({ page }) => { /* ... */ });
});
```

### Per-Test Ignored Patterns

```typescript
test('expects specific error', async ({ page, errorMonitor }) => {
  errorMonitor.addIgnoredPattern('Expected error message');
  await page.goto('/page-with-expected-error');
});
```

### Manual Assertion Mid-Test

```typescript
test('multi-step flow', async ({ page, errorMonitor }) => {
  await page.goto('/step-1');
  errorMonitor.assertNoErrors('after step 1');

  await page.click('#next');
  errorMonitor.assertNoErrors('after step 2');
});
```

## Verifying Adoption

Ensure all spec files import from the error-monitoring fixture rather than `@playwright/test`:

```bash
# Files that bypass error monitoring (should be empty):
grep -rL "fixtures/error-monitoring" e2e/*.spec.ts
```

If any files are found, update their imports:

```typescript
// Before (no error monitoring):
import { test, expect } from '@playwright/test';

// After (with auto error monitoring):
import { test, expect } from './fixtures/error-monitoring';
```

You can also verify that no spec files directly import from `@playwright/test`:

```bash
# Should return no results for spec files:
grep -r "from '@playwright/test'" e2e/*.spec.ts
```

Note: helper files and fixtures themselves will legitimately import from `@playwright/test` — only spec files need to use the fixture.

## Why This Matters

Without error monitoring, tests can "pass" while the page has runtime errors:
- Infinite loops that don't crash the page but degrade performance
- Null reference errors logged to console
- Failed API calls that the test doesn't assert on
- Framework warnings that indicate real problems (e.g., state updates after unmount)

With error monitoring via `auto: true`, these failures are caught in CI before reaching UAT — and no test can accidentally skip the check by forgetting to destructure the fixture.

## API Reference

### ErrorMonitor Class

```typescript
import { createErrorMonitor } from './helpers/error-monitor';

const monitor = createErrorMonitor(page, {
  ignoredPatterns: ['Expected error'],  // Optional: additional patterns to ignore
  captureWarnings: false,               // Optional: also capture console.warn
});

// Get captured errors
monitor.getErrors();

// Check if errors exist
monitor.hasErrors();

// Assert no errors (throws if errors found)
monitor.assertNoErrors('context message');

// Clear captured errors
monitor.clear();

// Add pattern to ignore at runtime (supports chaining)
monitor
  .addIgnoredPattern('some string')
  .addIgnoredPattern(/some-regex/);
```

### Default Ignored Patterns

These errors are ignored by default (organized by framework):

**Universal:**
- `favicon` — Favicon loading errors
- `net::ERR_CONNECTION_REFUSED` — Expected in error state tests

**WebSocket:**
- `WebSocket connection failed` — Dev server WebSocket errors
- `/WebSocket connection to .* failed/` — Browser-format WebSocket errors
- `[ws] WebSocket error` — Generic WebSocket client errors

**React:**
- `Hydration failed` — React dev mode hydration warnings
- `Cannot update a component` — State update during render warnings

**Vite:**
- `[vite]` — Vite HMR messages

**Next.js** (remove if not using Next.js):
- `Failed to fetch RSC payload` — RSC navigation errors in dev
- `Falling back to browser navigation` — Internal navigation fallback
- `fetchServerResponse` — Client-side navigation errors
