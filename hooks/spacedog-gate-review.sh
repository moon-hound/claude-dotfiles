#!/usr/bin/env bash
# Queries the spacedog-pm Architect Gate for blast-radius review before Edit|Write.
# PreToolUse hook adapter for Claude Code and Antigravity.
#
# Contracts:
# - Claude Code: outputs hookSpecificOutput JSON on stdout, exit 0 always. Exit 2 is a hard
#   unconditional block in Claude Code (ignores permissionDecision) -- never use it for "ask",
#   only exit 0 + permissionDecision lets the user actually be prompted.
# - Antigravity: outputs {"decision": "...", "reason": "..."} on stdout, exit 0.
#
# Fails open on any gate/network problem: this is an advisory
# blast-radius check, not a security boundary -- a down gate must never
# block real work.

set -uo pipefail

GATE_URL="${GATE_URL:-http://192.168.1.234:8787/review}"

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
  local reason="${2:-}"
  if [ "$MODE" = "antigravity" ]; then
    if [ "$decision" = "allow" ] || [ -z "$reason" ]; then
      printf '{"decision":"%s"}\n' "$decision"
      jq -nc --arg d "$decision" '{"decision": $d}'
    else
      printf '{"decision":"%s","reason":"%s"}\n' "$decision" "$reason"
      jq -nc --arg d "$decision" --arg r "$reason" '{"decision": $d, "reason": $r}'
    fi
    exit 0
  else
    # Claude Code: exit 0 always. Exit 2 would block unconditionally and skip
    # the JSON entirely, so "ask" must ride on exit 0 to actually prompt the user.
    if [ "$decision" = "allow" ]; then
      exit 0
    else
      printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$decision" "$reason"
      jq -nc --arg d "$decision" --arg r "$reason" \
        '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":$d,"permissionDecisionReason":$r}}'
      exit 0
    fi
  fi
}

# Extract target file path + proposed new content depending on agent payload
# format. NEW_CONTENT feeds the gate's mechanical signature-diff check; if it
# can't be determined (unknown field names, ambiguous Edit match), it's left
# empty and the gate just skips that check -- fails open, same as everything
# else in this script.
if [ "$MODE" = "antigravity" ]; then
  FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.toolCall.args.TargetFile // .toolCall.args.file_path // .toolCall.args.path // empty' 2>/dev/null || true)
  NEW_CONTENT=$(printf '%s' "$INPUT" | jq -r '.toolCall.args.CodeContent // .toolCall.args.Content // .toolCall.args.content // .toolCall.args.TargetContent // empty' 2>/dev/null || true)
  NEW_STRING=""
else
  TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)
  FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
  if [ "$TOOL_NAME" = "Write" ]; then
    NEW_CONTENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null || true)
    NEW_STRING=""
  else
    NEW_CONTENT=""
    OLD_STRING=$(printf '%s' "$INPUT" | jq -r '.tool_input.old_string // empty' 2>/dev/null || true)
    NEW_STRING=$(printf '%s' "$INPUT" | jq -r '.tool_input.new_string // empty' 2>/dev/null || true)
  fi
fi

[ -z "$FILE_PATH" ] && emit allow ""

# Normalize relative or platform paths portably
FILE_PATH=$(python3 -c "import os,sys; print(os.path.abspath(sys.argv[1]))" "$FILE_PATH" 2>/dev/null || python -c "import os,sys; print(os.path.abspath(sys.argv[1]))" "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")

# An Edit (old_string/new_string patch, not full content) -- reconstruct the
# resulting file text by applying the patch to the current on-disk content.
# Base64-encoded in transit: old/new strings can contain quotes, backslashes,
# and newlines that would otherwise be mangled crossing the shell/python
# boundary.
if [ -z "$NEW_CONTENT" ] && [ -n "$NEW_STRING" ] && [ -f "$FILE_PATH" ]; then
  OLD_B64=$(printf '%s' "$OLD_STRING" | base64 | tr -d '\n')
  NEW_B64=$(printf '%s' "$NEW_STRING" | base64 | tr -d '\n')
  NEW_CONTENT=$(python3 -c "
import sys, base64
path = sys.argv[1]
old = base64.b64decode(sys.argv[2]).decode('utf-8', 'replace')
new = base64.b64decode(sys.argv[3]).decode('utf-8', 'replace')
try:
    content = open(path, encoding='utf-8').read()
except OSError:
    sys.exit(1)
if content.count(old) == 1:
    sys.stdout.write(content.replace(old, new, 1))
else:
    sys.exit(1)
" "$FILE_PATH" "$OLD_B64" "$NEW_B64" 2>/dev/null || true)
OLD_CONTENT=""
if [ -n "$NEW_CONTENT" ] && [ -f "$FILE_PATH" ]; then
  OLD_CONTENT=$(cat "$FILE_PATH" 2>/dev/null || true)
fi

PAYLOAD=$(jq -n --arg path "$FILE_PATH" --arg content "$NEW_CONTENT" --arg old "$OLD_CONTENT" \
  '{path: $path} + (if $content != "" then {new_content: $content} else {} end) + (if $old != "" then {old_content: $old} else {} end)')
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
