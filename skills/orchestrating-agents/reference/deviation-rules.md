# Deviation Rules

Rules for handling unexpected situations during execution.

## Rule 1: Auto-Fix Bugs
**Trigger**: Discover bug while implementing
**Action**: Fix inline, document in SUMMARY.md
**Scope**: Same file, related to current task

## Rule 2: Add Critical Functionality
**Trigger**: Missing security, error handling, validation
**Action**: Add it, document in SUMMARY.md
**Scope**: Required for correctness, not nice-to-have

## Rule 3: Fix Blocking Issues
**Trigger**: Missing dependencies, broken imports, config issues
**Action**: Fix to unblock, document in SUMMARY.md
**Scope**: Minimum to proceed

## Rule 4: Ask About Architecture
**Trigger**: New patterns, service layers, database changes
**Action**: Create checkpoint, return to orchestrator
**Scope**: Changes affecting multiple components

## Rule 5: Log Enhancements
**Trigger**: Nice-to-have improvements, refactoring ideas
**Action**: Log to ISSUES.md, continue with task
**Scope**: Non-blocking, future work

## Decision Tree

```
Is it blocking?
├── No → Log to ISSUES.md (Rule 5)
└── Yes → Is it architectural?
    ├── Yes → Checkpoint (Rule 4)
    └── No → Is it critical for correctness?
        ├── Yes → Auto-add (Rule 2)
        └── No → Auto-fix (Rule 1, 3)
```
