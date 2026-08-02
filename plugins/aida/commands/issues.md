---
name: issues
description: Log a deferred issue, or triage the deferred-issue backlog
allowed-tools: Read, Write, Task, AskUserQuestion
---

# /issues [add <description> | review]

One command for the deferred-work backlog in `.planning/ISSUES.md`.

- `/issues add <description>` — log a new deferred issue/enhancement.
- `/issues review` (or `/issues` with no arg) — triage the backlog.

---

## Mode: add

1. Read `.planning/ISSUES.md`.
2. Generate the next sequential ID: `ISS-NNN`.
3. Append:
   ```markdown
   ## ISS-NNN: [Title]

   **Added**: [date]   **Phase**: [current]   **Priority**: [low|medium|high]   **Type**: [bug|enhancement|refactor|debt]

   ### Description
   [full description]

   ### Context
   [why deferred]
   ```
4. Confirm the ID.

**Output:** issue ID + confirmation.

---

## Mode: review

1. **Load & parse** all open issues from `.planning/ISSUES.md`.
2. **Spawn `researcher`** to check whether each issue is still relevant or was resolved by later phases.
3. **Present triaged view:**
   ```markdown
   ## Open Issues
   ### High / Medium / Low
   - ISS-NNN: [title] — [status]
   ### Possibly Resolved
   - ISS-NNN: [title] — [may be fixed by phase X]

   ## Recommendations
   - Address / Close / Defer …
   ```
4. **Get user decisions** — address now / close / keep deferred.
5. **Update ISSUES.md** — mark closed (with `**Resolved**: <date>` / `**Status**: resolved in Phase XX`), update priorities.
6. **Optionally** offer to create a fix phase for issues being addressed.

**Output:** triaged backlog with updated `ISSUES.md`.
