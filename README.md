# GTI -- Get To It

A Claude Code plugin for autonomous project execution with human-in-the-loop checkpoints. The orchestrator coordinates specialized sub-agents through a research-plan-execute-review pipeline, keeping each agent focused and context-efficient.

GTI is project-agnostic and technology-agnostic. It ships generic workflow patterns; technology-specific guidance lives in opt-in reference files.

## Installation

### From local directory (development)

```bash
claude --plugin-dir /path/to/odo
```

### From marketplace

```bash
# Install for current user (all projects)
claude plugin install gti@<marketplace>

# Install for current project (shared with team)
claude plugin install gti@<marketplace> --scope project
```

### Post-install setup

Copy `CLAUDE.md.template` to your project root as `CLAUDE.md` and fill in the project-specific sections below the `PROJECT CONFIG` marker. This configures the orchestrator with your project's services, verification commands, and coding conventions.

## Plugin Structure

```
.claude-plugin/
  plugin.json                          # Plugin manifest
agents/
  researcher.md                    # Context gathering before planning
  planner.md                       # Structured plan creation
  executor.md                      # Code implementation
  reviewer.md                      # Verification and quality checks
commands/gti/
  progress.md                          # Check status, route to next action
  new-project.md                       # Initialize planning structure
  map-codebase.md                      # Parallel codebase analysis
  create-roadmap.md                    # Create phased roadmap
  research.md                          # Research a topic or phase
  plan-phase.md                        # Create execution plan for a phase
  execute.md                           # Run the current approved plan
  verify.md                            # Run full verification suite
  pause-work.md                        # Create handoff for session breaks
  resume-work.md                       # Restore context from previous session
  add-issue.md                         # Log deferred issues
  review-issues.md                     # Triage deferred issues
  metrics.md                           # View project metrics
skills/
  gti-orchestrator/
    SKILL.md                           # Core orchestrator process definition
    reference/                         # Injected context (see Reference Materials)
    resources/                         # Reusable project resources (e.g., E2E fixtures)
    templates/                         # Templates for plans, summaries, roadmaps
  mapping-codebase/
    SKILL.md                           # Parallel codebase analysis skill
    templates/                         # Templates for 7 codebase documents
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
  WIP.md                             # Work-in-progress state (auto-updated during execution)
  codebase/                          # 7 analysis documents (from map-codebase)
  phases/XX-name/
    XX-YY-PLAN.md                    # Execution plan for segment YY
    XX-YY-SUMMARY.md                 # Post-execution summary
```

## How It Works

### Orchestrator Pattern

The orchestrator (defined in `CLAUDE.md` and `SKILL.md`) never writes code directly. It reads state, decides the next action, spawns a specialized agent, and relays results to the user. This preserves the orchestrator's context window for coordination rather than implementation details.

### Agent Pipeline

Every implementation task follows a mandatory four-stage pipeline:

```
researcher --> planner --> [user approval] --> executor --> reviewer
```

1. **Researcher** -- Explores the codebase, gathers context, identifies existing patterns
2. **Planner** -- Produces a structured `PLAN.md` with numbered tasks, segments, and checkpoints
3. **User approval** -- Human reviews the plan before any code is written
4. **Executor** -- Implements plan segments, writes code and tests, commits work
5. **Reviewer** -- Runs verification suite, checks requirements, produces review report

Each agent gets a fresh context window. This prevents token contamination -- an executor working on database queries does not carry the context overhead of the researcher's file exploration.

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

The framework maintains `.planning/WIP.md` during active execution, capturing task-level progress and orchestrator decisions in real time. If a session is interrupted (context compaction, usage limits, exit), `/gti:resume-work` reads WIP.md to restore exact position -- including which task within a segment was last completed and what the orchestrator planned to do next. See `reference/wip-protocol.md` for details.

## Quick Start

### Brownfield (existing codebase)

1. Install the plugin (see Installation above)
2. Copy `CLAUDE.md.template` to your project root as `CLAUDE.md`. Fill in the project-specific sections below the `PROJECT CONFIG` marker.
3. Run `/gti:map-codebase` to analyze the existing codebase and generate `.planning/codebase/` documents
4. Run `/gti:new-project` to create PROJECT.md and initialize the planning structure
5. Run `/gti:create-roadmap` to define phases
6. Run `/gti:progress` to begin the first phase

### Greenfield (new project)

1. Install the plugin (see Installation above)
2. Copy `CLAUDE.md.template` to your project root as `CLAUDE.md`. Fill in the project-specific sections below the `PROJECT CONFIG` marker.
3. Run `/gti:new-project` to create PROJECT.md and initialize the planning structure
4. Run `/gti:create-roadmap` to define phases
5. Run `/gti:progress` to begin the first phase

*Skip `/gti:map-codebase` for greenfield -- there is nothing to map yet. Run it later after initial code is written.*

## Commands Reference

All commands are invoked as `/gti:<command>`.

| Command | Description |
|---------|-------------|
| `progress` | Check project status and route to the next action |
| `new-project` | Initialize PROJECT.md and the .planning/ structure |
| `map-codebase` | Analyze codebase with parallel agents, produce 7 reference documents |
| `create-roadmap` | Create a phased roadmap from PROJECT.md |
| `research` | Research a topic or phase before planning |
| `plan-phase` | Create a detailed execution plan for a specific phase |
| `execute` | Execute the current approved plan |
| `verify` | Run full verification suite (type checking, tests, lint) |
| `pause-work` | Create a context handoff document for session breaks |
| `resume-work` | Restore context and resume from a previous session |
| `add-issue` | Log a deferred issue or enhancement to ISSUES.md |
| `review-issues` | Triage deferred issues and decide which to address |
| `metrics` | View and update project execution metrics |

## Skills

| Skill | Purpose |
|-------|---------|
| `gti-orchestrator` | Core workflow: state management, agent coordination, checkpoint handling |
| `mapping-codebase` | Spawns 4 parallel agents to produce 7 codebase analysis documents (STACK, ARCHITECTURE, STRUCTURE, CONVENTIONS, TESTING, INTEGRATIONS, CONCERNS) |

## Agents

| Agent | Purpose | Allowed Tools |
|-------|---------|---------------|
| `researcher` | Gather context, find relevant files, identify existing patterns | Read, Glob, Grep, WebSearch, WebFetch |
| `planner` | Create structured PLAN.md with tasks, segments, and checkpoints | Read, Write, Glob, Grep |
| `executor` | Implement plan segments, write code and tests, commit work | Read, Write, Edit, Bash, Glob, Grep |
| `reviewer` | Verify completion, run tests, validate against plan requirements | Read, Bash, Glob, Grep |

## Reference Materials

The `skills/gti-orchestrator/reference/` directory contains guidance that the orchestrator injects into agent prompts when relevant:

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

**Adding technology-specific pitfalls** -- Create a new file at `skills/gti-orchestrator/reference/pitfalls/<technology>.md`. The orchestrator will inject it when spawning agents that work with that technology.

**Adding templates** -- Place new templates in `skills/gti-orchestrator/templates/` or `skills/mapping-codebase/templates/`. Reference them from the relevant SKILL.md or agent instructions.

**Adding commands** -- Create a new `.md` file in `commands/gti/` with YAML frontmatter (name, description, allowed-tools). The command becomes available as `/gti:<name>`.

**Project-specific configuration** -- Edit the project-specific sections of `CLAUDE.md` (services, ports, build commands, testing tiers). The orchestrator discipline section and GTI workflow section remain unchanged across projects.
