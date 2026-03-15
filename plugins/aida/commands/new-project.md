---
name: new-project
description: Initialize a new AIDA project with PROJECT.md and planning structure
allowed-tools: Read, Write, Glob, Task, AskUserQuestion
---

# /new-project

Initialize a new project with AIDA workflow.

## Process

1. **Check for existing project**
   - Look for `.planning/PROJECT.md`
   - If exists, confirm overwrite or abort

2. **Detect project type**
   - Check for existing code (brownfield)
   - Empty/minimal codebase (greenfield)

3. **Gather project context**

   Ask user for:
   - Project name
   - One-sentence description
   - Primary goal/outcome
   - Key constraints (timeline, tech, etc.)

4. **For brownfield projects**
   - Spawn `researcher` to map existing codebase
   - Create `.planning/codebase/` analysis docs

5. **Create planning structure**
   ```
   .planning/
   ├── PROJECT.md      # Project vision
   ├── ROADMAP.md      # Empty, ready for phases
   ├── STATE.md        # Initial state
   ├── ISSUES.md       # Empty issues log
   └── phases/         # Empty phases directory
   ```

6. **Write PROJECT.md**
   ```markdown
   # [Project Name]

   ## Vision
   [One paragraph description]

   ## Goals
   - [Primary goal]
   - [Secondary goals]

   ## Constraints
   - [Timeline]
   - [Technology]
   - [Other limits]

   ## Success Criteria
   - [How we know we're done]
   ```

7. **Ask for verification commands**

   Ask the user:
   ```
   What commands should be used for verification? (Leave blank if not yet set up)

   Type checking: [e.g., npx tsc --noEmit, mypy ., cargo check]
   Unit tests: [e.g., npm test, pytest, cargo test, go test ./...]
   Linting: [e.g., npm run lint, ruff check ., cargo clippy]
   E2E tests: [e.g., npx playwright test, cypress run]
   Smoke tests: [e.g., npx playwright test --project=smoke]
   Build: [e.g., npm run build, cargo build, go build ./...]
   ```

   Write these to PROJECT.md under a `## Verification Commands` section:

   ```markdown
   ## Verification Commands

   | Check | Command |
   |-------|---------|
   | Type check | `npx tsc --noEmit` |
   | Unit tests | `npm test` |
   | Lint | `npm run lint` |
   | E2E tests | `npx playwright test` |
   | Smoke tests | `npx playwright test --project=smoke` |
   | Build | `npm run build` |

   *Update these as your project's tooling evolves.*
   ```

   Use `not configured` for any command the user leaves blank.

8. **Initialize STATE.md**
   ```markdown
   # Project State

   ## Current Position
   - Phase: None (project initialized)
   - Status: Ready for roadmap

   ## Decisions
   [None yet]

   ## Context
   Initialized: [timestamp]
   ```

## Output

Confirmation of project initialization with next step suggestion.
