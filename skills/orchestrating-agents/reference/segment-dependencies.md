# Segment Dependencies

Optional feature for parallel segment execution.

## When to Use

- Segments work on independent features/files
- No shared state between segments
- Significant time savings from parallelization

## When NOT to Use

- Segments build on each other's output
- Shared files being modified
- Sequential logic required
- Simple plans (parallelization overhead not worth it)

## Syntax

Add after the Segment Breakdown section in PLAN.md:

```markdown
## Segment Dependencies
- Segment 2 depends on: 1
- Segment 3 depends on: 1
- Segment 4 depends on: 2, 3
- Segment 5: independent
```

## Rules

1. **Unlisted segments are independent** - Can run immediately
2. **Dependencies must complete first** - Segment waits for all listed dependencies
3. **No circular dependencies** - Segment N cannot depend on segment N+
4. **Default behavior** - No dependency section = sequential execution
5. **File ownership must not overlap** - Parallel segments must modify distinct files; if two segments touch the same file, add a dependency between them
6. **Orchestrator spawns parallel agents** - The orchestrator uses `run_in_background=true` when spawning executors for independent segments

## Example

```markdown
## Segment Breakdown
- Segment 1: Tasks 1-2 (backend API)
- Segment 2: Tasks 3-4 (frontend component A)
- Segment 3: Tasks 5-6 (frontend component B)
- Segment 4: Tasks 7-8 (integration tests)

## Segment Dependencies
- Segment 2 depends on: 1
- Segment 3 depends on: 1
- Segment 4 depends on: 2, 3
```

Execution order:
1. Segment 1 runs first
2. Segments 2 and 3 run in parallel (both depend only on 1)
3. Segment 4 waits for both 2 and 3 to complete

## Checkpoint Handling

Checkpoints pause their segment only. Other parallel segments continue.

If a checkpoint requires user input that affects another segment, the segments should have a dependency relationship.
