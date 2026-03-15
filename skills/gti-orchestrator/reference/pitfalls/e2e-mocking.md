# E2E Mocking Pitfalls

## Problem: Duplicated Mock Setup

When each test file defines its own mock responses, issues compound:
- API contract changes require updating every mock file
- Same mock bug in all files goes undetected
- No single source of truth for API shapes

## Solution: Centralized Mock Server

Use a centralized mock approach (e.g., MSW - Mock Service Worker, or a shared mock setup helper).

### Pattern

```
tests/
  mocks/
    handlers.ts        # Single source of truth for all API mocks
    server.ts          # MSW server setup (or custom mock server)
    fixtures/          # Reusable response data
      users.json
      documents.json
  e2e/
    feature.spec.ts    # Tests import from shared mocks
```

### Key Rules

1. **One mock per endpoint** -- Define each API mock once in `handlers.ts`
2. **Override per-test** -- Tests override specific handlers when needed, not the entire mock setup
3. **Fixtures match contracts** -- Mock response shapes must be validated against actual API contracts
4. **Canary assertions** -- Each test should assert on response structure (not just values) to catch contract drift early

### Anti-Patterns

- Copy-pasting mock setup across test files
- Mocking at the component level when testing integration flows
- Mock responses that don't match the actual API wrapper structure (e.g., `{ data: [...] }` vs bare arrays)

### When the Orchestrator Should Inject This

Provide this guidance to executors when:
- The task involves setting up E2E test infrastructure
- The plan includes adding E2E tests to a project for the first time
- Test failures are caused by inconsistent mock responses
