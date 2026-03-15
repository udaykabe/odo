# Playwright & E2E Testing Pitfalls

Common issues when using Playwright and E2E testing in AIDA-managed projects.

## Mock Response Structure Mismatch

**Problem:** E2E test mocks don't match the exact backend response structure, causing silent auth failures or data access errors.

**Solution:** Ensure mock responses exactly match backend contracts:

```typescript
// WRONG - missing nested structure
route.fulfill({
  body: JSON.stringify({
    success: true,
    data: user  // Frontend accesses response.data.user which is undefined!
  })
});

// CORRECT - matches exact backend structure
route.fulfill({
  body: JSON.stringify({
    success: true,
    data: {
      user: user,
      roles: user.roles.map(r => r.name),
      permissions: user.permissions
    }
  })
});
```

**Why it matters:** Auth fails silently, redirects to login, test assertions never run but test "passes".

## Silent Auth Failure Detection

**Problem:** Tests appear to pass but are actually failing silently due to authentication issues.

**Solution:** Add auth canary assertions early in tests:

```typescript
await page.goto('/protected-page');
await expect(page).not.toHaveURL(/login/);  // Fails fast if auth broken
```

## Missing Console Error Monitoring

**Problem:** E2E tests don't detect JavaScript console errors, allowing runtime bugs to slip through.

**Solution:** Add console error monitoring to ALL E2E tests:

```typescript
// In test setup or fixture
const errors: string[] = [];
test.beforeEach(async ({ page }) => {
  page.on('console', msg => {
    if (msg.type() === 'error') errors.push(msg.text());
  });
});
test.afterEach(async () => {
  expect(errors, 'Console errors detected').toEqual([]);
});
```

## Page Load vs Real Interaction Tests

**Problem:** Smoke tests that only verify page loads don't catch interaction bugs.

**Solution:** Ensure smoke tests include real user interactions:

```typescript
// WRONG - only tests page load
test('notes page loads', async ({ page }) => {
  await page.goto('/notes');
  await expect(page).toHaveURL('/notes');
});

// CORRECT - tests real interaction
test('can create and view a note', async ({ page }) => {
  await page.goto('/notes');
  await page.click('[data-testid="new-note"]');
  await page.fill('[data-testid="note-title"]', 'Test Note');
  await page.click('[data-testid="save-note"]');
  await expect(page.locator('[data-testid="note-list"]')).toContainText('Test Note');
});
```

## Duplicated Mock Setup

**Problem:** Each test file duplicates mock setup, making maintenance difficult and allowing inconsistencies.

**Solution:** Centralize mock setup:

- Use fixtures for common mock patterns
- Consider MSW (Mock Service Worker) for centralized API mocking
- Create shared mock data factories

```typescript
// fixtures/mocks.ts
export const mockAuthResponse = (user: User) => ({
  success: true,
  data: { user, roles: user.roles.map(r => r.name), permissions: [] }
});

// In test
await page.route('**/auth/me', route => {
  route.fulfill({ body: JSON.stringify(mockAuthResponse(testUser)) });
});
```

## Flaky Tests from Race Conditions

**Problem:** Tests pass locally but fail in CI due to timing issues.

**Solution:** Use proper wait strategies instead of arbitrary delays:

```typescript
// WRONG - arbitrary timeout
await page.waitForTimeout(1000);

// CORRECT - wait for specific condition
await page.waitForSelector('[data-testid="loaded"]');
await expect(page.locator('.spinner')).toBeHidden();
```

## Test Isolation

**Problem:** Tests affect each other through shared state or database.

**Solution:**
- Use fresh browser contexts per test (Playwright default)
- Reset database state before each test or test suite
- Avoid relying on data created by other tests

## Network Request Assertions

**Problem:** Tests don't verify that expected API calls were made.

**Solution:** Use request interception to verify API calls:

```typescript
const apiCalled = page.waitForRequest(req =>
  req.url().includes('/api/save') && req.method() === 'POST'
);
await page.click('[data-testid="save"]');
await apiCalled; // Fails if API wasn't called
```

## Backend Readiness for Smoke Tests

Smoke tests require a running backend. Without an automated check, tests fail with confusing connection errors.

### Pattern: globalSetup Health Check

Create a `globalSetup` script for the smoke project that verifies backend health before any tests run:

```typescript
// e2e/smoke-setup.ts
import { FullConfig } from '@playwright/test';

export default async function globalSetup(config: FullConfig) {
  const backendUrl = process.env.BACKEND_URL || 'http://localhost:3001';
  const maxRetries = 5;
  const retryDelay = 2000;

  for (let i = 0; i < maxRetries; i++) {
    try {
      const res = await fetch(`${backendUrl}/api/v1/health`);
      if (res.ok) return;
    } catch {
      // Backend not ready yet
    }
    if (i < maxRetries - 1) {
      console.log(`Waiting for backend... (attempt ${i + 1}/${maxRetries})`);
      await new Promise(r => setTimeout(r, retryDelay));
    }
  }

  throw new Error(
    `Backend not reachable at ${backendUrl}/api/v1/health after ${maxRetries} attempts.\n` +
    `Start it with: docker compose up -d && npm run dev (or your project's startup command)`
  );
}
```

Wire it in playwright.config.ts:

```typescript
{
  name: 'smoke',
  testMatch: /smoke.*\.spec\.ts/,
  globalSetup: './e2e/smoke-setup.ts',
  use: { baseURL: 'http://localhost:3000' },
}
```

### Why This Matters

Without this check, a developer running `npx playwright test --project=smoke` without the backend gets dozens of `net::ERR_CONNECTION_REFUSED` errors across all tests. The globalSetup fails once with a clear message and actionable instructions.

## Database Seeding Strategy

Smoke tests that verify data existence (e.g., "library shows N documents") depend on a known database state. Without seeding, tests are non-reproducible.

### Approaches

**1. Seed script in globalSetup** (recommended for small datasets):

```typescript
// In smoke-setup.ts, after health check passes
const seedRes = await fetch(`${backendUrl}/api/v1/test/seed`, {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${adminToken}` },
});
```

**2. SQL/migration-based seeding** (recommended for complex data):

```bash
# Run seed script before smoke tests
npm run db:seed:test && npx playwright test --project=smoke
```

**3. Test-created data** (recommended for mutation tests):

Each test creates its own data, verifies it, then cleans up:

```typescript
test('can create and delete a note', async ({ page }) => {
  // Create
  await page.getByRole('button', { name: 'New Note' }).click();
  await page.getByRole('textbox').fill('Test note');
  await page.getByRole('button', { name: 'Save' }).click();
  await expect(page.getByText('Test note')).toBeVisible();

  // Cleanup
  await page.getByRole('button', { name: 'Delete' }).click();
  await page.getByRole('button', { name: 'Confirm' }).click();
});
```

### Test Isolation Rules

- Smoke tests run serially (`test.describe.serial`) to avoid race conditions
- Each test should leave the database in the same state it found it
- If a test creates data, it must clean up — or the test suite must tolerate accumulated data
- Never depend on data created by a previous test unless both are in the same serial describe block

## Debugging Failing Tests

### Headed Mode

Run tests with a visible browser:

```bash
npx playwright test --headed                    # All tests
npx playwright test --headed smoke.spec.ts      # Specific file
```

### Playwright Inspector

Step through tests interactively:

```bash
npx playwright test --debug                     # Opens Inspector
npx playwright test --debug smoke.spec.ts       # Specific file
```

The Inspector lets you step through each action, inspect selectors, and see the page state at each point.

### Trace Viewer

When `trace: 'on-first-retry'` is configured (recommended default), Playwright captures a trace on the first retry of a failing test:

```bash
npx playwright show-trace test-results/test-name/trace.zip
```

The trace viewer shows: screenshots at each step, DOM snapshots, network requests, console logs, and action timing.

### Interactive Pause

Add `await page.pause()` anywhere in a test to pause execution and open the Inspector at that point:

```typescript
test('debug this flow', async ({ page }) => {
  await page.goto('/dashboard');
  await page.pause();  // Browser pauses here — inspect manually
  await page.getByRole('button', { name: 'Submit' }).click();
});
```

Remove `page.pause()` before committing.

### HTML Report

After a test run, view the detailed report:

```bash
npx playwright show-report
```

Shows: pass/fail per test, duration, screenshots on failure, trace links.

### Video Recording

For CI debugging, enable video capture:

```typescript
// playwright.config.ts
use: {
  video: 'on-first-retry',  // Records video on first retry of failing tests
}
```

### Common Troubleshooting

| Problem | Solution |
|---------|----------|
| "Browser not installed" | `npx playwright install chromium` |
| "Port already in use" | Kill the process: `lsof -ti:3000 \| xargs kill` |
| "Stale auth state" | Delete the storage state file: `rm e2e/.auth/` |
| "Element not found" | Check if the element renders after async data load — use `await expect(...).toBeVisible()` instead of immediate assertions |
| "Timeout exceeded" | Increase specific timeout: `await expect(el).toBeVisible({ timeout: 10000 })`. Do NOT increase global timeout — diagnose the root cause. |

## Anti-Pattern: Conditional Assertions

### The Problem

```typescript
// DANGEROUS — test passes even if the feature is completely broken
if (await page.getByText('Submit').isVisible({ timeout: 2000 }).catch(() => false)) {
  await page.getByText('Submit').click();
  await expect(page.getByText('Success')).toBeVisible();
}
// If 'Submit' never appears, the test passes with zero assertions
```

When a test conditionally skips its core assertion because an element is not found, it provides **false confidence**. The test "passes" but tested nothing.

### Correct Patterns

**1. Assert the element exists (fail if missing):**

```typescript
await expect(page.getByText('Submit')).toBeVisible();
await page.getByText('Submit').click();
await expect(page.getByText('Success')).toBeVisible();
```

**2. Skip explicitly with a reason:**

```typescript
const submitButton = page.getByText('Submit');
if (!(await submitButton.isVisible({ timeout: 2000 }).catch(() => false))) {
  test.skip(true, 'Submit button not rendered — feature may not be deployed');
  return;
}
await submitButton.click();
```

**3. Use `test.fixme()` for known broken tests:**

```typescript
test.fixme('submit flow is broken due to API migration');
```

### Rule

Every smoke test must make at least one assertion. A test with zero assertions is worse than no test — it occupies a slot in the suite while providing no signal.

## Timeout Strategy

### Default Timeouts

Playwright provides three timeout layers:

| Timeout | Default | Controls |
|---------|---------|----------|
| Test timeout | 30s | Total time for the entire test |
| Action timeout | 0 (none) | Individual actions (click, fill, etc.) |
| Expect timeout | 5s | `expect(...).toBeVisible()` and similar |

### Guidelines

- **Do NOT increase global timeouts** to fix flaky tests. Diagnose the root cause.
- **Per-assertion overrides** are acceptable for known slow operations:
  ```typescript
  await expect(page.getByText('Results')).toBeVisible({ timeout: 10000 }); // Search is slow
  ```
- **Smoke tests may need longer timeouts** than mocked E2E tests because they wait for real backend responses. Set smoke project timeout to 60s in playwright.config.ts:
  ```typescript
  { name: 'smoke', timeout: 60000, ... }
  ```
- **Never use `page.waitForTimeout(N)`** (arbitrary sleep). Use `expect` with a condition or `page.waitForResponse()` for specific network events.

## Multi-Browser Testing

### Default: Chromium Only

Most projects start with Chromium-only testing. This is a deliberate trade-off:
- Chromium covers ~65% of browser market share
- Single-browser tests run 3x faster than three-browser suites
- Most rendering bugs are CSS-related, not browser-specific

### When to Add Firefox/WebKit

Add additional browsers when:
- The application uses browser-specific APIs (WebRTC, Web Speech, File System Access)
- Users report browser-specific bugs
- The application targets Safari/iOS users (WebKit)

### Configuration

```typescript
// playwright.config.ts
projects: [
  { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
  { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  // Mobile
  { name: 'mobile-chrome', use: { ...devices['Pixel 5'] } },
  { name: 'mobile-safari', use: { ...devices['iPhone 13'] } },
]
```

### Headless vs Headed

- **Headless (default):** Used in CI and automated runs. No visible browser window.
- **Headed (`--headed`):** Used for local debugging. Shows the browser.
- Both modes use the same Chromium/Firefox/WebKit binaries — behavior is identical except for GPU compositing edge cases.
