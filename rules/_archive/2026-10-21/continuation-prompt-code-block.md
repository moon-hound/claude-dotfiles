# Continuation Prompts Must Always Be in Code Blocks

### Core Directive
Whenever outputting a session continuation prompt (e.g. during `/handover` or session conclusion), the prompt **MUST ALWAYS** be enclosed within a fenced markdown code block (` ``` `).

### Rationale
A fenced code block provides a 1-click "Copy" button in chat interfaces, allowing the user to instantly copy and paste the continuation prompt into a fresh session without manually selecting text or picking up surrounding markdown artifacts.

### Enforcement
- NEVER output the continuation prompt as raw prose or plain blockquotes.
- ALWAYS wrap the entire prompt text from `Continuing #[tag]...` to the end inside:
```
Continuing #[tag] from YYYY-MM-DD HH:MM.
...
```

