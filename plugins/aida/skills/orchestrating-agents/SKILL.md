---
name: orchestrating-agents
description: Project planning and execution workflow. Use when user mentions phases, roadmaps, milestones, planning, project management, or wants to execute work systematically. Coordinates research, planning, execution, and review sub-agents.
---

# AIDA Orchestrator

AI Development Agents - Autonomous project execution with human-in-the-loop checkpoints.

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
- `.planning/ESCAPES.md` - Escape catalog (known failure patterns; grows over time)

## Sub-Agents

Spawn via Task tool with dedicated subagent types:

| Agent | subagent_type | When | Purpose |
|-------|---------------|------|---------|
| researcher | `researcher` | Before planning | Gather context |
| planner | `planner` | After research | Create PLAN.md |
| executor | `executor` | After plan approved | Execute segments (stages work, does NOT commit) |
| test-writer-fixer | `test-writer-fixer` | After execution, before review | Independent watchdog: makes tests real, flags product bugs |
| reviewer | `reviewer` | After watchdog | Verify + spec/quality + audit; marks `APPROVED` |

**Canonical pipeline:** `researcher → planner → (approval) → executor → test-writer-fixer → reviewer → (commit on APPROVE)`

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
   - Execution done (staged, uncommitted)? → Spawn test-writer-fixer (watchdog)
   - Watchdog found product bugs? → Spawn executor to fix, then re-run watchdog
   - Watchdog clean? → Spawn reviewer
   - Reviewer NEEDS_WORK? → Spawn executor with fixes, re-review
   - Reviewer APPROVE? → Commit the approved unit (gate now unlocked), update STATE, next phase
   - Phase complete? → Run retrospective (see Continuous Improvement)
```

### Commit Timing (important)

Work is **committed only after the reviewer marks `APPROVED`** in STATE.md. The executor and watchdog stage their work but never commit. This is enforced by the review-before-commit hook. The commit — done by you, the orchestrator, once the gate is unlocked — bundles code + tests + summaries + STATE.md into one reviewed unit.

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

## Continuous Improvement (Escapes + Retrospective)

AIDA gets smarter across phases through a learning loop. This is not optional overhead — it is the mechanism that prevents the same bug class from recurring.

### The Escape Catalog (`.planning/ESCAPES.md`)

An **escape** is any defect or process failure that got past the pipeline: a bug the reviewer approved, a fix you (the orchestrator) had to make *after* review, or a skipped methodology step. See `templates/escapes.md` for the format and the 7 escape classes.

- The **reviewer** drafts candidate escape entries during its audit pass.
- **You** confirm them and, where a check has proven reliable, mark a `Hook candidate` so it can be promoted from a checklist item to an enforced hook.
- **Never delete entries.** The catalog only grows.

> Trigger rule: if you make ANY code fix *after* a phase was reviewed/approved, that is an escape by definition. Log it before moving on.

### Phase Retrospective

After a phase completes (all segments approved, verification passes), run a short retrospective before starting the next phase:

1. **Metrics** — segments total, segments approved cleanly (no post-review fixes), clean-pass rate, new escapes this phase.
2. **Patterns** — which escape classes recur? Is the clean-pass rate improving across phases? Which checks are being rubber-stamped?
3. **Evolution** — promote proven checklist items to hooks; retire steps that add overhead without catching anything; refine escape entries.
4. Record the summary in `.planning/STATE.md` (or the metrics section) so trends are visible over time.

Keep it lightweight — a few sentences and the metrics line. The value is the trend, not the ceremony.

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
