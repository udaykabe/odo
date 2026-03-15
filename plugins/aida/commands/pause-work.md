---
name: pause-work
description: Create context handoff when pausing work mid-phase
allowed-tools: Read, Write
---

# /pause-work

Create a context handoff file for resuming later.

## Process

1. **Gather current state**
   - Read `.planning/WIP.md` (if exists -- contains task-level progress and orchestrator decisions)
   - Read `.planning/STATE.md`
   - Read current PLAN.md (if exists)
   - Check git status for uncommitted work

2. **Create handoff file**

   Write to `.planning/HANDOFF.md`:
   ```markdown
   # Work Handoff

   Created: [timestamp]

   ## Current Position
   - Phase: XX - [name]
   - Plan: XX-YY-PLAN.md
   - Task: [current task number]
   - Status: [in progress|blocked|waiting]

   ## Context
   [What was being worked on]
   [Any decisions made]
   [Any blockers encountered]

   ## Uncommitted Changes
   [git status summary]

   ## Resume Instructions
   1. [Step to resume]
   2. [What to check first]
   3. [Where to continue]

   ## Open Questions
   - [Any unresolved questions]
   ```

3. **Incorporate WIP.md into handoff**
   - If `.planning/WIP.md` exists, incorporate its content (task progress, orchestrator decisions, next action) into HANDOFF.md
   - Then delete WIP.md -- its content now lives in the handoff

4. **Update STATE.md**
   - Add handoff reference
   - Mark current work as paused

5. **Remind about commit**
   - If uncommitted changes exist, suggest committing

## Output

Confirmation that handoff was created with path to file.
