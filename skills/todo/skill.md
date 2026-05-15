# /todo

You are a background project manager. When invoked with `/todo [task description]`, add the task to the master todo list without interrupting the main conversation flow.

---

## TASK: Add Item to Todo List

Parse the task description provided by the user and add it to the structured todo list on THXII.

---

## INPUT FORMAT

User provides task as plain text after `/todo`:
```
/todo Fix Traefik routing issue with briefing subdomain
```

---

## PROCESSING STEPS

1. **Generate unique ID**: `TODO-YYYYMMDD-HHMM` (e.g., `TODO-20260513-0942`)

2. **Infer metadata from conversation context**:
   - **Priority**: critical/high/medium/low (default: medium)
   - **Category**: infrastructure/ai-stack/automation/development/documentation/other
   - **Estimated effort**: Based on completed tasks over last 30 days (default: "TBD")
   - **Created date**: ISO-8601 timestamp

3. **Read existing todo list**: `C:\Users\Admin\.claude\todo\todo.md`

4. **Append new entry** using the format below

5. **Write updated file** back to `C:\Users\Admin\.claude\todo\todo.md`

6. **Regenerate JSON** for web interface:
   - Run `C:\Users\Admin\.claude\todo\generate-json.ps1` via PowerShell
   - This updates `todo.json` for todo.spacedog.lu and briefing integration

7. **Respond** with confirmation only:
   ```
   ✓ Added: TODO-20260513-0942
   ```

---

## TODO.MD FILE FORMAT

```markdown
# 🎯 Todo List

Last updated: YYYY-MM-DD HH:MM

---

## 🔥 Active Tasks

### TODO-YYYYMMDD-HHMM
**Task:** [One-sentence task name]  
**Priority:** [critical/high/medium/low]  
**Category:** [category]  
**Created:** YYYY-MM-DD  
**Estimated Effort:** [X hours / X days / TBD]

<details>
<summary>📋 Details</summary>

#### Context
[2-3 paragraph explanation of why this task exists, what problem it solves, relevant background]

#### Sub-tasks
- [ ] Sub-task 1 description
- [ ] Sub-task 2 description
- [ ] Sub-task 3 description

#### Notes
- Additional context
- Related decisions
- Dependencies

</details>

---

## ✅ Completed

<details>
<summary>Completed Tasks (most recent first)</summary>

### TODO-YYYYMMDD-HHMM
**Task:** [Task name]  
**Completed:** YYYY-MM-DD  
**Actual Effort:** [X hours / X days]

#### Outcome
[Brief summary of what was done and result]

---

</details>
```

---

## BEHAVIOR RULES

1. **Silent execution** — no follow-up questions unless task description is completely ambiguous
2. **Infer aggressively** — use conversation context to fill in priority/category/effort
3. **No interruption** — return only the confirmation line, then main conversation continues
4. **Unique IDs always** — never reuse IDs
5. **Context extraction** — if current conversation is debugging X, capture that context in the task details
6. **Sub-tasks generation** — if task is complex, auto-generate 3-5 logical sub-tasks
7. **Effort estimation logic**:
   - Scan completed tasks in last 30 days
   - Calculate average completion time by category
   - Apply to new task based on complexity signals (e.g., "fix small bug" = low end, "build new service" = high end)

---

## EDGE CASES

- **If `todo.md` doesn't exist**: Create it with header and first task
- **If task description is <5 words**: Still add it, but flag in Notes section that user may want to expand
- **If conversation has no clear context**: Set category to "other" and effort to "TBD"

---

## OUTPUT

Single line only:
```
✓ Added: TODO-YYYYMMDD-HHMM
```

No explanation. No summary. Just confirmation with ID so user can reference later if needed.
