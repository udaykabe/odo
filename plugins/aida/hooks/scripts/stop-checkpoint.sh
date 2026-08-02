#!/usr/bin/env bash
# AIDA — checkpoint reminder when the agent stops.
# If there are uncommitted CODE changes but no WIP.md capturing them, nudge the
# orchestrator to record position so a session break doesn't lose work.
# Purely informational (never blocks).
set -uo pipefail
input="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0
cwd="$(printf '%s' "$input" | jq -r '.cwd // "."')"

state="$cwd/.planning/STATE.md"
[ -f "$state" ] || exit 0

changes="$(cd "$cwd" 2>/dev/null && git status --porcelain 2>/dev/null | grep -vE '\.planning/' || true)"
[ -n "$changes" ] || exit 0

wip="$cwd/.planning/WIP.md"
if [ ! -f "$wip" ]; then
  echo "AIDA checkpoint: uncommitted code changes exist but there is no .planning/WIP.md. Update WIP.md (or run /handoff save) so this position survives a session break." >&2
fi
exit 0
