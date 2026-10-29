---
name: pm
description: Background project manager that researches, plans, and triages todo list items
---

# /pm — Todo List Project Manager

Background project manager that researches, plans, and triages todo list items. Runs automatically when new todos are added and periodically to maintain up-to-date plans.

## Trigger

- User types `/pm` (manual invocation)
- Auto-triggered via hook when todo.md changes
- Auto-triggered via cron every 6 hours

## Behavior

**Silent background operation** — only surface output when critical items are found or when manually invoked.

### Phase 1: Load Current State (30 seconds)

1. Read the todo list (platform-aware path):
   - **Mac**: `~/.claude/workspaces/spacedog/todo/todo.md`
   - **THXII/Windows**: `C:\Users\Admin\.claude\todo\todo.md`
2. Query the Architect Gate (dojoNAS, `http://192.168.1.234:8787`) for live graph truth:
   - `GET /briefing` — graph stats, in-flight/blocked projects, gaps, fragile nodes, WIP status
   - `POST /query {"question": "what should I work on next"}` — ranked actions with score/unblocks
   - **If the Gate is unreachable** (container down, dojoNAS offline): skip straight to todo.md-only behavior for this cycle, note the degradation in the Phase 5 completion line, don't fail the whole run.
3. Identify all active tasks (under `## 🔥 Active Tasks`) from todo.md — this remains the source for human-written context, sub-tasks, and notes. The graph is the source for status, severity, and blast-radius; todo.md's own "priority"/"status" fields are no longer trusted over it.
4. Classify each task's research state:
   - **NEEDS_RESEARCH**: Missing context, no sub-tasks, effort is "TBD", or description is <5 words
   - **NEEDS_UPDATE**: Created >7 days ago, external dependencies may have changed
   - **READY**: Has detailed context, sub-tasks, and effort estimate
   - **CRITICAL**: matches a `/briefing` gap with `severity` in (`critical`, `high`), or a `dependency_inversion` gap naming this task's project

### Phase 2: Triage & Prioritization (1 minute)

Severity, urgency, impact, and escalation are now read from the Gate instead of guessed from todo.md text:
1. **Severity**: `/briefing`'s `gaps[].severity` for this task's project, or `/query`'s ranked `score` if it has an entry.
2. **Blast radius / Impact**: for any task that touches a specific file/service, `POST /query {"question": "is it safe to touch <path>?", "path": "<path>"}` — use its `decision`/`severity`/`dependents_count` directly rather than estimating.
3. **Unblock leverage**: `/query`'s `ranked_actions[].unblocks` — a task clearing a `dependency_inversion` that frees 2+ in-flight projects outranks one that frees none, mechanically, not by judgment call.
4. **Effort**: still LLM-estimated from similar completed tasks — the graph has no effort data.

**Priority escalation rules (now graph-derived, not keyword-matched):**
- Gap `severity: critical` → task priority CRITICAL
- `dependency_inversion` naming this task's project as the blocker → escalate the blocking task to at least HIGH
- `ranked_actions[].unblocks >= 2` → HIGH (minimum)
- Subscription/service expires within 7 days → HIGH (minimum) — still todo.md-sourced, the graph doesn't track this
- Missing credentials/access → escalate to blocker status — still todo.md-sourced

### Phase 3: Research & Planning (parallel, 3-5 minutes per task)

For each NEEDS_RESEARCH or NEEDS_UPDATE task, launch research workflow:

**Research workflow (per task):**
1. **Understand the domain** (2 min):
   - Web search for context (what is this tool/service/technology?)
   - Check Spacedog vault for existing related docs
   - Identify alternatives and comparison points
   
2. **Build implementation plan** (3 min):
   - Identify required steps (setup, configuration, testing, deployment)
   - List prerequisites (credentials, access, dependencies)
   - Estimate time per sub-task based on complexity
   - Flag integration points with existing Spacedog infrastructure
   
3. **Assess risks & gotchas** (2 min):
   - Search for known issues, common pitfalls
   - Check version compatibility with existing stack
   - Identify rollback strategy
   - Security/privacy considerations

4. **Update todo entry**:
   - Expand Context section (2-3 paragraphs)
   - Generate 5-8 concrete sub-tasks
   - Update effort estimate with rationale
   - Add Notes section with gotchas, dependencies, alternatives
   - Adjust priority if research reveals higher severity

### Phase 4: Surface Critical Findings

**Always surface to user immediately if:**
- `/briefing` reports a new gap with `severity` in (`critical`, `high`) not previously surfaced (track surfaced gap IDs in memory to avoid repeat alerts)
- A `dependency_inversion` gap names an in-flight task as blocked by a project not in todo.md's active tasks (a graph/todo.md drift — todo.md doesn't know about a real blocker)
- Priority escalated during research (e.g., low → high)
- Blocker discovered (missing credentials, service down, dependency unavailable)
- Time-sensitive action needed (expires within 48 hours)
- Security/data risk identified

**Surface format:**
```
🚨 CRITICAL TODO ITEM DETECTED

TODO-YYYYMMDD-HHMM: [Task name]
Priority: CRITICAL (escalated from [previous])
Urgency: [why this needs immediate attention]

Action needed: [specific next step]
```

### Phase 5: Silent Completion (background mode)

When running in background (hook/cron), output format:
```
✓ PM cycle complete — [timestamp]
Reviewed: [N] tasks
Researched: [N] tasks  
Escalated: [N] tasks
Critical items: [N] (surfaced above if >0)
```

When manually invoked (`/pm`), provide full report:
```
## 📊 Todo List Status — [timestamp]

**Active Tasks:** [N]
- Critical: [N] 
- High: [N]
- Medium: [N]
- Low: [N]

**Research Status:**
- Ready: [N] (fully planned)
- Researched this cycle: [N]
- Still need research: [N]

**Critical Items:**
[List any critical items with summary]

**Top 3 Recommended Next Actions** (from `/query`'s ranked_actions, highest score first):
1. [TODO-ID]: [Why this is highest leverage — cite score/unblocks from the Gate]
2. [TODO-ID]: [Why this is second priority]
3. [TODO-ID]: [Why this should be third]

*(If the Gate was unreachable this cycle, say so here and fall back to todo.md-only reasoning.)*

**Blockers:** [List any blockers discovered]
```

## Research Quality Standards

Every researched todo must have:
- **Context**: 2-3 paragraphs explaining WHAT, WHY, and IMPACT
- **Sub-tasks**: 5-8 concrete, actionable steps (not vague)
- **Effort**: Realistic estimate with rationale (X hours because Y)
- **Notes**: Gotchas, alternatives considered, dependencies, integration points

Sub-task quality checklist:
- ✅ Specific and actionable ("Install X via Y" not "Set up X")
- ✅ Ordered by dependency (can't do step 3 before step 2)
- ✅ Include verification steps (test/confirm it works)
- ✅ Flag external dependencies (needs credentials, hardware, etc.)

## Integration with Spacedog Infrastructure

**Architect Gate (dojoNAS, `http://192.168.1.234:8787`)** is the source of truth for status, severity, blast radius, and ranked priority — see Phase 1/2/4 above. Endpoints used: `GET /briefing`, `POST /query`. If unreachable, degrade to todo.md-only and say so in output.

When researching, always consider:
- **Docker deployment**: Can this run in a container on dojoNAS?
- **Traefik + Authelia**: Does it need a public endpoint? How to secure?
- **Netbird VPN**: Is this admin-only or public?
- **Lui integration**: Should Lui be aware of this? Add to system_knowledge?
- **Existing services**: Does Plex/Jellyfin/Home Assistant already do this?

Reference the Spacedog vault architecture:
- `~/.claude/workspaces/spacedog/vault/_system-map.md` — infrastructure overview
- `~/.claude/workspaces/spacedog/vault/_hashtags.md` — taxonomy for tagging related docs

## Workflow Orchestration

For NEEDS_RESEARCH tasks, use Workflow tool to parallelize research:
- Launch one research agent per task (max 3 concurrent)
- Each agent gets task description + Spacedog context
- Agent returns structured research (context, sub-tasks, effort, notes)
- Update todo.md with all research results

Use workflow schema to enforce structure:
```javascript
{
  context: { type: 'string', minLength: 200 },
  subTasks: { type: 'array', minItems: 5, maxItems: 8 },
  effort: { type: 'string' },
  priority: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
  notes: { type: 'array', items: { type: 'string' } }
}
```

## Safety & Boundaries

- **Read-only by default**: PM skill does NOT execute work, only plans
- **No auto-escalation spam**: Only surface critical once per item (track in memory)
- **Respect user priority**: Don't downgrade user-set priority, only escalate if justified
- **No external API calls**: Web research only, don't sign up for trials or create accounts
- **Preserve user content**: Never delete user-written context, only expand it

## Notes

- Runs silently in background via hooks + cron
- Only interrupts user for genuine critical items
- Uses Workflow tool for parallel research (efficient token usage)
- Maintains todo.md as single source of truth
- Integrates with `/work` skill (work execution) and `/todo` skill (item creation)
- Research quality matters — better to spend 5 min and get it right than rush incomplete plans
