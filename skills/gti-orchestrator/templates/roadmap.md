# Roadmap Template

Use this structure for ROADMAP.md.

```markdown
# Project Roadmap

## Current Milestone: [Milestone Name]

## Phases

### Completed
- [x] **01 - Phase Name** - Brief description
  - Completed: YYYY-MM-DD
  - Summary: [one line]

### In Progress
- [ ] **02 - Phase Name** - Brief description
  - Status: Planning | Executing | Review
  - Current plan: 02-01-PLAN.md

### Upcoming
- [ ] **03 - Phase Name** - Brief description
  - Dependencies: [phases that must complete first]
  - Estimated tasks: ~N

- [ ] **04 - Phase Name** - Brief description
  - Dependencies: 03
  - Estimated tasks: ~N

## Inserted Phases
- [ ] **02.1 - Urgent Fix** - [description]
  - Inserted: YYYY-MM-DD
  - Reason: [why urgent]

## Progress Metrics
| Metric | Value |
|--------|-------|
| Phases complete | X/Y |
| Current phase | NN |
| Plans executed | N |

## Dependencies Graph
```
01 ─┬─> 02 ───> 03 ───> 04
    │           ↑
    └─> 02.1 ───┘
```
```

## Guidelines

1. Keep phase descriptions brief
2. Track completion dates
3. Note dependencies explicitly
4. Use decimal numbering for insertions
5. Update progress metrics after each phase
