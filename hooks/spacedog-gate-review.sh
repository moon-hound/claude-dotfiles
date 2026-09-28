#!/usr/bin/env bash
# Queries the spacedog-pm Architect Gate for blast-radius review before Edit|Write.
# PreToolUse hook for Edit|Write operations.
# Exit 2 = block/ask. Exit 0 = allow.
#
# NOT WIRED into settings.json yet -- standalone script only, per phase-lock rule.
# Fails open (exit 0) on any gate/network problem: this is an advisory
# blast-radius check, not a security boundary -- a down gate must never
# block real work.

set -uo pipefail

GATE_URL="http://127.0.0.1:8787/review"

emit() {
  # $1 = decision (deny|ask) ; $2 = reason
  local decision="$1"
  local reason="${2//\"/\\\"}"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$decision" "$reason"
  exit 2
}

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
[ -z "$FILE_PATH" ] && exit 0

PAYLOAD=$(jq -n --arg path "$FILE_PATH" '{path: $path}')
RESPONSE=$(curl -sS --max-time 2 -X POST "$GATE_URL" \
  -H 'Content-Type: application/json' \
  -d "$PAYLOAD" 2>/dev/null) || exit 0

[ -z "$RESPONSE" ] && exit 0

DECISION=$(printf '%s' "$RESPONSE" | jq -r '.decision // empty' 2>/dev/null || true)
REASON=$(printf '%s' "$RESPONSE" | jq -r '.reason // "Gate flagged this change for review."' 2>/dev/null || true)

case "$DECISION" in
  ask)
    emit ask "$REASON" ;;
  force_ask)
    emit ask "HIGH BLAST RADIUS: $REASON" ;;
  allow|"")
    exit 0 ;;
  *)
    exit 0 ;;
esac
