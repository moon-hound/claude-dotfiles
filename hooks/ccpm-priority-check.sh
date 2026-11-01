#!/usr/bin/env bash
# Injects the Architect Gate's ranked priority list on the first user prompt of
# a session, so Claude can tell the user if something higher priority exists
# than what they're about to start on.
#
# Division of labor (handover 2026-10-28, confirmed by research 2026-11-01):
# CCPM owns backlog/classification (PRD/epic/task, depends_on). The Gate owns
# priority/risk ranking (score/severity/unblocks) computed from its own infra
# dependency graph, fed by GitHub issues CCPM creates (project:gh-NN == issue
# NN). CCPM has no priority field by design -- this hook does NOT invent one,
# it defers to the Gate, which is the actual source of ranking signal.
#
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

CONTEXT=$(jq -nr --argjson ranked "$RANKED" --arg prompt "$PROMPT" '
  "CCPM priority check (Architect Gate /query, first prompt this session): the user is about to work on something. Below is the Gate'"'"'s current ranked_actions list -- its computed priority signal (score/severity/unblocks), derived from its own infra dependency graph and fed by GitHub issues CCPM created (target_id project:gh-N == GitHub issue N on moon-hound/claude-config). CCPM itself has no priority field by design; the Gate is the source of ranking truth, not CCPM'"'"'s files.\n\n" +
  ($ranked | tostring) +
  "\n\nCompare the user'"'"'s request below against this list. If a CLEARLY higher-priority item exists (higher score, critical/high severity, or unblocks >= 2) that is NOT what they asked for, say so in your first reply: name the item (and its gh-N issue if present), cite the score/severity/unblocks reason, and ask if they want to switch -- then proceed with whatever they choose either way, no hard block. If their request already matches the top item, or nothing else clearly outranks it, say nothing about this and just proceed normally.\n\nUser'"'"'s request: " + $prompt
')

jq -n --arg ctx "$CONTEXT" '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":$ctx}}'
exit 0
