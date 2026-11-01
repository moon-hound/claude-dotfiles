#!/usr/bin/env bash
# Injects CCPM's ranked priority list (from the Architect Gate) on the first
# user prompt of a session, so Claude can tell the user if something higher
# priority exists than what they're about to start on.
# UserPromptSubmit hook. Fail-open on any Gate/network problem -- advisory
# only, never blocks the prompt.
#
# Fires once per session: marks itself done via a temp file keyed by session_id,
# since UserPromptSubmit has no native "first prompt only" matcher.

set -uo pipefail

GATE_URL="${GATE_URL:-http://192.168.1.234:8787/query}"

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
[ -z "$SESSION_ID" ] && exit 0

MARKER_DIR="${TMPDIR:-/tmp}/claude-ccpm-priority-check"
mkdir -p "$MARKER_DIR" 2>/dev/null
MARKER_FILE="$MARKER_DIR/$SESSION_ID"

# Already ran this session -- skip silently.
[ -f "$MARKER_FILE" ] && exit 0
touch "$MARKER_FILE" 2>/dev/null

PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // empty' 2>/dev/null || true)

RESPONSE=$(curl -sS --max-time 3 -X POST "$GATE_URL" \
  -H 'Content-Type: application/json' \
  -d '{"question":"what should I work on next"}' 2>/dev/null) || exit 0

[ -z "$RESPONSE" ] && exit 0

RANKED=$(printf '%s' "$RESPONSE" | jq -c '.ranked_actions // []' 2>/dev/null || true)
[ -z "$RANKED" ] || [ "$RANKED" = "[]" ] && exit 0

CONTEXT=$(jq -n --argjson ranked "$RANKED" --arg prompt "$PROMPT" '
  "CCPM priority check (Architect Gate, first prompt this session): the user is about to work on something. Here is the current ranked_actions list from the Gate (highest score = highest priority, unblocks = how many in-flight projects it frees):\n\n" +
  ($ranked | tostring) +
  "\n\nCompare the user'"'"'s request below against this list. If a clearly higher-priority item exists (higher score, critical/high severity, or unblocks >= 2) that is NOT what they asked for, tell them in your first reply: name the higher-priority item, cite the score/severity/unblocks reason, and ask if they want to switch -- then proceed with whatever they choose. If their request already matches the top item, or nothing else outranks it, say nothing about this and just proceed.\n\nUser'"'"'s request: " + $prompt
')

jq -n --arg ctx "$CONTEXT" '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":$ctx}}'
exit 0
