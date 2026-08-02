#!/usr/bin/env bash
# AIDA — surface in-progress work at session start.
# If .planning/WIP.md exists, print it so the orchestrator can offer to resume.
set -uo pipefail
input="$(cat)"

cwd="."
if command -v jq >/dev/null 2>&1; then
  cwd="$(printf '%s' "$input" | jq -r '.cwd // "."')"
fi

wip="$cwd/.planning/WIP.md"
[ -f "$wip" ] || exit 0

echo "AIDA: in-progress work detected in .planning/WIP.md — offer to resume before starting new work."
echo "----- WIP.md (first 40 lines) -----"
sed -n '1,40p' "$wip"
echo "-----------------------------------"
exit 0
