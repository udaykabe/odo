---
name: execute
description: Execute the current approved plan
allowed-tools: Read, Write, Task, AskUserQuestion
---

# /gti:execute

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
   - Read executor's status
   - If COMPLETE → Continue
   - If BLOCKED → Handle blocker
   - If NEEDS_DECISION → Present to user

7. **After all segments**
   - Spawn `reviewer` for verification
   - If review passes → Create SUMMARY.md
   - If review fails → Present issues, decide fix

8. **Update STATE.md**
   - Phase status: Complete
   - Record decisions made
   - Update position to next phase

## Output

Execution summary and next step recommendation.
