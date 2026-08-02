# Escape Catalog

> This file is the framework's most valuable asset. It grows with experience.
> Every escape makes the process better. Never delete entries — only add or refine.
>
> Copied to `.planning/ESCAPES.md` at project init. Seed it empty; let it grow from real escapes.

## What is an "escape"?

An **escape** is any defect or process failure that got past the pipeline — a bug the reviewer approved, a fix the orchestrator had to make *after* review, or a methodology step that was skipped. Each escape is logged, classified, and turned into a checklist patch so the same class can't recur.

## Escape classes

- `didn't-test` — code written without running it against the real system
- `didn't-read-docs` — assumed library/API behavior without checking the installed version or docs
- `wrong-assumption` — guessed field names, response shapes, or behavior
- `integration-gap` — components work in isolation but break when connected
- `test-theater` — tests exist but verify imagined behavior, not actual behavior
- `documentation-drift` — code changed but requirements/status docs weren't updated
- `process-bypass` — methodology steps skipped entirely (no plan, no watchdog, no review)

## Entry format

```markdown
### ESC-NNN: <short title> (<date>, <phase>)

- **What:** <what escaped>
- **Class:** <one of the classes above>
- **Root cause:** <why it wasn't caught>
- **Executor patch:** <what to add to the executor's checklist>
- **Watchdog patch:** <what the test watchdog should now check> (if test-related)
- **Reviewer patch:** <what to add to the reviewer's audit checks>
- **Hook candidate:** <could this be enforced by a hook instead of a checklist? how?>
```

## Who writes entries

- **reviewer** — drafts a candidate entry when its audit pass detects a new failure pattern.
- **orchestrator** — during the phase retrospective, promotes confirmed candidates and, where a check has proven reliable, opens a `Hook candidate` for enforcement.

---

## Entries

_(none yet — the catalog starts empty and grows from real escapes)_
