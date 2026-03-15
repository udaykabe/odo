---
name: map-codebase
description: Analyze codebase with parallel agents to produce .planning/codebase/ documents
argument-hint: "[optional: specific area to map, e.g., 'api' or 'auth']"
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Write
  - Task
---

<objective>
Analyze existing codebase using parallel Explore agents to produce structured codebase documents.

This command spawns multiple Explore agents to analyze different aspects of the codebase in parallel, each with fresh context.

Output: .planning/codebase/ folder with 7 structured documents about the codebase state.
</objective>

<context>
Focus area: $ARGUMENTS (optional - directs agents to specific subsystem)

**Load project state if exists:**
Check for .planning/STATE.md - loads context if project already initialized

**This command can run:**
- Before /gti:new-project (brownfield codebases) - creates codebase map first
- After /gti:new-project (greenfield codebases) - updates codebase map as code evolves
- Anytime to refresh codebase understanding
</context>

<when_to_use>
**Use map-codebase for:**
- Brownfield projects before initialization (understand existing code first)
- Refreshing codebase map after significant changes
- Onboarding to an unfamiliar codebase
- Before major refactoring (understand current state)
- When STATE.md references outdated codebase info

**Skip map-codebase for:**
- Greenfield projects with no code yet (nothing to map)
- Trivial codebases (<5 files)
</when_to_use>

<process>
This command delegates to the mapping-codebase SKILL.
Follow the process defined in `skills/mapping-codebase/SKILL.md`.
</process>

<success_criteria>
See `skills/mapping-codebase/SKILL.md` for detailed success criteria.
- [ ] .planning/codebase/ directory created with all 7 documents
- [ ] Documents follow SKILL template structure
- [ ] User knows next steps
</success_criteria>
