# Workflow Principles

Battle-tested principles for autonomous project execution. These apply across all projects and technology stacks.

## Research & Planning

### 1. Research Before Planning Prevents Wasted Work
Always verify current state before creating tasks. Many "fix X" or "add Y" items turn out to already exist. A thorough research phase saves entire segments of redundant implementation.

### 2. API Contracts Must Be Explicit in Plans
Frontend/backend contract mismatches are the most common source of integration bugs. Plans must specify exact request/response shapes, field names, wrapper structures, and auth requirements for every API endpoint.

### 3. Task Granularity Matters
Tasks that take <5 minutes should be consolidated with related work. But tasks that touch multiple systems should be split to maintain clear ownership. The sweet spot: one task = one coherent unit of work that can be verified independently.

## Testing & Quality

### 4. Test Infrastructure Debt Compounds Silently
Failing tests that accumulate unnoticed create a false sense of security. Run the full test suite periodically -- not just tests related to current work. Track test counts per segment to ensure coverage never regresses.

### 5. Root Causes Are Often Systemic, Not Local
When many tests fail, resist the urge to fix them individually. Look for shared root causes first: stale build artifacts, misconfigured mocks, environment drift. One systemic fix often resolves dozens of failures.

### 6. Mock Fidelity Is Critical
Mocked responses must exactly match real API contracts. Tests that pass against incorrect mocks provide false confidence. Add canary assertions early in tests to catch structural mismatches before functional assertions.

### 7. Console Error Monitoring Catches What Tests Miss
Tests can pass while the browser has runtime errors -- infinite loops, null references, unhandled rejections. All E2E tests should capture and assert on console errors.

### 8. Smoke Tests Must Include Real Interactions
A page loading successfully is not a smoke test. Meaningful smoke tests click buttons, submit forms, and verify responses against the real backend. Each feature needs at least one real interaction test.

### 9. Multi-Layer Verification Catches Different Bug Classes
- Type checking catches: compile errors, interface mismatches
- Unit tests catch: logic errors, edge cases
- Integration tests catch: query syntax, DB interaction bugs
- E2E mocked tests catch: UI flow, state management issues
- E2E smoke tests catch: API contract mismatches, auth flows, real library behavior
Skipping any layer allows that class of bugs through.

### 10. TDD Prevents Regressions During Hardening
When modifying existing behavior or adding defensive features, write the failing test first. This approach consistently results in zero regressions across large test suites.

## Execution & State Management

### 11. State File Staleness Causes Duplicate Work
Long-running agents that read state files early and write changes late can overwrite concurrent updates. Always re-read shared state files immediately before modification -- never rely on cached copies from earlier in the session.

### 12. Deviations Must Be Documented, Not Hidden
When implementation diverges from the plan, document the deviation and reasoning in the segment summary. This creates an audit trail and prevents confusion during review. Hidden deviations cause trust erosion and debugging difficulty.

### 13. Integration Points Are Where Bugs Live
The most common bug locations across projects: ID field mapping between layers, response format mismatches, query parameter type ambiguity, and mock-vs-real behavior divergence. Pay special attention to every boundary between systems.

## Architecture & Patterns

### 14. Centralize Repeated Patterns Early
When the same boilerplate appears in 3+ files, extract it immediately. Duplicated setup code (test fixtures, mock configurations, API clients) creates maintenance burden and inconsistency. One canonical implementation referenced everywhere is better than N copies.

### 15. Technology-Specific Guidance Should Be Opt-In
Projects use different stacks. Keep technology-specific pitfalls, patterns, and resources in separate, clearly-labeled files. Agent guidance should reference generic principles; the orchestrator injects technology-specific context when relevant.
