---
name: progress
description: Check AIDA project status, show metrics, and route to next action
allowed-tools: Read, Bash, Task, AskUserQuestion
---

# /progress

Check current project status, show auto-derived metrics, and determine next action.

## Process

1. **Read state files**
   - `.planning/STATE.md` - Current position
   - `.planning/ROADMAP.md` - Phase status

2. **Determine current position**
   - Which phase is in progress?
   - What's the current plan status?
   - Any blockers or pending decisions?

3. **Route to next action**

   | State | Next Action |
   |-------|-------------|
   | No project | Suggest `/new-project` |
   | No roadmap | Suggest `/create-roadmap` |
   | Phase needs plan | Suggest `/plan-phase N` (spawns researcher then planner) |
   | Plan ready, not approved | Ask user to review |
   | Plan approved | Suggest `/execute` (spawns `executor`) |
   | Execution done (staged) | Spawn `test-writer-fixer` (watchdog) |
   | Watchdog found bugs | Spawn `executor` to fix, then re-run watchdog |
   | Watchdog clean | Spawn `reviewer` |
   | Reviewer NEEDS_WORK | Spawn `executor` with fixes, re-review |
   | Reviewer APPROVE | Commit approved unit, update STATE, next phase |
   | Phase complete | Run retrospective (update `ESCAPES.md` + metrics block) |
   | Blocked | Present blocker, get guidance |

4. **Report status**
   ```
   ## AIDA Status

   **Project**: [name]
   **Current Phase**: XX - [name]
   **Status**: [Planning|Executing|Review|Blocked]
   **Next Action**: [what will happen next]
   ```

## Metrics (auto-derived — no manual file)

After the status summary, show a compact metrics block derived at query time from git + planning artifacts:

```bash
git log --oneline --grep="^feat(" | sed 's/^[^ ]* feat(\([0-9]*\).*/\1/' | sort | uniq -c | sort -k2 -n  # commits per phase
git log --oneline | wc -l                                                                                  # total commits
```

Read `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/phases/*/SUMMARY-*.md` for phases completed vs planned, tests added, and open issue count from `ISSUES.md`.

```
Metrics
=======
Phases:  X completed / Y planned      Total commits: NNN
Clean-pass rate: N/N (%)              Open issues: N     Escapes logged: N
Phase history: | Phase | Segments | Commits | Status |
```

Include the **clean-pass rate** (segments approved with no post-review fixes) and **escapes logged** (`.planning/ESCAPES.md`) — these are the health signals the retrospective tracks. Skip the metrics block if `.planning/` doesn't exist.

## Output

Clear status summary + metrics block, and either:
- Spawn appropriate agent, or
- Ask user for input/decision
