# Common Pitfalls Reference

Quick-reference for avoiding known integration issues in AIDA-managed projects. These are technology-agnostic patterns - see `pitfalls/` directory for technology-specific details.

## Database Layer

### ID Field Mapping
Database systems often return documents with internal ID fields that differ from what frontend code expects.

**Pattern:** Always transform IDs in the API layer to match frontend expectations.

**Example:** Backend returns `_key` or `_id`, frontend expects `id`.

### Query Parameter Binding
Query languages may not interpolate bind parameters inside string literals.

**Pattern:** Use concatenation functions rather than string interpolation for building references.

### Collection/Table Prefixes
Document databases may include collection names in document handles.

**Pattern:** Be consistent about where prefixes are stripped in the data flow.

## API Layer

### Response Structure Consistency
Different endpoints may use different response wrappers, causing frontend confusion.

**Pattern:** Standardize response format across all endpoints:
- Success responses: `{ success: true, data: {} }`
- Paginated responses: `{ data: [], meta: { page, limit, total } }`
- Error responses: `{ success: false, error: string }`

### Mock Response Contracts
E2E test mocks must exactly match backend response structure.

**Pattern:** If backend returns `{ data: { user, roles } }`, mock must too - not `{ data: user }`.

**Silent failure:** Auth mocks returning wrong structure cause redirects, tests "pass" without running assertions.

### Query Parameter Types
Web frameworks may return query params as string OR array.

**Pattern:** Always handle both cases when reading query parameters.

### HTTP Status Semantics
- **404**: Resource doesn't exist
- **400**: Bad request / validation error
- **401**: Not authenticated
- **403**: Not authorized
- **500**: Actual server error (not for missing resources)

## Frontend Patterns

### Authenticated Resource Access
Direct URL access (like `window.open()`) doesn't include authentication tokens.

**Pattern:** Use fetch with headers + blob download pattern for authenticated file downloads.

### Event Handler State Staleness
Event handlers and callbacks may capture stale state from when they were created.

**Pattern:** Use refs for state that handlers need to read, or use functional state updates.

### State Array Initialization
Operations on undefined arrays crash the application.

**Pattern:** Always initialize state arrays and use defensive checks: `(items || []).map(...)`.

### Infinite Loop Detection
State management bugs can cause infinite update loops that pass all tests but crash immediately at runtime.

**Pattern:** Check if updates are actually needed before setting state. Watch for circular dependencies in effects.

## External Libraries

### Reserved Attribute Names
Some libraries reserve common attribute names internally (e.g., `type`, `id`, `data`).

**Pattern:** Check library documentation for reserved properties. Use alternative names like `itemType` or `category`.

### Mock Limitations
Mocking external libraries hides integration bugs.

**Pattern:** Document what mocks DON'T test. Ensure smoke tests exercise real library behavior.

## Error Handling

### Graceful Degradation
Non-critical service failures shouldn't block primary operations.

**Pattern:** Wrap auxiliary operations in try/catch, log failures, allow primary operation to complete.

### Runtime Configuration Sync
Configuration saved to database must be loaded into runtime registries.

**Pattern:** Always reload registries after configuration changes.

## Testing Patterns

### Console Error Monitoring
Unit tests and mocked E2E tests don't catch runtime errors.

**Pattern:** Add console error monitoring to ALL E2E tests, fail test if errors detected.

### Page Load vs Interaction Tests
Page load tests are NOT sufficient smoke tests.

**Pattern:** Smoke tests must include real user interactions - clicks, form submissions, data verification.

### Silent Test Failures
Tests that redirect on failure appear to "pass" without running assertions.

**Pattern:** Add early "canary" assertions that fail fast if setup is broken.

---

## State File Management

### Stale Context Overwrites
Long-running agents may read state files early and write changes later, overwriting concurrent updates.

**Pattern:** Always re-read state files immediately before editing, not at task start.

**Example bug:** An agent may read STATE.md early in a long-running session and make decisions based on stale data. When it finally writes updates, it overwrites changes made by other agents in the interim.

### Append vs Replace
When adding information to state files, append new sections rather than replacing existing data.

**Pattern:**
- Add new sections (spikes, accomplishments) at the end
- Only modify "Current Position" when specifically updating phase status
- Use `git diff` before commit to verify changes

---

## Technology-Specific References

See the `pitfalls/` directory for detailed examples:
- `pitfalls/arangodb.md` - ArangoDB-specific issues
- `pitfalls/express.md` - Express.js-specific issues
- `pitfalls/react.md` - React-specific issues
- `pitfalls/playwright.md` - Playwright/E2E testing issues
