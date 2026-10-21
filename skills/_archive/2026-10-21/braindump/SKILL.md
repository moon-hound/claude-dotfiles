---
name: braindump
description: >
  Processes raw braindump entries from the Obsidian vault into fully-formed
  todo items. Reads unprocessed entries from vault/braindump/🧠BRAINDUMP.md,
  grills the user for context using targeted questions, then creates a new
  todo entry, items detail note, and Kanban card. Marks the braindump entry
  as processed with a link to the new todo.
  Trigger: user types /braindump or Claude detects new unprocessed entries.
---

# /braindump — Braindump Processing Skill

## Purpose

Convert raw ideas from the braindump into structured, actionable todo items. Every idea deserves a proper ticket — this skill bridges the gap between "shower thought" and "planned work."

## Braindump File

**Location:** `C:\Users\Admin\.claude\workspaces\spacedog\vault\braindump\🧠BRAINDUMP.md`

**Entry format** — user writes freeform entries under date headings:
```
## 💡 YYYY-MM-DD — [Idea title or leave blank]
[Freeform thoughts here]
```

**Processed entries** get a link appended:
```
## 💡 YYYY-MM-DD — [Idea title] ✅ → [[todo/items/TODO-XXXXXXXX-XXXX|TODO-XXXXXXXX-XXXX]]
```

---

## Process

### Step 1 — Read & Identify Unprocessed Entries

1. Read `vault/braindump/🧠BRAINDUMP.md`
2. Find all entries that do NOT have `✅ →` in their heading
3. If no unprocessed entries → tell user "No new braindump entries to process."
4. If multiple entries → ask user which one to start with (or process all sequentially)

### Step 2 — Grill for Context (per entry)

Present the raw entry to the user, then ask targeted questions to understand:

**Required context (ask all of these):**
1. **Goal** — What outcome does this achieve? What's the "done" state?
2. **Why now** — What's the motivation or trigger behind this idea?
3. **Scope** — Is this a 1-hour task, a multi-day project, or a phase of something bigger?
4. **Section** — Which vault section does this belong to? (🧠 Brain / 🔵 Home / 🔴 Infra / 🟠 Projects / 🟣 Sessions)
5. **Blockers** — Does this depend on anything else being done first?
6. **Priority** — How urgent is this? (critical / high / medium / low)

Use `AskUserQuestion` modal for each round of questions. Don't ask all 6 at once — group logically into 2 rounds max:
- Round 1: Goal, Why now, Scope
- Round 2: Section, Blockers, Priority

**If the idea is vague or ambitious:** invoke the grill-me approach — push back with follow-up questions until the scope is clear enough to estimate effort. Don't create a todo for something half-baked.

**If the idea is clear and small (1-2h):** skip deep grilling, confirm the key details in one shot.

### Step 3 — Create Todo Entry

Generate a new TODO ID using current date/time: `TODO-YYYYMMDD-HHMM`

**3a. Create the items detail note:**
Write `vault/todo/items/TODO-YYYYMMDD-HHMM.md` with:
```markdown
---
todo-id: TODO-YYYYMMDD-HHMM
section: "[section emoji + name]"
title: "[short title]"
priority: [critical/high/medium/low]
status: backlog
hashtags: "[relevant tags]"
effort: [estimate]
---

# TODO-YYYYMMDD-HHMM · [Title]

## What This Work Entails
[Clear description from grilling session]

## What Completing This Brings
[The outcome / capability gained]

## Planned Steps
[Numbered steps based on grilling context]

## Origin
> Braindump entry: [date] — [first line of raw idea]
```

**3b. Add entry to `todo/todo.md`:**
Under `## 🔥 Active Tasks`, add:
```markdown
### TODO-YYYYMMDD-HHMM
**Task:** [Title]
**Hashtag:** [tags]
**Priority:** [priority]
**Category:** [category]
**Created:** [date]
**Estimated Effort:** [estimate]
**Source:** Braindump → [[todo/items/TODO-YYYYMMDD-HHMM]]
```

**3c. Add card to `todo/Kanban.md`:**
Add to the appropriate column (Backlog or In Progress) before the `%% kanban:settings` block:
```
- [ ] [[todo/items/TODO-YYYYMMDD-HHMM|[section] · TODO-YYYYMMDD-HHMM · [title] · [priority dot] [priority]]]
```

If Kanban doesn't have a `## 🗂 Backlog` column, add the card to the most appropriate existing column.

### Step 4 — Remove Entry from Braindump

Delete the entire entry (heading + body) from `🧠BRAINDUMP.md`. The todo items file is now the canonical record — the braindump is a temporary capture buffer, not an archive.

**How to remove cleanly:**
- Delete from the `## 💡` heading line down to (but not including) the next `## ` heading or end of file
- Collapse any resulting double blank lines to a single blank line
- Do NOT leave a processed marker behind — remove the entry entirely

The braindump file should end up containing only the preamble and any remaining unprocessed entries.

### Step 5 — Report

Tell the user:
- What todo was created (ID + title)
- What section/priority it was assigned
- Whether any follow-up research is recommended (trigger /pm if needed)

---

## PM Integration

After creating the todo, invoke `/pm` behavior silently:
- Check if the new todo has enough context to be READY (has sub-tasks, effort estimate, clear scope)
- If NEEDS_RESEARCH → flag it and ask if user wants to run `/pm` now to flesh it out further
- If READY → confirm and move on

---

## Rules

- **Never create a vague todo.** If the idea isn't clear enough after two rounds of questions, tell the user and ask them to clarify the braindump entry first.
- **One todo per braindump entry** unless the entry clearly describes independent parallel work streams.
- **Don't modify existing todos** — only create new ones.
- **Always delete the braindump entry after creating the todo** — never leave it in limbo. The todo items file is the permanent record.
- **Preserve the braindump file's other content** — only remove the specific entry being processed, leave all others untouched.
