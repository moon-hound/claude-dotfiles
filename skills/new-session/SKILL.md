---
name: new-session
description: "DEPRECATED — merged into /handover on 2026-09-14. Redirects there. Kept as a stub so old muscle-memory invocations of /new-session don't silently do the wrong thing."
---

# new-session → use /handover

`/new-session` and `/handover` used to be two separate skills covering the same job, and they drifted out of sync — `/new-session` kept writing to the deprecated `handover.md` for days after `/handover` moved to the shard model, silently losing session context. They're merged now. **Invoke `/handover` instead.**

`/handover`'s session log template already includes everything `/new-session` had: Goal, Current State, Diagnostic Path, Error Data, Failed Attempts / Dead Ends, Mistakes, Configuration State, Active Files, Verification, Rollback, State Drift Risks, Open Questions, Live Verification Checklist, Next Steps, Vault Files, and the mandatory Architectural Truths knowledge block for pgvector ingestion.

If invoked directly, do this: read `~/.claude/workspaces/spacedog/commands/handover/SKILL.md` and run that process instead. Do not fall back to any old `new-session` behavior — there is none left to fall back to.
