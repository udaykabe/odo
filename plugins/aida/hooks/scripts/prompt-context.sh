#!/usr/bin/env bash
# AIDA — inject the current project position into each user prompt.
# Keeps the orchestrator anchored to phase / next-action / gate status without
# re-reading STATE.md every turn. Compact and best-effort; silent if no project.
set -uo pipefail
input="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0
cwd="$(printf '%s' "$input" | jq -r '.cwd // "."')"

state="$cwd/.planning/STATE.md"
[ -f "$state" ] || exit 0

ctx="$(grep -iE 'current (position|phase)|next action|commit-gate|escape-pending|^status:' "$state" | head -8)"
[ -n "$ctx" ] || exit 0

jq -n --arg c "AIDA position (from .planning/STATE.md):
$ctx" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$c}}'
exit 0
