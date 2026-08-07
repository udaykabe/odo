---
name: execute
description: Execute the current approved plan
allowed-tools: Read, Write, Task, AskUserQuestion
---

# /execute

Execute the currently approved plan using sub-agents.

## Process

1. **Load current plan**
   - Read STATE.md for current plan path
   - Parse PLAN.md for tasks and segments

2. **Segment analysis**

   Break plan into segments at checkpoints:
   ```
   Segment 1: Tasks 1-3 (autonomous)
   Checkpoint: Task 4 (verify)
   Segment 2: Tasks 5-7 (autonomous)
   Checkpoint: Task 8 (decision)
   Segment 3: Tasks 9-10 (autonomous)
   ```

3. **Check for dependencies**

   Look for optional `## Segment Dependencies` section:
   - If absent: sequential execution (current default)
   - If present: parse dependency graph for parallel execution

4. **Execute segments**

   **Sequential mode (no dependencies section):**
   For each segment:
   - Spawn `executor` with segment tasks
   - Wait for completion or checkpoint
   - Handle checkpoint in main context
   - Continue to next segment

   **Parallel mode (dependencies section exists):**
   - Track completed segments
   - Spawn all segments whose dependencies are satisfied
   - Wait for any segment to complete
   - Check for newly unblocked segments, spawn them
   - Handle checkpoints as they occur
   - Repeat until all segments complete

5. **Checkpoint handling**

   | Type | Action |
   |------|--------|
   | verify | Show results, ask approval |
   | decision | Present options, get choice |
   | human-action | Describe task, wait for confirmation |

6. **On segment completion**
   - Read the executor's returned status and summary text
   - **Persist the summary yourself** — subagents cannot write report files, so the
     executor returns its summary as text. Write that text to
     `.planning/phases/XX-name/SUMMARY-XX.Y.md`, then `git add` it (planning-only,
     always allowed by the commit gate).
   - If COMPLETE → continue to the watchdog
   - If BLOCKED → handle blocker
   - If NEEDS_DECISION → present to user

7. **Watchdog (test-writer-fixer)**
   - Spawn `test-writer-fixer` with the segment range and the `SUMMARY-XX.Y.md` path
   - **Persist its findings yourself** — write the watchdog's returned report to
     `.planning/phases/XX-name/WATCHDOG-XX.Y.md`, then `git add` it
   - If it reports real product bugs → record them in STATE.md/ISSUES.md, spawn the
     executor to fix, then re-run the watchdog
   - If `WATCHDOG_CLEAN` → continue to review

8. **After all segments pass the watchdog**
   - Spawn `reviewer` for verification (it reads the persisted SUMMARY/WATCHDOG files)
   - **Persist the review yourself** — write the reviewer's returned report to the
     phase `SUMMARY.md`, then `git add` it
   - Reviewer **APPROVE** (it sets `Commit-Gate: APPROVED` in STATE.md) → commit the
     approved unit with `feat(XX-YY): summary`. The commit gate is a *PreToolUse* hook,
     so `git add` must be a separate command from `git commit`, never chained.
   - Reviewer **NEEDS_WORK / BLOCKED** → present issues, spawn the executor with fixes,
     re-review

9. **Update STATE.md**
   - Phase status: Complete
   - Record decisions made
   - Update position to next phase

## Reports are returned, not written by subagents

The executor, watchdog, and reviewer all run as subagents, and the harness blocks
subagents from writing report/summary files (their final message *is* their return
value). So each returns its report as text and **you (the orchestrator) write it to
disk**: `SUMMARY-XX.Y.md` from the executor, `WATCHDOG-XX.Y.md` from the watchdog, and
the phase `SUMMARY.md` from the reviewer. Subagents still write their own *work
products* (code, tests) and edit *state files* (STATE.md, ESCAPES.md) directly — only
report files route through you.

## Output

Execution summary and next step recommendation.
