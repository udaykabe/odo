---
name: create-roadmap
description: Create project roadmap with phases
allowed-tools: Read, Write, Task, AskUserQuestion
---

# /gti:create-roadmap

Create a roadmap breaking the project into phases.

## Process

1. **Read project context**
   - `.planning/PROJECT.md` - Goals and constraints
   - `.planning/codebase/` - If brownfield, existing structure

2. **Analyze scope**
   - Spawn `researcher` if needed for technical discovery
   - Identify major work areas

3. **Propose phases**

   Present 3-7 phases to user:
   ```markdown
   ## Proposed Phases

   1. **[Phase Name]** - [description]
      - Estimated scope: [small/medium/large]
      - Dependencies: none

   2. **[Phase Name]** - [description]
      - Estimated scope: [small/medium/large]
      - Dependencies: Phase 1
   ```

4. **Get user feedback**
   - Confirm phases
   - Allow additions/removals
   - Adjust scope estimates

5. **Write ROADMAP.md**

   Create roadmap following the structure in `.planning/ROADMAP.md` conventions

6. **Update STATE.md**
   - Set current phase to 01
   - Status: Ready for planning

## Output

Created roadmap with phase breakdown. Suggest `/gti:plan-phase 1` as next step.
