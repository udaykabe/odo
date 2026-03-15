---
name: plan-phase
description: Create detailed execution plan for a phase
allowed-tools: Read, Write, Task, AskUserQuestion
---

# /gti:plan-phase [phase-number]

Create a detailed PLAN.md for the specified phase.

## Arguments

- `phase-number` - Phase to plan (e.g., `1`, `2.1`)

## Process

1. **Read context**
   - `.planning/PROJECT.md`
   - `.planning/ROADMAP.md`
   - `.planning/STATE.md`
   - Previous phase summaries if applicable

2. **Research phase requirements**
   - Spawn `gti-researcher` with phase scope
   - Gather technical requirements
   - Identify files to modify

3. **Spawn planner agent**
   - Use `gti-planner` with research findings
   - Create structured PLAN.md

4. **Review plan with user**

   Present:
   ```markdown
   ## Phase XX Plan

   **Objective**: [goal]
   **Tasks**: [count]
   **Checkpoints**: [count]
   **Segments**: [count]

   ### Task Summary
   1. [task description]
   2. [task description]
   ...

   ### Checkpoint Summary
   - Task N: [checkpoint type] - [reason]
   ```

5. **Get approval**
   - User approves → Ready for execution
   - User requests changes → Modify and re-present

6. **Update STATE.md**
   - Current plan: XX-YY-PLAN.md
   - Status: Plan approved, ready for execution

## Output

Created plan at `.planning/phases/XX-phase-name/XX-YY-PLAN.md`

Suggest `/gti:execute` as next step.
