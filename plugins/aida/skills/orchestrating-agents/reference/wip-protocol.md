# Work-In-Progress Protocol

Captures session state continuously so work can resume after interruptions (context compaction, usage limits, crashes, exits).

## The Problem

GTI state files (STATE.md, SUMMARY.md) are only updated at segment completion boundaries. If a session ends mid-segment, the only evidence of progress is:
- Git commits (completed work)
- STATE.md (segment-level status, not task-level)
- Conversation context (lost on exit/compaction)

## The Solution: WIP.md

`.planning/WIP.md` is a continuously-updated file that captures in-flight work state.

## Format

```markdown
# Work In Progress

*Auto-updated during execution. Do not edit manually.*
*Last updated: YYYY-MM-DD HH:MM*

## Current Context

- **Phase**: XX -- [phase name]
- **Segment**: XX.N -- [segment name]
- **Branch**: feature/phase-XX-name
- **Agent**: [executor | researcher | planner | reviewer | none]
- **Status**: [executing | waiting-for-approval | between-segments]

## Task Progress

| Task | Description | Status |
|------|-------------|--------|
| 1 | [from PLAN.md] | DONE |
| 2 | [from PLAN.md] | DONE |
| 3 | [from PLAN.md] | IN_PROGRESS |
| 4 | [from PLAN.md] | PENDING |

## Orchestrator Decisions

- Spawned researcher for Phase XX context gathering
- Research complete: [key findings summary]
- Spawned planner: plan created at .planning/phases/XX-name/PLAN.md
- User approved plan
- Executing segment XX.1: spawned executor for tasks 1-4
- Segment XX.1 complete: [summary]
- Executing segment XX.2: spawned executor for tasks 5-7

## Last Agent Result

[Summary of the most recent agent's output -- what was accomplished, any issues]

## Next Action

[What should happen next if this session resumes]
```

## Who Updates WIP.md

### Orchestrator (before spawning agent)
```
Update WIP.md:
- Set Agent to the agent being spawned
- Set Status to "executing"
- Add decision to Orchestrator Decisions log
- Set Next Action
```

### Executor (after each task)
```
Update WIP.md:
- Mark completed task as DONE in Task Progress table
- Mark next task as IN_PROGRESS
- Update Last Agent Result with task completion note
```

### Orchestrator (after receiving agent result)
```
Update WIP.md:
- Set Agent to "none"
- Set Status to "between-segments" or "waiting-for-approval"
- Update Last Agent Result with agent summary
- Set Next Action to what comes next
```

## Lifecycle

1. **Created** when first agent is spawned in a phase
2. **Updated** continuously during execution
3. **Cleared** when segment completes (content moves to SUMMARY.md)
4. **Deleted** when phase completes or `/gti:pause-work` runs (content moves to HANDOFF.md)

## Resumption

`/gti:resume-work` reads WIP.md as a primary source (higher priority than inferring from git):

| Source | Priority | What It Provides |
|--------|----------|-----------------|
| WIP.md | 1 (highest) | Exact task-level position, orchestrator decisions, next action |
| HANDOFF.md | 2 | Explicit pause context (from /gti:pause-work) |
| Git state | 3 | Last committed work |
| STATE.md | 4 | Segment-level status |
