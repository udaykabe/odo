---
name: review-issues
description: Review deferred issues and decide which to address
allowed-tools: Read, Write, Task, AskUserQuestion
---

# /review-issues

Review ISSUES.md and triage deferred work.

## Process

1. **Load issues**
   - Read `.planning/ISSUES.md`
   - Parse all open issues

2. **Spawn researcher for context**
   - Check if issues are still relevant
   - Identify any that were resolved

3. **Present issues to user**
   ```markdown
   ## Open Issues

   ### High Priority
   - ISS-001: [title] - [status]
   - ISS-005: [title] - [status]

   ### Medium Priority
   - ISS-002: [title] - [status]

   ### Possibly Resolved
   - ISS-003: [title] - [may be fixed by phase X]

   ## Recommendations
   - Address ISS-001 in next phase
   - Close ISS-003 (resolved)
   - Defer ISS-002 to future milestone
   ```

4. **Get user decisions**
   - Which to address now?
   - Which to close?
   - Which to keep deferred?

5. **Update ISSUES.md**
   - Mark closed issues
   - Update priorities

6. **Optionally create phase**
   - If addressing issues, offer to create fix phase

## Output

Triaged issues with updated ISSUES.md.
