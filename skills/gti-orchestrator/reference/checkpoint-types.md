# Checkpoint Types

## Task Types in PLAN.md

### `type="auto"`
Execute without stopping. Default for most tasks.

### `type="checkpoint:verify"`
User verifies automated work before proceeding.
- Show diff or output
- Wait for approval
- Continue or fix based on feedback

### `type="checkpoint:decision"`
User chooses between options.
- Present 2-4 clear options
- Explain trade-offs
- Wait for selection
- Proceed with chosen approach

### `type="checkpoint:human-action"`
User performs manual step.
- Describe what user needs to do
- Wait for confirmation
- Examples: authentication, external service setup, physical testing

## Segment Boundaries

Checkpoints define segment boundaries:
```
Segment 1: [tasks 1-3]
Checkpoint: verify
Segment 2: [tasks 4-6]
Checkpoint: decision
Segment 3: [tasks 7-9]
```

Each segment can run in a fresh sub-agent context.

## Routing Rules

After checkpoint completion:
- `verify` → Next segment can start fresh (verification doesn't affect next tasks)
- `decision` → Next segment needs decision context (run in main or pass decision)
- `human-action` → Next segment can start fresh after confirmation
