# AIDA Framework Consolidation — Spec

**Status:** DRAFT for review · **Owner:** Uday Kabe · **Scope:** `udaykabe/odo` → `plugins/aida`, the standalone `agentic-dev` skill, and Claude Code settings/hooks (user + project).

This is the "spec first" deliverable. Nothing is refactored until this is approved. Sections marked **⛳ DECISION** need your sign-off.

---

## 1. Goal

Turn a scattered, partly-duplicated set of skills, agents, and (absent) hooks into **one** coherent, minimal, self-improving development framework — AIDA — where every piece has a single home, a single vocabulary, and gates that are *enforced*, not merely documented.

**Guiding constraints (from you):**
1. **Minimal surface.** Few agents/skills/commands. Cognitive load is the enemy.
2. **No conflicting instructions.** One methodology, one state model, one vocabulary.
3. **Enforce + automate.** Hooks hard-block critical gates and automate the chores.
4. **Single source of truth.** Everything versions together in the `odo` repo.

---

## 2. Core decision — consolidation direction  ⛳ DECISION

**Recommended: Option 1 (merge `agentic-dev` into AIDA), executed with Option 3's soul.**

Keep AIDA's working skeleton — real `subagent_type`s, phase/roadmap state, HITL checkpoints, WIP resumption, graduated verification, codebase mapping. **Absorb** `agentic-dev`'s three unique assets as *first-class* pipeline elements (not bolt-ons):

- **Escape catalog** — the durable learning asset (`.planning/ESCAPES.md`).
- **Retrospective** — end-of-phase learning capture.
- **Audit gate** — process-adherence check distinct from code review.

Then **retire** the standalone `agentic-dev` skill. Rationale for Option 1 over Option 3 is in the comparison table (chat); short version: Option 3's only real edge — a leaner learning-centric mental model — is reproducible inside Option 1 by pruning hard and elevating the catalog, without throwing away infrastructure that already runs.

---

## 3. The minimalism fork — the 12 role-agents  ✅ DECIDED

Your `odo` working tree had **uncommitted** new agents:

- `agents/design/`: brand-guardian, ui-designer, ux-researcher, visual-storyteller, whimsy-injector
- `agents/engineering/`: ai-engineer, backend-architect, devops-automator, frontend-developer, mobile-app-builder, rapid-prototyper, **test-writer-fixer**

This was a **4 → 16 agent** expansion — the source of the `test-writer-fixer` reference in `stockvaluation/CLAUDE.md` and a direct violation of constraint #1.

**Decision:** **Drop 11 of the 12.** Delete `agents/design/` (5) and the 6 engineering role-agents (ai-engineer, backend-architect, devops-automator, frontend-developer, mobile-app-builder, rapid-prototyper). "Frontend developer" vs "backend architect" is a *hat the executor wears*, injected as context per task — not a separate agent type with its own instructions that can drift and conflict.

**Exception — `test-writer-fixer` is promoted, not dropped.** It becomes a proper top-level AIDA agent acting as an independent **watchdog** (see §4.1). This is deliberate: an independent tester with fresh context is the strongest guard against the `test-theater` / `didn't-test` escape classes, precisely because it does *not* share the executor's context or its incentive to declare its own work done.

---

## 4. Target architecture

### 4.1 Agents — 5 (4 core process roles + 1 watchdog)

**Canonical pipeline:**
```
researcher → planner → (HITL approval) → executor → test-writer-fixer → reviewer
```

| Agent | Role | Key change |
|-------|------|-----------|
| `researcher` | Gather context before planning | unchanged |
| `planner` | Produce `PLAN.md` | plan template gains an explicit **acceptance-criteria + verification-command** block per task |
| `executor` | Implement a segment | writes implementation + first-pass tests, runs verify before reporting. Does **not** own final test integrity — that's the watchdog's job. |
| `test-writer-fixer` | **Independent watchdog** between executor and reviewer | writes/extends tests against **observed** behavior, runs the suite, fixes brittle/outdated tests — but **reports** (never silently fixes) real product bugs back to the orchestrator. Feeds `test-theater`/`didn't-test` escape candidates. **Must NOT commit** (the old "commit before returning" constraint is removed — it violates the review gate). Fresh context by design — it does not trust the executor's report. |
| `reviewer` | Verify + spec/quality review + **audit** | absorbs `agentic-dev`'s spec-review, quality-review, and **audit** passes into one graduated report; emits candidate **escape** entries. Read-only (writes no code or tests). |

Result: agentic-dev's 4 prompt-template "agents" collapse into AIDA's real agents; `test-writer-fixer` is kept independent as a watchdog. Net agent count: **5**.

**Watchdog vs reviewer — why both:** `test-writer-fixer` *writes and fixes tests* (needs Write/Edit/Bash); `reviewer` is *read-only* verification + audit + escape logging. Different tools, different intent, no overlap. The watchdog makes the tests real; the reviewer judges whether the phase is done.

**`test-writer-fixer` adaptation checklist (from the imported generic agent):**
- Remove the `Commit work before returning` constraint (conflicts with the review-before-commit hook).
- Add AIDA frontmatter `allowed-tools: Read, Write, Edit, Bash, Glob, Grep`.
- Rewrite the verbose `<example>` block into AIDA's concise agent format.
- Wire it to the AIDA state model: reads the segment's `PLAN.md`/`SUMMARY.md`, records real-bug findings for `STATE.md`/`ISSUES.md`, and flags escape candidates for `ESCAPES.md`.
- Enforce "test against observed behavior" (capture actual output/DOM before writing selectors) — directly closes ESC-004.

### 4.2 Skills — keep 2, retire 1

- **`orchestrating-agents`** (augmented): the single pipeline. Adds the escape-catalog loop, the retrospective step, and the enforced review→commit gate.
- **`mapping-codebase`** (unchanged): parallel codebase analysis → 7 docs.
- **`agentic-dev`** → **RETIRED.** Its content is migrated (see §6) and the `~/.claude/skills/agentic-dev/` dir is deleted so it can never be invoked to fight AIDA.

### 4.3 Commands — prune 13 → 8  ⛳ DECISION

| Keep | Merge / Cut |
|------|-------------|
| `progress` (router — folds in `metrics`) | `metrics` → into `progress` |
| `new-project` | |
| `map-codebase` | |
| `create-roadmap` | |
| `plan-phase` (folds in `research`) | `research` → into `plan-phase` (research is always a prelude to planning) |
| `execute` | |
| `verify` | |
| `handoff` (replaces `pause-work` + `resume-work`) | two halves of one idea |
| `issues` (replaces `add-issue` + `review-issues`) | one command, add/triage subverbs |

Final set: **new-project, map-codebase, create-roadmap, plan-phase, execute, verify, progress, handoff, issues** (9). Trim further if any prove thin. *(Open: is `create-roadmap` distinct enough from `new-project`, or fold together → 8?)*

### 4.4 State model — one canonical layout

```
.planning/
  PROJECT.md        # vision + verification commands (source of truth)
  ROADMAP.md        # phases
  STATE.md          # current position, decisions, phase status
  WIP.md            # live session state for resumption
  ISSUES.md         # deferred work
  ESCAPES.md        # NEW — the escape catalog (from agentic-dev)
  phases/NN-name/   # NN-MM-PLAN.md, NN-MM-SUMMARY.md
  codebase/         # 7 mapping docs
```

`agentic-dev`'s `active-sprint.md` / `audit-trail.md` / `implementation-plan.md` are **retired** and mapped onto `STATE.md` + `WIP.md` + `ROADMAP.md`. Escape entries live in `ESCAPES.md`.

### 4.5 Hooks — new layer (enforce + automate)  ⛳ DECISION

Ship a `hooks/` dir in the plugin, wired via the plugin's `settings.json`. Proposed set (each realistic to implement against Claude Code's hook events):

**Enforce (hard block):** *(implemented in `hooks/scripts/gate-commit.sh`, PreToolUse/Bash)*
- **Review-before-commit gate** — a code `git commit` is blocked unless `STATE.md` contains the marker `Commit-Gate: APPROVED` (reviewer sets it on APPROVE; executor resets to `LOCKED` at segment start). **Planning-only commits** (every staged path under `.planning/`) are exempt so plans/state can still be committed. Guards ESC-009 process-bypass.
- **Escape-before-commit gate** — if `STATE.md` reads `Escape-Pending: yes` (a post-review fix was made), the commit is blocked until the escape is logged in `ESCAPES.md` and the flag cleared to `no`.
- Both markers are literal `Key: Value` lines. The gate is **opt-in per project**: it enforces only when a `Commit-Gate:` line exists in `STATE.md` (`new-project` seeds it; existing projects opt in by adding it), so shipping v2 does not retroactively block commits in projects that predate the marker. The gate fails **open** if `jq`/`git` are missing so it never wedges a repo. Verified against 7 scenarios (deny un-approved, allow planning-only, allow post-approve, deny unlogged-escape, ignore non-commit, ignore non-AIDA repo, ignore un-adopted project).

**Automate (assist):**
- **Session-start resumption** — `SessionStart`: if `WIP.md` exists, surface it (already in `CLAUDE.md.template`; move enforcement into a hook so it can't be skipped).
- **Stop checkpoint** — `Stop`: warn if `WIP.md` is stale relative to work done this turn.
- **Prompt context injection** — `UserPromptSubmit`: inject the current phase + next-action line from `STATE.md` so the orchestrator never loses the thread.

*(Note: hooks are session-global — they can't tell "orchestrator" from "executor" context. So enforcement keys off **state files + command patterns**, which is robust. Blunter ideas like "block all Edits from the orchestrator" are not implementable and are excluded.)*

#### Commit choreography (resolves an AIDA↔gate conflict)

AIDA's executor historically **committed each segment before returning**, and the imported `test-writer-fixer` also committed. That contradicts the approved review-before-commit gate. Resolution:

- **executor** and **test-writer-fixer** do their work but **do not commit** — they leave changes staged, write their summaries, and update `STATE.md`/`WIP.md`.
- The **reviewer** runs on the staged (uncommitted) work. On `APPROVE`, it marks the segment/phase `APPROVED` in `STATE.md`.
- The **commit happens after `APPROVE`** as an explicit orchestrator step. The hook gate blocks any `git commit` while the current segment/phase is not `APPROVED`.

Net effect: the **reviewed unit == the committed unit**, the gate is meaningful, and per-segment history is replaced by per-*approved*-segment history (a strict improvement for auditability).

---

## 5. What this eliminates (the incoherence, itemized)

1. Two competing methodologies → **one** (agentic-dev retired, absorbed).
2. `test-writer-fixer` reference → made **real**: promoted to an independent watchdog agent in the canonical pipeline (was dangling because the agent was mid-import and unaligned).
3. No learning loop → `ESCAPES.md` + retrospective are first-class.
4. No hooks → an enforce+automate hook layer.
5. State-model drift → one canonical `.planning/` layout.
6. Split home (plugin + loose skill) → everything in `odo`, versioned together.

---

## 6. Migration plan (build phases — dogfoodable through AIDA itself)

- **P1 — Freeze & decide.** Approve this spec. Resolve the ⛳ decisions. Revert-or-quarantine the 12 role-agents.
- **P2 — Absorb agentic-dev.** Fold escape catalog → `ESCAPES.md`; audit + spec/quality review → `reviewer`; retrospective → `orchestrating-agents`; integration checks (auth-grep, SSE guards, contract checks) → `executor`/`reviewer` checklists. Migrate ESC-001…011 into the new catalog. Delete the standalone skill.
- **P3 — Prune commands & unify state.** Execute §4.3 merges; update `CLAUDE.md.template` and all command/skill docs to the one vocabulary + state model.
- **P4 — Hook layer.** Implement §4.5; wire `settings.json`; test each hook fires/blocks correctly.
- **P5 — Re-sync consumers.** Update `stockvaluation/CLAUDE.md` (remove `test-writer-fixer`, point at the pruned pipeline). Bump plugin to v2.0.0. Re-install; smoke-test the full pipeline on a throwaway phase.

Each phase is independently reviewable; P5 verifies end-to-end.

---

## 7. Decisions

1. **§2** — ✅ **Option 1** (merge into AIDA), with Option 3's learning loop first-class.
2. **§3** — ✅ **Drop 11** role-agents; **promote `test-writer-fixer`** to an independent watchdog.
3. **§4.1** — ✅ **5 agents.** `test-writer-fixer` stays independent (not folded into executor); audit folds into reviewer.
4. **§4.3** — ⏳ Command prune (13 → 8–9) proceeding as proposed unless vetoed. *Flag any command that must stay standalone.*
5. **§4.5** — ✅ Hook set approved, including the two hard-block gates.
