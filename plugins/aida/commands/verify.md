---
name: verify
description: "Run verification suite from PROJECT.md commands. Args: quick | smoke"
allowed-tools: Bash, Read, Grep
---

# /verify [quick|smoke]

Run verification using commands declared in `.planning/PROJECT.md`. Accepts an optional argument to select verification level (default: full).

## Verification Levels

| Level | When to Use | What Runs |
|-------|-------------|-----------|
| **Quick** | During development | Type check + unit tests |
| **Full** | Phase completion (default) | Type check + lint + unit tests + E2E tests |
| **Smoke** | Before marking complete | Full + smoke tests (real backend) |

## Process

### 1. Read verification commands

Read `.planning/PROJECT.md` and extract the `## Verification Commands` table. Each row maps a check name to a shell command.

If no `## Verification Commands` section is found:
- Warn the user: "No verification commands found in PROJECT.md. Run `/new-project` or add a `## Verification Commands` table to `.planning/PROJECT.md` manually."
- Abort verification.

### 2. Map commands to levels

| Check | Quick | Full | Smoke |
|-------|-------|------|-------|
| Type check | yes | yes | yes |
| Lint | -- | yes | yes |
| Unit tests | yes | yes | yes |
| Integration tests | -- | yes | yes |
| E2E tests | -- | yes | yes |
| Smoke tests | -- | -- | yes |
| Build | -- | -- | -- |

Build is not run during verification by default. It can be run manually.

### 3. Execute commands in order

For each command applicable to the selected level:
1. Skip if the command value is blank, `not configured`, or missing from the table
2. Print the check name as a header
3. Run the command
4. Record PASS or FAIL

### 4. Report results

```
=== AIDA VERIFY ([level]) ===

--- [Check Name] ---
[command output]
Result: PASS|FAIL

--- [Check Name] ---
[command output]
Result: PASS|FAIL|SKIP (not configured)

=== SUMMARY ===
[Check]: PASS|FAIL|SKIP
[Check]: PASS|FAIL|SKIP
...

OVERALL: PASS|FAIL
```

OVERALL is PASS only if all executed checks pass. Skipped checks do not cause failure.

## Usage

| Invocation | Level | What Runs |
|------------|-------|-----------|
| `/verify` | Full | Type check + lint + unit tests + integration + E2E |
| `/verify quick` | Quick | Type check + unit tests only |
| `/verify smoke` | Smoke | Full + smoke tests (real backend required) |

- **Quick**: Use during development and at mid-segment checkpoints
- **Full** (default): Use before committing phase work
- **Smoke**: Use before marking a phase complete (BLOCKING requirement)

## Phase Completion Checklist

Before marking a phase complete, verify ALL configured checks pass:

1. `/verify smoke` -- runs all tiers including smoke tests
2. If smoke tests are not configured, `/verify` (full) is sufficient

**Critical:** Smoke tests, when configured, are BLOCKING. Do not mark phase complete if smoke tests fail.

## E2E Test Quality Requirements

*Only applicable if E2E testing is configured for this project.*

1. **All E2E tests must monitor console errors** -- both mocked and smoke tests
2. **Smoke tests must test real interactions**, not just page loads
3. **Mock responses must match exact API contract** -- see `common-pitfalls.md`
