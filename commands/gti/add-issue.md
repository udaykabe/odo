---
name: add-issue
description: Log a deferred issue or enhancement to ISSUES.md
allowed-tools: Read, Write
---

# /gti:add-issue [description]

Log an issue for future consideration.

## Arguments

- `description` - Brief description of the issue/enhancement

## Process

1. **Read current issues**
   - Load `.planning/ISSUES.md`

2. **Generate issue ID**
   - Format: `ISS-NNN` (sequential)

3. **Append issue**
   ```markdown
   ## ISS-NNN: [Title]

   **Added**: [timestamp]
   **Phase**: [current phase]
   **Priority**: [low|medium|high]
   **Type**: [bug|enhancement|refactor|debt]

   ### Description
   [Full description]

   ### Context
   [Why this was deferred]
   ```

4. **Confirm addition**

## Output

Issue ID and confirmation.
