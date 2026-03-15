---
name: resume-work
description: Resume work from previous session with context restoration
allowed-tools: Read, Bash, Task, AskUserQuestion
---

# /resume-work

Resume work from a previous session using handoff context and auto-detected git state.

## Process

1. **Auto-detect position from git state**

   Run these commands to gather evidence:
   ```bash
   git status
   git log --oneline -10
   git branch --show-current
   ```

   Parse git evidence:
   - **Last commit pattern**: Look for `feat(XX-YY):` or `feat(XX):` in recent commits
   - **Uncommitted changes**: Files modified but not committed indicate work-in-progress
   - **Staged files**: Files staged but not committed indicate interrupted commit
   - **Branch state**: Current branch and any ahead/behind info

2. **Read state files**
   - `.planning/WIP.md` - Work-in-progress state (if exists -- highest priority, most recent)
   - `.planning/STATE.md` - Recorded position (what phase/segment is marked in-progress? any BLOCKED?)
   - `.planning/HANDOFF.md` - Explicit handoff context (if exists)
   - Current PLAN.md referenced in STATE.md

3. **Check for stale work**
   - List SUMMARY files for the current phase: `ls .planning/phases/XX-*/XX-*-SUMMARY.md`
   - Compare completed SUMMARY files against STATE.md segment statuses
   - Flag inconsistencies (e.g., SUMMARY exists but STATE.md still shows IN_PROGRESS)

4. **Reconcile sources**

   Compare sources of truth:
   | Source | Priority | What It Tells Us |
   |--------|----------|------------------|
   | WIP.md | 1 (highest) | Exact task-level position, orchestrator decisions, next action |
   | HANDOFF.md | 2 | Explicit pause context (from /pause-work) |
   | Git log | 3 | Last successfully committed segment |
   | Git status | 4 | Whether work is in progress |
   | STATE.md | 5 | Last recorded segment-level position |
   | SUMMARY files | 6 | Which segments actually completed |

   Determine confidence level:
   - **HIGH**: WIP.md exists and is recent, or all sources agree, or HANDOFF.md exists and matches git state
   - **MEDIUM**: Minor discrepancies (e.g., STATE.md one behind git)
   - **LOW**: Major conflicts between sources

5. **Synthesize and present concise status**

   Present a quick-scan summary first, then details:
   ```
   Session resumption:
   - Branch: feature/phase-XX-name
   - Phase: XX -- [phase name]
   - Last completed: Segment XX.N ([name])
   - Current task: Task M of P (from WIP.md, if available)
   - Next pending: [next task or segment]
   - Uncommitted changes: [yes/no -- list if yes]
   - WIP.md: [found/not found]
   - HANDOFF.md: [found/not found]
   - Confidence: HIGH|MEDIUM|LOW
   ```

   Then show detailed position detection:
   ```markdown
   ## Position Detection

   - **WIP.md says**: [task-level position and next action, or "Not found"]
   - **Last commit**: feat(XX-YY): [message] (segment XX.Y complete)
   - **Uncommitted changes**: [list of modified files]
   - **STATE.md says**: Segment XX.Y [status]
   - **HANDOFF.md says**: [context if exists, or "Not found"]
   - **Stale work check**: [consistent / inconsistencies found]
   - **Inferred position**: [Mid-segment XX.Y | Start of XX.Y | etc] (confidence: HIGH|MEDIUM|LOW)

   ### Discrepancies
   - [Any conflicts between sources]
   - [Which source to trust and why]
   ```

6. **Get confirmation**

   Ask: "Resume from Segment XX.M, or would you like to do something else?"
   - Allow user to provide additional context
   - If discrepancies found, ask which source to trust

7. **Resume execution**
   - Spawn appropriate agent based on reconciled state
   - Pass handoff context and detected position

8. **Clean up**
   - Archive HANDOFF.md after successful resume
   - Update STATE.md if it was stale

## Fallback Behavior

If no HANDOFF.md exists:
- Rely on git state + STATE.md
- Present detected position with lower confidence
- Suggest `/progress` if detection is inconclusive

## Output

Position detection summary with confidence level, reconciled state, and continuation of work via appropriate agent.
