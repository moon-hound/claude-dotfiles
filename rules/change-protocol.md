---
alwaysApply: true
---

# Change Protocol

## Before touching anything

- Name every component the change touches. Multi-component systems require mapping all blast surfaces before writing a single line.
- **Read actual current state — don't assume it matches what should be there.** Check group_policies, env vars, file ownership, bootstrap status before writing code that depends on them.
- If the task involves a container, know whether it needs `restart` vs `down/up`. `docker restart` keeps old env vars. Only `down` + `up` reloads compose config.

## One change, one verification

- Make one logical change. Verify it works. Then move to the next.
- Never stack a second change on top of an unverified first change.
- Never make "while I'm here" improvements. Scope is exactly the task.

## When something breaks mid-task

- Stop immediately. Restore first. Resume after.
- Never revert without diagnosing why the current state broke — reverting into an already-broken system makes things worse. (Ollama v0.23.1 post-Docker-uninstall: revert caused same crash as original because Windows system file corruption was the real issue.)

## Infrastructure rules

- Never modify nginx, Traefik, docker-compose unless explicitly the task.
- After any nginx reload, confirm a real HTTP request succeeds before declaring done. Syntax-valid ≠ behavior-correct.
- Nested `location` blocks inside `alias` don't inherit the alias path — requests 404 silently.

## Shell / SSH rules

- Heredocs with Python or special characters will be mangled by the shell. Use base64 encode/decode for any file with quotes, operators, or sigils.
- SSH → zsh → PowerShell is three quoting layers. Inline commands break silently. Write to /tmp, scp, then execute.
- `crontab /etc/config/crontab` must run BEFORE `crond restart` — restart doesn't re-read the file.

## Read before writing

- Check CLAUDE.md "Critical Gotchas" section before touching dojoNAS — permission traps, PATH issues, and broken NICs are documented there.
- Before writing a script that references a container or flag location, grep to confirm it actually lives where assumed. (HMAC flag was on n8n, not lui-gateway.)
- Before assuming a machine is bootstrapped/synced, verify. (THXII was never added to claude-config GitHub — assumed it was.)

## Consumer contracts

- When changing a section title, label, or key in a producer (briefing-runner), check every consumer (SPA, n8n, Signal parser) for hardcoded matches before deploying.
- Adding a model alias to LiteLLM config.yaml is not enough — the virtual key's allowed_models list also needs updating, then both litellm and open-webui need restart.
