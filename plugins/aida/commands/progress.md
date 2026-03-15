---
name: progress
description: Check AIDA project status and route to next action
allowed-tools: Read, Task, AskUserQuestion
---

# /progress

Check current project status and determine next action.

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
   | No roadmap | Suggest creating roadmap |
   | Phase needs research | Spawn `researcher` |
   | Phase needs plan | Spawn `planner` |
   | Plan ready, not approved | Ask user to review |
   | Plan approved | Spawn `executor` |
   | Execution done | Spawn `reviewer` |
   | Review passed | Update STATE, next phase |
   | Blocked | Present blocker, get guidance |

4. **Report status**
   ```
   ## AIDA Status

   **Project**: [name]
   **Current Phase**: XX - [name]
   **Status**: [Planning|Executing|Review|Blocked]
   **Next Action**: [what will happen next]
   ```

## Output

Clear status summary and either:
- Spawn appropriate agent, or
- Ask user for input/decision
