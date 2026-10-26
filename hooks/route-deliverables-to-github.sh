#!/usr/bin/env bash
# Blocks writing durable deliverables (undo guides, changelogs, decision records,
# reference docs) to the Nextcloud export folder. Forces GitHub issue instead, per
# CCPM (GitHub is SoT). Ephemeral/explicitly-requested one-off files pass through.
# PreToolUse hook for Write operations. Exit 2 = block/ask. Exit 0 = allow.
#
# Why this exists: 2026-10-25, jachzy caught a session-output "extensive undo guide"
# saved as a loose file instead of a GitHub issue under CCPM, despite the rule already
# being in loaded context. A rule in text is not enforcement. This is.

set -uo pipefail

emit() {
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
CONTENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null || true)
[ -z "$FILE_PATH" ] && exit 0

PATH_LC=$(printf '%s' "$FILE_PATH" | tr '[:upper:]' '[:lower:]' | tr '\\' '/')

# Only gate the export folder itself. Scratchpad is explicit session-temp (system
# prompt), and anything inside a git repo is already CCPM/vault-tracked.
case "$PATH_LC" in
  */nextcloud/personal/from\ claude/*) : ;;
  *) exit 0 ;;
esac

# Heuristic: does this read like a durable to-do/reference rather than a one-off
# export the user explicitly asked for (image, data export, generated report asked
# for by name)? Look for changelog/undo/rollback/reference-guide signal words in the
# first ~2000 chars.
HEAD=$(printf '%s' "$CONTENT" | head -c 2000 | tr '[:upper:]' '[:lower:]')
case "$HEAD" in
  *undo*|*rollback*|*revert*|*changelog*|*"changes made"*|*"reference doc"*|*"to be used later"*)
    emit ask "This looks like a durable deliverable (undo/changelog/reference doc) being saved as a loose file in the export folder. Per CCPM, GitHub is SoT for anything needing future action — this should be a GitHub issue (gh issue create), not a file nobody will find. Confirm this is really a one-off export explicitly asked for as a file, not a to-do."
    ;;
esac

exit 0
