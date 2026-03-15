# Phase Numbering

## Standard Phases

Phases use two-digit numbering:
```
01-initial-setup
02-core-feature
03-api-layer
...
```

## Plans Within Phases

Plans use phase-plan numbering:
```
.planning/phases/
├── 01-initial-setup/
│   ├── 01-01-PLAN.md      # First plan for phase 1
│   ├── 01-01-SUMMARY.md
│   ├── 01-02-PLAN.md      # Second plan (if needed)
│   └── 01-02-SUMMARY.md
├── 02-core-feature/
│   ├── 02-01-PLAN.md
│   └── 02-01-SUMMARY.md
```

## Inserting Urgent Work

Use decimal phases for urgent insertions:
```
02-core-feature      # Existing
02.1-hotfix          # Inserted urgent work
03-api-layer         # Existing (unchanged)
```

This avoids renumbering existing phases.

## Progress Tracking

In ROADMAP.md:
```markdown
## Phases

- [x] 01 - Initial Setup (complete)
- [x] 02 - Core Feature (complete)
- [ ] 02.1 - Hotfix (inserted, in progress)
- [ ] 03 - API Layer (pending)
```

## File Naming

For decimal phases:
```
.planning/phases/
├── 02.1-hotfix/
│   ├── 02.1-01-PLAN.md
│   └── 02.1-01-SUMMARY.md
```
