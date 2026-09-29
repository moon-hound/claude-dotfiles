#!/usr/bin/env bash
# Queries the spacedog-pm Architect Gate for blast-radius review before Edit|Write.
# PreToolUse hook adapter for Claude Code and Antigravity.
#
# Contracts:
# - Claude Code: outputs hookSpecificOutput JSON on stdout, exit 2 for ask/deny, exit 0 for allow.
# - Antigravity: outputs {"decision": "...", "reason": "..."} on stdout, exit 0.
#
# Fails open on any gate/network problem: this is an advisory
# blast-radius check, not a security boundary -- a down gate must never
# block real work.

set -uo pipefail

GATE_URL="http://127.0.0.1:8787/review"

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

INPUT=$(cat)

# Mode determination: explicit CLI flag or auto-detection from payload structure
MODE="claude"
if [ "${1:-}" = "--agy" ] || [ "${1:-}" = "--antigravity" ]; then
  MODE="antigravity"
elif [ "${1:-}" = "--claude" ]; then
  MODE="claude"
elif printf '%s' "$INPUT" | jq -e '.toolCall' >/dev/null 2>&1; then
  MODE="antigravity"
fi

emit() {
  local decision="$1"
  local reason="${2//\"/\\\"}"
  if [ "$MODE" = "antigravity" ]; then
    if [ "$decision" = "allow" ] || [ -z "$reason" ]; then
      printf '{"decision":"%s"}\n' "$decision"
    else
      printf '{"decision":"%s","reason":"%s"}\n' "$decision" "$reason"
    fi
    exit 0
  else
    # Claude Code
    if [ "$decision" = "allow" ]; then
      exit 0
    else
      printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$decision" "$reason"
      exit 2
    fi
  fi
}

# Extract target file path depending on agent payload format
if [ "$MODE" = "antigravity" ]; then
  FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.toolCall.args.TargetFile // .toolCall.args.file_path // .toolCall.args.path // empty' 2>/dev/null || true)
else
  FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
fi

[ -z "$FILE_PATH" ] && emit allow ""

PAYLOAD=$(jq -n --arg path "$FILE_PATH" '{path: $path}')
RESPONSE=$(curl -sS --max-time 2 -X POST "$GATE_URL" \
  -H 'Content-Type: application/json' \
  -d "$PAYLOAD" 2>/dev/null) || emit allow ""

[ -z "$RESPONSE" ] && emit allow ""

DECISION=$(printf '%s' "$RESPONSE" | jq -r '.decision // empty' 2>/dev/null || true)
REASON=$(printf '%s' "$RESPONSE" | jq -r '.reason // "Gate flagged this change for review."' 2>/dev/null || true)

case "$DECISION" in
  ask)
    emit ask "$REASON" ;;
  force_ask)
    if [ "$MODE" = "antigravity" ]; then
      emit force_ask "HIGH BLAST RADIUS: $REASON"
    else
      emit ask "HIGH BLAST RADIUS: $REASON"
    fi
    ;;
  allow|"")
    emit allow "" ;;
  *)
    emit allow "" ;;
esac
