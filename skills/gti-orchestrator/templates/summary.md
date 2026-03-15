# Phase Summary Template

Use this structure for SUMMARY.md files.

```markdown
# Summary: Phase XX-YY

## Status: COMPLETE | PARTIAL | BLOCKED

## Accomplishments
- [What was done]
- [Features added]
- [Problems solved]

## Files Modified
| File | Change |
|------|--------|
| path/to/file.ts | Added function X |
| path/to/other.ts | Updated import |

## Deviations
### Deviation 1: [Title]
- **Rule Applied**: [1-5]
- **Reason**: [Why deviation was needed]
- **Action Taken**: [What was done]

## Issues Discovered
Logged to ISSUES.md:
- [Issue description] → ISSUES.md#issue-id

## Decisions Made
- [Decision point]: Chose [option] because [reason]

## Metrics
- Tasks completed: X/Y
- Files modified: N
- Lines changed: +A/-B

## Next Steps
- [What should happen next]
- [Blocking items if any]
```

## Guidelines

1. Be specific about accomplishments
2. List all modified files
3. Document all deviations with rule reference
4. Log discovered issues properly
5. Record decisions for future context
