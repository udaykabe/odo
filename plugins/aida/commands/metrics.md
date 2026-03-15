---
name: metrics
description: View auto-derived AIDA project metrics from git history and planning artifacts
allowed-tools: Read, Bash
---

# /metrics

Display project metrics auto-derived from git history and planning artifacts. No manual METRICS.md file required.

## Process

### 1. Auto-derive from git history

Run these commands to gather data:

```bash
# Count commits per phase (feat(XX) pattern)
git log --oneline --grep="^feat(" | sed 's/^[^ ]* feat(\([0-9]*\).*/\1/' | sort | uniq -c | sort -k2 -n

# List all phase completion commits
git log --oneline --grep="^feat(" --grep="COMPLETE\|complete\|verification" | head -20

# Count total commits
git log --oneline | wc -l

# Files changed per phase (sample last phase)
# git diff --stat <phase-start-commit>..<phase-end-commit>
```

### 2. Auto-derive from planning artifacts

Read these files to gather state:

- `.planning/STATE.md` -- Current phase, segment status, phases completed vs total
- `.planning/ROADMAP.md` -- Total planned phases
- `.planning/phases/*/` -- List phase directories and their SUMMARY files

Extract from SUMMARY files:
- Test counts (grep for "test" or "Tests" in SUMMARY files)
- Files modified per segment
- Deviations and issues discovered

### 3. Synthesize and display

Present a dashboard-style summary:

```
Project Metrics
===============
Phases: X completed / Y planned
Current: Phase XX -- Segment XX.N
Total commits: NNN

Phase History:
| Phase | Name | Segments | Commits | Status |
|-------|------|----------|---------|--------|
| 01    | ...  | N        | N       | COMPLETE |
| 02    | ...  | N        | N       | COMPLETE |
| ...   | ...  | ...      | ...     | ...      |

Test Coverage Trend:
(extracted from SUMMARY files where available)
- Phase XX: N tests added
- Phase YY: N tests added

Active Issues: N (from ISSUES.md)
```

### 4. Optional deep dive

If the user asks for more detail on a specific phase:
- Show all commits for that phase: `git log --oneline --grep="^feat(XX"`
- Show the SUMMARY file for each segment
- List files changed

## Output Format

Always display the dashboard summary first. Offer to drill into specific phases if requested.

## Notes

- All data is derived at query time -- no manual file maintenance needed
- Phase commit counts use the `feat(XX` grep pattern from commit conventions
- Test counts depend on SUMMARY files recording them (best-effort)
- If `.planning/` does not exist, report that the project has not been initialized with AIDA
