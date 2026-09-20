---
name: work
description: Execute prioritized work items from the canonical spacedog roadmap.
---

Execute prioritized work items from the canonical spacedog roadmap.

## Trigger

User types `/work` to begin a focused execution session.

## Behavior

This is an **autonomous execution mode** — proceed through all steps without asking permission for each action. The user wants momentum, not checkpoints.

### Phase 1: Load & Assess (2-3 minutes)

1. Read `~/.claude/workspaces/spacedog/vault/spacedog-roadmap-active.md` — the canonical source of truth
2. Read handover at `~/.claude/workspaces/spacedog/handover/handover.md` — current context
3. Assess current state:
   - **T0 (Blockers):** Any remaining? These block everything else — clear first.
   - **T1 (Ship):** 90%+ done items ready to finish
   - **T2 (Build):** Foundation work, ordered by dependency
   - **T3 (Expand):** New features (only after T1+T2 clear)
   - **Standing Items:** Quick wins for spare cycles

### Phase 2: Present Work Plan (1 message)

Output a **terse execution plan**:

```
## /work session — [timestamp]

**T0:** [count] blockers — [list IDs if any, else "CLEAR"]
**T1:** [count] to ship — [list top 3 by priority]
**T2:** [count] ready — [list next unblocked item]
**Standing:** [1-2 quick wins if time permits]

**Proposed execution order:**
1. [item ID] — [action] ([est])
2. [item ID] — [action] ([est])
3. [item ID] — [action] ([est])
...

**Est. total:** [time]

**Proceeding in 10 seconds unless you say STOP.**
```

Pause for 10 seconds of real wall-clock time by checking the timestamp. If user says "stop" or "wait", halt. Otherwise proceed.

### Phase 3: Execute (autonomous, use TodoWrite)

1. **Create TodoWrite task list** with all planned items before starting any work
2. For each item in execution order:
   - Mark `in_progress` in TodoWrite **before starting**
   - Execute the work (read files, run commands, deploy changes, verify)
   - Mark `completed` in TodoWrite **immediately after finishing**
   - Never batch updates — keep todo list current in real time
3. Follow the roadmap's **Principles**:
   - Complete > Start (finish before moving to next)
   - One work stream at a time (no context-switching)
   - Debt before features (security/fixes before new work)

### Phase 4: Sync Back to Roadmap (required)

After completing each item:
1. Update the status in `spacedog-roadmap-active.md` (✅ DONE, notes, timestamp)
2. If decisions were made, add to Decision Log section
3. If new blockers discovered, add to T0
4. Keep roadmap current — it's the source of truth

### Phase 5: Handover Update (at session end)

Update `~/.claude/workspaces/spacedog/handover/handover.md`:
1. If item belongs to existing Active Work section, update it
2. If it's a new work stream, add a new section following handover format:
   - Goal, Latest session log, Current state, Top 3 next actions, Open blockers
3. Move completed work to "Recently Completed" section
4. Reference the roadmap sync you just did

### Phase 6: Summary (final message)

```
## /work complete — [duration]

**Shipped:**
✅ [item ID] — [what changed]
✅ [item ID] — [what changed]
...

**Current state:**
- T0: [status]
- T1: [count remaining]
- T2: [next unblocked item]

**Velocity:** [items/hour]

**Next /work session priority:** [1-2 sentence recommendation]

**Roadmap + handover synced.**
```

## Key Rules

- **Never ask permission mid-execution** — user invoked `/work` to delegate the entire session
- **TodoWrite in real time** — mark in_progress before each item, completed immediately after
- **Keep roadmap current** — sync status after every completed item, not just at end
- **One item to completion** — never start the next until current is verified shipped
- **Stop on blockers** — if you discover something that blocks progress, surface it and halt rather than guessing
- **Physical-only steps** — if an item requires jachzy to physically do something (plug cables, press buttons), queue it and move to next item

## Safety Boundaries

Even in autonomous mode:
- No destructive git operations (force-push, reset --hard, branch deletion) without explicit approval
- No production data deletion
- No credential changes without saving to Bitwarden first
- Flag any item that affects shared/external systems before executing

## Examples

**Good execution flow:**
```
[10:00] /work invoked
[10:02] Plan presented (3 items, 45min est)
[10:03] TodoWrite created
[10:03] T1-1 marked in_progress
[10:15] T1-1 verified shipped, marked completed, roadmap updated
[10:15] T1-3 marked in_progress
[10:25] T1-3 shipped, marked completed, roadmap updated
[10:25] Standing item marked in_progress
[10:30] Standing item complete, roadmap updated
[10:32] Handover updated, summary posted
```

**When to stop:**
- Blocker discovered (missing credential, service down, unknown state)
- User says "stop" or "wait" during 10-second pause
- Physical action required
- Ambiguous decision that genuinely needs user input

## Notes

- This skill is the **high-momentum execution mode** — use it when jachzy wants to clear a batch of work without micromanagement
- Always reference the roadmap principles at the top of `spacedog-roadmap-active.md`
- The roadmap **Review cadence** says "Weekly (Sundays) or at /work session start" — you're fulfilling that contract
- Estimated times in roadmap are guidelines, not limits — finish the work properly
