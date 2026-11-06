#!/usr/bin/env bash
# post-edit-verify.sh - Silent In-Session Syntax & Ponytail De-Bloat Hook
# Runs after Edit/Write operations in Claude Code & Antigravity.
# Execution budget: < 100ms. Silent on success.

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

EXTENSION="${FILE_PATH##*.}"

# 1. Fast Syntax Validation (Python)
if [ "$EXTENSION" = "py" ]; then
  if command -v python >/dev/null 2>&1; then
    PY_ERR=$(python -m py_compile "$FILE_PATH" 2>&1)
    if [ $? -ne 0 ]; then
      printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","status":"error","message":"[SYNTAX ERROR] Python compile failed: %s"}}\n' "${PY_ERR//\"/\\\"}"
      exit 1
    fi
  fi
fi

# 2. Fast Ponytail Anti-Slop / Boilerplate Scan
# Checks for common AI-generated filler that violates Ponytail standards
AI_TELLS=(
  "// In a real application"
  "# In a production environment"
  "// TODO: replace with proper"
  "# TODO: implement proper error handling"
  "// Mock implementation for testing"
)

for tell in "${AI_TELLS[@]}"; do
  if grep -qF "$tell" "$FILE_PATH" 2>/dev/null; then
    printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","status":"warning","message":"[PONYTAIL WARNING] Detected AI boilerplate tell: \"%s\". Please simplify and remove placeholder fluff."}}\n' "$tell"
    exit 0
  fi
done

exit 0

