---
name: recover-context
description: "Recover full working context after compaction, API failure, VS Code crash, or new session. Reconciles handover with actual repo/service state before resuming work."
---

# Recover Context

Use when starting a session after compaction, a crash, an unexpected restart, or when the recovery brief alone isn't enough to safely resume work.

**Do not use for normal session starts** — the SessionStart hook already injects a recovery brief. Use this when you need to verify actual state before acting, or when the handover looks stale or incomplete.

## When to run

- After compaction, if the recovery brief raised warnings or the objective is unclear
- After a VS Code crash or abrupt session end
- When handover.md seems stale (>24h old, or last session didn't complete its handover)
- When about to make a change to infrastructure, config, or running services — verify state first
- When the handover references files, services, or branches that may have changed

## Process

### Step 1 — Read the active handover

Read `~/.claude/workspaces/spacedog/handover/handover.md` in full.

Note:
- The stated objective and definition of done
- The claimed current state (what's working, what's pending)
- The last verified action and its timestamp
- Any open questions or blockers

### Step 2 — Check actual repository state

```bash
git -C ~/.claude/workspaces/spacedog status
git -C ~/.claude/workspaces/spacedog branch --show-current
git -C ~/.claude/workspaces/spacedog log --oneline -5
```

Compare against what the handover claims. Flag any discrepancy.

### Step 3 — Verify runtime state (only for the active task's services)

Do NOT check every service. Only verify what the handover's next steps actually require.

Examples:
- If next step is "restart lui2" → check `ssh admin@100.126.212.162 "docker ps | grep lui2"`
- If next step involves a config file → read that file now
- If next step mentions a branch → confirm branch exists and is up to date

### Step 4 — Read relevant vault docs on demand

From the handover's context, identify which vault docs are needed. Use `vault/_hashtags.md` to locate the right file for any service or topic. Read only what's relevant — not the full index.

Priority order for resolving conflicts:
1. Current user instructions (this session's conversation)
2. Actual runtime and repository state (what you just verified)
3. Verified test results or git log
4. Authoritative vault docs (gotchas, runbooks)
5. Active handover
6. Native auto-memory
7. Historical session logs (lowest trust — most likely stale)

### Step 5 — Reconcile discrepancies

If the handover claims state that doesn't match reality:

1. Note the discrepancy explicitly ("Handover says X is deployed; `docker ps` shows it's not running")
2. Do NOT proceed with the handover's next steps until the discrepancy is understood
3. If safe to resolve: fix the state or update the handover
4. If unsafe to resolve without more info: surface it to jachzy before acting

### Step 6 — Update handover if stale

If the handover is materially wrong or outdated, update it using the atomic write protocol:

```
HANDOVER=~/.claude/workspaces/spacedog/handover/handover.md
TMP=${HANDOVER}.tmp
```

1. Write corrected content to `$TMP`
2. Validate: non-empty, contains `## Goal`, `## Current State`, `## Next Steps`
3. If valid: `mv "$TMP" "$HANDOVER"` (atomic rename)
4. If invalid: keep original, delete `$TMP`, report failure

### Step 7 — Resume from first validated next action

State clearly:
- What state was verified
- What discrepancies were found and resolved
- What the first actual next step is
- Any risks or open questions before proceeding

Do NOT claim recovery is complete until Step 2–4 verification is done.

## Canonical file reference

| Purpose | Path |
|---------|------|
| Active handover | `~/.claude/workspaces/spacedog/handover/handover.md` |
| Handover backups | `~/.claude/workspaces/spacedog/handover/backups/` |
| Session logs | `~/.claude/workspaces/spacedog/handover/sessions/` |
| Vault routing | `vault/spacedog-index.md` |
| Tag index | `vault/_hashtags.md` |
| Project state | `vault/spacedog-state.md` |
| Roadmap | `vault/spacedog-master-roadmap-2026.md` |

## After recovery

Once context is verified and the first action is clear, proceed. If work will take multiple steps, create a TodoWrite list before starting.
