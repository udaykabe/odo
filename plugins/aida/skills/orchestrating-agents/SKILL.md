---
name: orchestrating-agents
description: Project planning and execution workflow. Use when user mentions phases, roadmaps, milestones, planning, project management, or wants to execute work systematically. Coordinates research, planning, execution, and review sub-agents.
---

# AIDA Orchestrator

Get To It - Autonomous project execution with human-in-the-loop checkpoints.

## Overview

You are the orchestrator for AIDA workflow. You:
- Coordinate specialized sub-agents
- Handle HITL checkpoints
- Maintain project state
- Never execute code directly

## State Files

Read these to understand current position:
- `.planning/PROJECT.md` - What we're building
- `.planning/ROADMAP.md` - Phase breakdown
- `.planning/STATE.md` - Current position, decisions, issues

## Sub-Agents

Spawn via Task tool with dedicated subagent types:

| Agent | subagent_type | When | Purpose |
|-------|---------------|------|---------|
| researcher | `researcher` | Before planning | Gather context |
| planner | `planner` | After research | Create PLAN.md |
| executor | `executor` | After plan approved | Execute segments |
| reviewer | `reviewer` | After execution | Verify completion |

### Spawning Pattern

```markdown
Task(
  subagent_type="researcher",
  prompt="[your task]"
)
```

### Example Prompts

**researcher:**
```
Research phase 3 requirements. Context:
- PROJECT.md: [summary]
- Phase goal: [from ROADMAP.md]

Return findings for planning.
```

**planner:**
```
Create PLAN.md for phase 3. Context:
- Research findings: [summary from researcher]
- Phase directory: .planning/phases/03-feature-name/

Write plan to 03-01-PLAN.md.
```

**executor:**
```
Execute segment 1 (tasks 1-4) of .planning/phases/03-feature-name/03-01-PLAN.md.

Stop at checkpoints and return status.
```

**reviewer:**
```
Review phase 03-01 completion:
- PLAN.md: .planning/phases/03-feature-name/03-01-PLAN.md
- SUMMARY.md: .planning/phases/03-feature-name/03-01-SUMMARY.md

Return APPROVE, NEEDS_WORK, or BLOCKED.
```

## Workflow

```
1. Check STATE.md for current position
2. Determine next action:
   - No project? → Initialize
   - No roadmap? → Create roadmap
   - Phase needs research? → Spawn researcher
   - Phase needs plan? → Spawn planner
   - Plan ready? → Get approval, spawn executor
   - Execution done? → Spawn reviewer
   - Review passed? → Update STATE, next phase
```

## Checkpoint Handling

When sub-agent returns checkpoint status:

### NEEDS_DECISION
```markdown
Present options to user via AskUserQuestion
Wait for response
Pass decision to next agent
```

### NEEDS_VERIFICATION
```markdown
Show user what was done
Ask for approval
If approved → continue
If not → spawn executor with fixes
```

### BLOCKED
```markdown
Present blocker to user
Get guidance
Resume or pivot
```

## Parallel Segment Execution

When a plan declares segment dependencies (see `reference/segment-dependencies.md`), independent segments can run in parallel.

### How to Execute in Parallel

1. Check the plan's **Segment Dependencies** section to identify independent segments
2. Spawn multiple executor agents using `run_in_background=true` for each independent segment
3. Wait for all parallel agents to complete before spawning segments that depend on them

### Rules

- **File ownership must not overlap** -- Each parallel segment must work on distinct files. If two segments modify the same file, they must run sequentially.
- **Merge order** -- When parallel segments complete, review results before spawning dependent segments
- **Checkpoint handling** -- A checkpoint in one parallel segment does not pause other parallel segments
- **Default is sequential** -- Only parallelize when the plan explicitly declares dependencies and segments are truly independent

### Example

```
# Plan declares:
# Segment 2 depends on: 1
# Segment 3 depends on: 1
# Segment 4 depends on: 2, 3

# Orchestrator execution:
1. Spawn executor for Segment 1
2. After Segment 1 completes:
   - Spawn executor for Segment 2 (run_in_background=true)
   - Spawn executor for Segment 3 (run_in_background=true)
3. After both Segment 2 and 3 complete:
   - Spawn executor for Segment 4
```

## Context Efficiency

Keep main context light:
- Only read STATE.md headers
- Let sub-agents handle file exploration
- Store decisions in STATE.md
- Trust agent summaries

## Context Injection

When spawning agents, provide relevant context from reference materials rather than expecting agents to self-discover.

### What to inject per agent type

**executor** -- When the task involves:
- Database queries: Include relevant pitfall guidance from `reference/pitfalls/`
- E2E test setup: Reference `resources/e2e/` and provide copy instructions
- UI/frontend work: Include `reference/pitfalls/ux-design.md` and `reference/pitfalls/ui-implementation.md`
- Technology-specific work: Summarize relevant patterns from `reference/pitfalls/<tech>.md`

**researcher** -- When exploring:
- Include known architectural constraints from PROJECT.md
- Specify which directories/patterns to prioritize
- For UX/UI tasks: Include `reference/pitfalls/ux-design.md` so research covers accessibility, states, and interaction patterns

**planner** -- When creating plans:
- Include relevant findings from researcher
- Note any technology-specific pitfalls that affect the design

**reviewer** -- When verifying:
- Include project-specific verification commands from PROJECT.md
- Note which test tiers are configured for this project

## Work-In-Progress Tracking

Maintain `.planning/WIP.md` to capture session state continuously. This enables reliable resumption after context compaction, usage limits, or session exits.

### Orchestrator Responsibilities

**Before spawning any agent:**
1. Create or update `.planning/WIP.md` with current context
2. Log the decision in the Orchestrator Decisions section
3. Set the Next Action

**After receiving agent results:**
1. Update WIP.md with agent outcome
2. Set Next Action to what comes next
3. If segment is complete, content moves to SUMMARY.md and WIP.md resets for next segment

See `reference/wip-protocol.md` for the full protocol and file format.

### Key Rule

> WIP.md is updated BEFORE spawning agents, not after. If the session dies during agent execution, WIP.md already records what was being attempted.

## Workflow Principles

See `reference/workflow-principles.md` for battle-tested principles from real project execution. Key highlights:

1. **Research before planning** -- Always verify current state before creating tasks
2. **Test infrastructure debt compounds** -- Run full suites periodically, not just related tests
3. **Root causes are systemic** -- When many tests fail, look for shared cause before fixing individually
4. **Mock fidelity matters** -- Mock responses must exactly match real API contracts
5. **State file staleness causes duplicate work** -- Always re-read before modifying
6. **Integration points are where bugs live** -- Pay special attention to system boundaries
7. **Verification must be multi-layered** -- Each layer catches different bug classes

## Resources

AIDA provides reusable resources in `skills/orchestrating-agents/resources/`:

| Resource | Purpose |
|----------|---------|
| `e2e/` | E2E testing infrastructure (error monitoring, fixtures) |

Agents should copy these resources to projects as needed rather than writing from scratch.

## Reference Files

For detailed guidance, see:
- `reference/checkpoint-types.md`
- `reference/deviation-rules.md`
- `reference/phase-numbering.md`
- `reference/segment-dependencies.md`
- `reference/common-pitfalls.md`
- `reference/wip-protocol.md`
