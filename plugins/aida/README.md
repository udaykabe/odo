# AIDA -- AI Development Agents

A Claude Code plugin for autonomous project execution with human-in-the-loop checkpoints. The orchestrator coordinates specialized sub-agents through a **research → plan → execute → test (watchdog) → review** pipeline, with a review-before-commit gate and an escape-catalog learning loop that makes the process smarter over time. Each agent stays focused and context-efficient.

AIDA is project-agnostic and technology-agnostic. It ships generic workflow patterns; technology-specific guidance lives in opt-in reference files.

## Installation

### From local directory (development)

```bash
claude --plugin-dir ./plugins/aida
```

### Post-install setup

Copy `CLAUDE.md.template` to your project root as `CLAUDE.md` and fill in the project-specific sections below the `PROJECT CONFIG` marker. This configures the orchestrator with your project's services, verification commands, and coding conventions.

## Plugin Structure

```
.claude-plugin/
  plugin.json                          # Plugin manifest
agents/
  researcher.md                        # Context gathering before planning
  planner.md                           # Structured plan creation
  executor.md                          # Code implementation (stages, does not commit)
  test-writer-fixer.md                 # Independent test watchdog
  reviewer.md                          # Verification, audit, escape logging
commands/
  progress.md                          # Check status + metrics, route to next action
  new-project.md                       # Initialize planning structure
  map-codebase.md                      # Parallel codebase analysis
  create-roadmap.md                    # Create phased roadmap
  plan-phase.md                        # Research + create execution plan for a phase
  execute.md                           # Run the current approved plan
  verify.md                            # Run full verification suite
  handoff.md                           # Save/resume a session handoff
  issues.md                            # Log or triage deferred issues
skills/
  orchestrating-agents/
    SKILL.md                           # Core orchestrator process definition
    reference/                         # Injected context (see Reference Materials)
    resources/                         # Reusable project resources (e.g., E2E fixtures)
    templates/                         # Templates for plans, summaries, roadmaps
  mapping-codebase/
    SKILL.md                           # Parallel codebase analysis skill
    templates/                         # Templates for 7 codebase documents
hooks/
  hooks.json                           # Hook registrations (gate + automation)
  scripts/                             # gate-commit, session-start, prompt-context, stop
settings.json                          # Plugin settings
CLAUDE.md.template                     # Template for project-level CLAUDE.md
```

The `.planning/` directory is created per-project at runtime (not shipped with the plugin):

```
.planning/
  PROJECT.md                         # What we are building
  ROADMAP.md                         # Phase breakdown
  STATE.md                           # Current position and decisions
  ISSUES.md                          # Deferred work items
  ESCAPES.md                         # Escape catalog (known failure patterns; grows over time)
  WIP.md                             # Work-in-progress state (auto-updated during execution)
  codebase/                          # 7 analysis documents (from map-codebase)
  phases/XX-name/
    XX-YY-PLAN.md                    # Execution plan for segment YY
    SUMMARY-XX.Y.md                  # Post-execution summary (executor returns, orchestrator writes)
    WATCHDOG-XX.Y.md                 # Test findings (test-writer-fixer returns, orchestrator writes)
```

## How It Works

### Orchestrator Pattern

The orchestrator (defined in `CLAUDE.md` and `SKILL.md`) never writes code directly. It reads state, decides the next action, spawns a specialized agent, and relays results to the user. This preserves the orchestrator's context window for coordination rather than implementation details.

### Agent Pipeline

Every implementation task follows a mandatory pipeline:

```
researcher --> planner --> [user approval] --> executor --> test-writer-fixer --> reviewer --> [commit on APPROVE]
```

1. **Researcher** -- Explores the codebase, gathers context, identifies existing patterns
2. **Planner** -- Produces a structured `PLAN.md` with numbered tasks, acceptance criteria, verify commands, and checkpoints
3. **User approval** -- Human reviews the plan before any code is written
4. **Executor** -- Implements plan segments, writes first-pass tests, **stages** work (does not commit)
5. **Test-writer-fixer (watchdog)** -- Independent, fresh-context agent that makes the tests real (tests against *observed* behavior), fixes brittle tests, and *reports* real product bugs rather than fixing them
6. **Reviewer** -- Runs verification, does spec/quality review, audits process adherence, logs escapes, and marks `APPROVED`
7. **Commit on APPROVE** -- Only after the reviewer approves does the orchestrator commit the reviewed unit (enforced by the review-before-commit hook)

Each agent gets a fresh context window. This prevents token contamination -- and the watchdog's independence is deliberate: it does not share the executor's context or its incentive to declare its own work done.

### Progressive Disclosure

Context is layered so that each level only loads what it needs:

```
CLAUDE.md            Loaded always. Orchestrator rules + project config.
  |
  v
SKILL.md             Loaded when a skill is invoked. Process definitions.
  |
  v
agents/*.md          Loaded per-agent. Role-specific instructions.
  |
  v
reference/           Injected selectively by the orchestrator when relevant.
```

### Context Injection

The orchestrator does not expect agents to self-discover all relevant guidance. Instead, it injects targeted context from the `reference/` directory when spawning agents. For example, an executor working on database queries receives the relevant pitfall file; a reviewer gets project-specific verification commands.

### Session Continuity

The framework maintains `.planning/WIP.md` during active execution, capturing task-level progress and orchestrator decisions in real time. If a session is interrupted (context compaction, usage limits, exit), `/handoff resume` reads WIP.md to restore exact position -- including which task within a segment was last completed and what the orchestrator planned to do next. See `reference/wip-protocol.md` for details.

### Continuous Improvement

AIDA gets smarter across phases. The reviewer's audit pass logs any **escape** (a defect or process failure that got past the pipeline) to `.planning/ESCAPES.md`, classified into one of seven classes, with a checklist patch so the same class can't recur. A lightweight per-phase retrospective tracks the clean-pass rate and promotes proven checks into enforced hooks. See `templates/escapes.md`.

### Enforcement (Hooks)

The pipeline is *enforced*, not merely documented. AIDA ships hooks (`hooks/hooks.json`):

| Hook | Event | Effect |
|------|-------|--------|
| `gate-commit` | PreToolUse (Bash) | **Blocks** a code `git commit` unless `STATE.md` reads `Commit-Gate: APPROVED`; also blocks if `Escape-Pending: yes`. Planning-only commits are allowed. |
| `session-start` | SessionStart | Surfaces `WIP.md` so an interrupted session can resume |
| `prompt-context` | UserPromptSubmit | Injects current phase / next-action / gate status each turn |
| `stop-checkpoint` | Stop | Reminds you to checkpoint uncommitted code into `WIP.md` |

The gate is driven by two `Key: Value` markers in `STATE.md`: `Commit-Gate:` (`LOCKED`→`APPROVED`, set by executor/reviewer) and `Escape-Pending:` (`yes`→`no`). It is **opt-in per project** — enforcement only kicks in once a `Commit-Gate:` line exists in `STATE.md` (`new-project` seeds it; existing projects add the line to opt in). The gate fails **open** if `jq`/`git` are unavailable, so it never wedges a repo.

## Quick Start

### Brownfield (existing codebase)

1. Install the plugin (see Installation above)
2. Copy `CLAUDE.md.template` to your project root as `CLAUDE.md`. Fill in the project-specific sections below the `PROJECT CONFIG` marker.
3. Run `/map-codebase` to analyze the existing codebase and generate `.planning/codebase/` documents
4. Run `/new-project` to create PROJECT.md and initialize the planning structure
5. Run `/create-roadmap` to define phases
6. Run `/progress` to begin the first phase

### Greenfield (new project)

1. Install the plugin (see Installation above)
2. Copy `CLAUDE.md.template` to your project root as `CLAUDE.md`. Fill in the project-specific sections below the `PROJECT CONFIG` marker.
3. Run `/new-project` to create PROJECT.md and initialize the planning structure
4. Run `/create-roadmap` to define phases
5. Run `/progress` to begin the first phase

*Skip `/map-codebase` for greenfield -- there is nothing to map yet. Run it later after initial code is written.*

## Commands Reference

All commands are invoked as `/<command>`.

| Command | Description |
|---------|-------------|
| `progress` | Check project status + metrics, and route to the next action |
| `new-project` | Initialize PROJECT.md and the .planning/ structure |
| `map-codebase` | Analyze codebase with parallel agents, produce 7 reference documents |
| `create-roadmap` | Create a phased roadmap from PROJECT.md |
| `plan-phase` | Research and create a detailed execution plan for a specific phase |
| `execute` | Execute the current approved plan |
| `verify` | Run full verification suite (type checking, tests, lint) |
| `handoff [save\|resume]` | Save a context handoff when pausing, or resume a prior session |
| `issues [add\|review]` | Log a deferred issue, or triage the deferred-issue backlog |

## Skills

| Skill | Purpose |
|-------|---------|
| `orchestrating-agents` | Core workflow: state management, agent coordination, checkpoint handling |
| `mapping-codebase` | Spawns 4 parallel agents to produce 7 codebase analysis documents (STACK, ARCHITECTURE, STRUCTURE, CONVENTIONS, TESTING, INTEGRATIONS, CONCERNS) |

## Agents

| Agent | Purpose | Allowed Tools |
|-------|---------|---------------|
| `researcher` | Gather context, find relevant files, identify existing patterns | Read, Glob, Grep, WebSearch, WebFetch |
| `planner` | Create structured PLAN.md with tasks, acceptance criteria, segments, checkpoints | Read, Write, Glob, Grep |
| `executor` | Implement plan segments, write first-pass tests; stages work, does not commit | Read, Write, Edit, Bash, Glob, Grep |
| `test-writer-fixer` | Independent watchdog: make tests real, fix brittle tests, report product bugs | Read, Write, Edit, Bash, Glob, Grep |
| `reviewer` | Verify + spec/quality + audit; log escapes; mark APPROVED (`.planning/` edits only) | Read, Bash, Glob, Grep, Edit |

## Reference Materials

The `skills/orchestrating-agents/reference/` directory contains guidance that the orchestrator injects into agent prompts when relevant:

| File | Content |
|------|---------|
| `workflow-principles.md` | 15 battle-tested principles for autonomous execution |
| `common-pitfalls.md` | Cross-cutting integration pitfalls (ID mapping, API contracts, mocks) |
| `checkpoint-types.md` | NEEDS_DECISION, NEEDS_VERIFICATION, BLOCKED handling |
| `deviation-rules.md` | When agents can auto-fix vs. when they must ask |
| `segment-dependencies.md` | How to express and resolve inter-segment dependencies |
| `phase-numbering.md` | Naming conventions for phases and segments |
| `wip-protocol.md` | Work-in-progress tracking for session continuity |
| `pitfalls/<tech>.md` | Technology-specific guidance (arangodb, express, playwright, react) |

*The shipped pitfalls files (arangodb, express, playwright, react) are examples from the framework's original project. Delete any that are irrelevant to your stack and add your own.*

The `resources/` directory contains reusable project assets (E2E test fixtures and helpers) that agents copy into projects rather than writing from scratch.

*The E2E resources are Playwright/TypeScript-specific. Projects using other E2E frameworks (Cypress, Selenium, etc.) should create equivalent resources or skip this directory.*

The `templates/` directory contains templates for plans, summaries, and roadmaps that the planner agent fills during plan creation.

## Customization

**Adding technology-specific pitfalls** -- Create a new file at `skills/orchestrating-agents/reference/pitfalls/<technology>.md`. The orchestrator will inject it when spawning agents that work with that technology.

**Adding templates** -- Place new templates in `skills/orchestrating-agents/templates/` or `skills/mapping-codebase/templates/`. Reference them from the relevant SKILL.md or agent instructions.

**Adding commands** -- Create a new `.md` file in `commands/` with YAML frontmatter (name, description, allowed-tools). The command becomes available as `/<name>`.

**Project-specific configuration** -- Edit the project-specific sections of `CLAUDE.md` (services, ports, build commands, testing tiers). The orchestrator discipline section and AIDA workflow section remain unchanged across projects.
