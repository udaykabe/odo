/**
 * Playwright globalSetup for smoke tests.
 *
 * Verifies that the backend is running and healthy before smoke tests begin.
 * Wire this into your playwright.config.ts smoke project:
 *
 *   { name: 'smoke', globalSetup: './e2e/smoke-setup.ts', ... }
 *
 * Customize:
 * - BACKEND_URL: set via environment variable or change the default
 * - HEALTH_ENDPOINT: adjust to your project's health check path
 * - maxRetries / retryDelay: tune for your backend startup time
 */

import type { FullConfig } from '@playwright/test';

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3001';
const HEALTH_ENDPOINT = '/api/v1/health';

export default async function globalSetup(_config: FullConfig): Promise<void> {
  const maxRetries = 5;
  const retryDelay = 2000;
  const url = `${BACKEND_URL}${HEALTH_ENDPOINT}`;

  for (let i = 0; i < maxRetries; i++) {
    try {
      const res = await fetch(url);
      if (res.ok) {
        console.log(`Backend healthy at ${url}`);
        return;
      }
      console.warn(`Backend returned ${res.status} at ${url}`);
    } catch {
      // Backend not ready
    }

    if (i < maxRetries - 1) {
      console.log(`Waiting for backend... (${i + 1}/${maxRetries})`);
      await new Promise(r => setTimeout(r, retryDelay));
    }
  }

  throw new Error(
    [
      `Backend not reachable at ${url} after ${maxRetries} attempts.`,
      '',
      'To start the backend:',
      '  docker compose up -d    # Start infrastructure services',
      '  npm run dev             # Start the application server',
      '',
      'Or set BACKEND_URL to point to a running instance.',
    ].join('\n')
  );
}
