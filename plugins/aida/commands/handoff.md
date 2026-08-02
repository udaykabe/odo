---
name: handoff
description: Save a context handoff when pausing, or resume work from a previous session
allowed-tools: Read, Write, Bash, Task, AskUserQuestion
---

# /handoff [save|resume]

One command for both sides of a session break.

- `/handoff save` — capture current context so work can resume cleanly later (pause).
- `/handoff resume` — restore context and continue from where you left off.
- `/handoff` (no arg) — auto-detect: if `.planning/HANDOFF.md` or `.planning/WIP.md` exists, **resume**; otherwise **save**.

---

## Mode: save

1. **Gather state** — read `.planning/WIP.md` (if present), `.planning/STATE.md`, the current `PLAN.md`, and `git status` for uncommitted/staged work.
2. **Write `.planning/HANDOFF.md`:**
   ```markdown
   # Work Handoff — [phase XX, segment XX.Y]

   ## Current Position
   - Phase / Plan / Task / Status

   ## Context
   [what was being worked on, decisions made, blockers]

   ## Uncommitted / staged changes
   [git status summary]

   ## Resume Instructions
   1. [first thing to check]
   2. [where to continue]

   ## Open Questions
   - [unresolved]
   ```
3. **Fold in WIP.md** — incorporate its task-level progress + next action, then delete `WIP.md` (its content now lives in the handoff).
4. **Update STATE.md** — add handoff reference, mark work paused.
5. **Commit reminder** — note that staged work is *not* committed (the review gate holds until reviewer `APPROVE`); do not force a commit just to pause.

**Output:** confirmation + path to `HANDOFF.md`.

---

## Mode: resume

1. **Auto-detect from git:** `git status`, `git log --oneline -10`, `git branch --show-current`. Look for `feat(XX-YY)` commits, staged/uncommitted files, branch state.
2. **Read state files (priority order):** `WIP.md` (1, highest) → `HANDOFF.md` (2) → git log (3) → git status (4) → `STATE.md` (5) → `SUMMARY-*.md` files (6).
3. **Check for stale work** — compare SUMMARY files present against STATE.md segment statuses; flag inconsistencies.
4. **Reconcile & score confidence:**
   - **HIGH** — WIP.md recent, or all sources agree, or HANDOFF matches git.
   - **MEDIUM** — minor drift (STATE one behind git).
   - **LOW** — sources conflict.
5. **Present concise resumption summary** (branch, phase, last completed segment, current task, next pending, staged changes, WIP/HANDOFF found, confidence), then the detailed position detection + any discrepancies.
6. **Confirm with user:** "Resume from Segment XX.M, or do something else?" If sources conflict, ask which to trust.
7. **Resume** — spawn the appropriate agent for the reconciled position (respect the pipeline: executor → watchdog → reviewer).
8. **Clean up** — archive `HANDOFF.md`, fix stale `STATE.md`.

**Fallback:** no HANDOFF.md → rely on git + STATE.md at lower confidence; suggest `/progress` if inconclusive.

**Output:** position detection with confidence, reconciled state, and continuation via the right agent.
