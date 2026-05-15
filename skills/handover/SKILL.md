---
name: handover
description: "End-of-session handover document. Captures goal, current state, active files, failed attempts, and next steps so the next session picks up cold with zero re-explanation."
---

# Session Handover

Generate a `handoff.md` in the current working directory that gives the next session everything it needs to continue without asking jachzy to re-explain.

## Process

1. **Gather context** — review conversation history, todo list state, recent git changes, and any open files
2. **Write `handoff.md`** — using the template below
3. **Report** — confirm file written, print the path

## Template

Write `handoff.md` with exactly these sections:

```markdown
# Session Handoff — {DATE}

## Goal
What we're working toward. One paragraph max. Include the "why" if non-obvious.

## Current State
Where things stand right now. What works, what's partially done, what's broken.
Use bullet points. Be specific — file paths, line numbers, service names.

## Active Files
Files being edited or created this session. One per line with brief note on what changed.

| File | Status | What Changed |
|------|--------|-------------|
| path/to/file | modified/created/deleted | brief description |

## Failed Attempts
Everything tried that didn't work. Include WHY it failed — this prevents the next session from repeating dead ends.

- **What was tried** — why it failed
- **What was tried** — why it failed

If nothing failed, write: "Clean run — no failed attempts."

## Next Steps
The exact next action(s) to take, in priority order. Be specific enough that the next session can start executing immediately without exploration.

1. First thing to do
2. Second thing to do

## Open Questions
Anything unresolved that needs jachzy's input or investigation. Remove this section if none.
```

## Rules

- **Be specific.** File paths, error messages, command outputs — not vague summaries.
- **No fluff.** This is a technical handoff, not a status report.
- **Include failures.** Failed attempts are the most valuable part — they prevent wasted work.
- **Date format:** YYYY-MM-DD
- **If a todo list exists**, incorporate its state into Current State and Next Steps.
- **If memory notes were saved this session**, reference them in Current State.
- **Overwrite** any existing `handoff.md` in the directory — each session gets a fresh one.
