#!/usr/bin/env bash
# AIDA — review-before-commit gate (+ escape-before-commit gate).
#
# Blocks `git commit` of CODE changes until the reviewer has marked the work
# APPROVED in .planning/STATE.md (`Commit-Gate: APPROVED`). Planning-only commits
# (every staged path under .planning/) are always allowed, so the orchestrator can
# still commit plans and state. Also blocks if a post-review fix was made but no
# escape was logged (`Escape-Pending: yes`).
#
# Enforcement is fail-open on missing tooling (jq/git) so it never wedges a repo.

set -uo pipefail
input="$(cat)"

# jq is required to parse the event; if absent, do not block.
if ! command -v jq >/dev/null 2>&1; then
  echo "AIDA gate: jq not found; commit gate skipped." >&2
  exit 0
fi

cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"
cwd="$(printf '%s' "$input" | jq -r '.cwd // "."')"

# Only intercept git commits.
printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])git[[:space:]]+commit([[:space:]]|$)' || exit 0

state="$cwd/.planning/STATE.md"
# Not an AIDA project → don't interfere.
[ -f "$state" ] || exit 0

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# Gate is OPT-IN per project: only enforce if a `Commit-Gate:` marker exists in
# STATE.md. Projects that haven't adopted the gate (no marker) are unaffected.
# `new-project` seeds `Commit-Gate: LOCKED`; existing projects add it to opt in.
grep -qiE '^[[:space:]]*Commit-Gate:' "$state" || exit 0

# If everything staged is under .planning/, treat as a plan/state commit → allow.
staged="$(cd "$cwd" 2>/dev/null && git diff --cached --name-only 2>/dev/null || true)"
if [ -n "$staged" ]; then
  if ! printf '%s\n' "$staged" | grep -qvE '^\.planning/'; then
    exit 0
  fi
fi

# Escape must be logged before committing when a post-review fix occurred.
if grep -qiE '^[[:space:]]*Escape-Pending:[[:space:]]*yes' "$state"; then
  deny "AIDA gate: a post-review fix was made but no escape is logged. Add an ESC-NNN entry to .planning/ESCAPES.md, set 'Escape-Pending: no' in STATE.md, then commit."
fi

# Review gate: require the reviewer's APPROVED marker.
if ! grep -qiE '^[[:space:]]*Commit-Gate:[[:space:]]*APPROVED' "$state"; then
  deny "AIDA gate: this code is not reviewer-APPROVED. Run the reviewer — it writes 'Commit-Gate: APPROVED' to STATE.md on APPROVE. Code commits are blocked until then. (Planning-only commits under .planning/ are always allowed.)"
fi

exit 0
