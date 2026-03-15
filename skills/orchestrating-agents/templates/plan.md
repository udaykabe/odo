# Phase Plan Template

Use this structure for PLAN.md files.

```markdown
# Phase XX-YY: [Phase Name]

## Objective
[One sentence describing what this phase accomplishes]

## Context
@.planning/PROJECT.md
@.planning/ROADMAP.md
@path/to/relevant/file.ts

## Tasks

<task id="1" type="auto">
Task description with specific details
</task>

<task id="2" type="auto">
Another task
</task>

<task id="3" type="checkpoint:verify">
Verify: [what user should check]
</task>

<task id="4" type="auto">
Continue after verification
</task>

<task id="5" type="checkpoint:decision">
Decision needed:
- Option A: [description]
- Option B: [description]
</task>

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Unit tests passing
- [ ] E2E mocked tests passing
- [ ] Smoke tests passing (with real backend interactions)
- [ ] No console errors in smoke test execution

## Segment Breakdown
- Segment 1: Tasks 1-2 (autonomous)
- Checkpoint: Task 3 (verify)
- Segment 2: Task 4 (autonomous)
- Checkpoint: Task 5 (decision)

## Segment Dependencies (Optional)
- Segment 2 depends on: 1
- Segment 3: independent
```

## Guidelines

1. Keep tasks atomic and specific
2. Use @path references for context
3. Place checkpoints at natural boundaries
4. 5-15 tasks per plan
5. Clear success criteria
6. Add Segment Dependencies only when parallel execution is beneficial
