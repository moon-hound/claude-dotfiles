---
name: work-vault
description: 8-folder Obsidian Operating System for work vault automation - local-first with Claude Code + Claude API
subcommands:
  - name: setup
    description: Interactive setup wizard - creates vault structure, generates WORKBOT.md, schedules automation
  - name: capture
    description: Capture work items to 00-CAPTURE/ for processing
  - name: briefing
    description: Generate on-demand morning briefing
  - name: status
    description: Quick project pulse across active work
  - name: sync
    description: Manually trigger capture processor
  - name: health
    description: Check project health and flag stalled work
---

# Personal Assistant - 8-Folder Obsidian Operating System

Standalone, local-first work vault automation using Claude Code + Claude API (Bedrock). No infrastructure dependencies.

## Architecture

- **Local vault**: `~/work-vault/` (8-folder structure)
- **Automation**: Claude Code CronCreate for scheduling
- **LLM**: Claude Sonnet via Bedrock (classification + briefing generation)
- **Interface**: Slack Socket Mode (Phase 3+, optional)
- **Colleague-portable**: Copy skill → run setup → working system in <30 min

## Usage

```bash
/work-vault setup      # Interactive setup wizard
/work-vault capture "text"  # Capture work item
/work-vault briefing   # Generate morning briefing now
/work-vault status     # Show project pulse
/work-vault sync       # Process captures manually
/work-vault health     # Check project health
```

---

# Subcommand Implementation

When the user invokes a subcommand, call the corresponding Python script from the `scripts/` directory.

## capture

**Usage:**
- `/work-vault capture "Meeting with Alice about Q3 roadmap"`
- `/work-vault capture --process` (classify and route today's captures)

**Implementation:**

```python
import sys
from pathlib import Path

# Get skill directory
skill_dir = Path(__file__).parent
scripts_dir = skill_dir / "scripts"

# Get arguments
if len(sys.argv) < 2:
    print("Usage: /work-vault capture <text> | /work-vault capture --process")
    sys.exit(1)

args = sys.argv[1:]

# Call capture.py
import subprocess
result = subprocess.run(
    ["python3", str(scripts_dir / "capture.py")] + args,
    capture_output=True,
    text=True
)

print(result.stdout)
if result.stderr:
    print(result.stderr, file=sys.stderr)

sys.exit(result.returncode)
```

Alternatively, use Bash tool to invoke directly:

```bash
cd ~/.claude/skills/work-vault/scripts
python3 capture.py "$@"
```

## briefing

**Usage:**
- `/work-vault briefing` (interactive mode, display in terminal)
- `/work-vault briefing --auto` (cron mode, post to Slack only)

**Implementation:**

```bash
cd ~/.claude/skills/work-vault/scripts
python3 briefing.py "$@"
```

## status

**Usage:**
- `/work-vault status`

**Implementation:**

```bash
cd ~/.claude/skills/work-vault/scripts
python3 status.py
```

## health

**Usage:**
- `/work-vault health` (display report)
- `/work-vault health --check` (cron mode, alert if stalled projects)

**Implementation:**

```bash
cd ~/.claude/skills/work-vault/scripts
python3 health.py "$@"
```

## sync

**Usage:**
- `/work-vault sync` (alias for capture --process)

**Implementation:**

```bash
cd ~/.claude/skills/work-vault/scripts
python3 sync.py
```

## setup

**Status:** Partially implemented

**Current setup (manual):**

### 1. Create vault structure

```bash
mkdir -p ~/work-vault/{00-CAPTURE,01-ACTIVE/{projects,tasks,daily},02-RESOURCES/{references,research},03-SYSTEM/{workflows,logs},04-GENERATED/{briefings,summaries,research},05-QUEUE,06-CALENDAR/events,07-ARCHIVE/capture-processed}
```

### 2. Create WORKBOT.md

```bash
cat > ~/work-vault/03-SYSTEM/WORKBOT.md <<'EOF'
# WORKBOT Operating Manual

## User Profile

- **Name:** [Your name]
- **Role:** [Your role]
- **Team:** [Your team]

## Active Projects

### Project: [project-name]
**Status:** [In Progress / Planning / Blocked]
**Next action:** [Specific next step]
**Priority:** [High / Medium / Low]

[Brief description]

## This Week's Priorities

1. [Priority 1]
2. [Priority 2]
3. [Priority 3]
EOF
```

Edit with your details.

### 3. Verify Bedrock auth

Check that settings.json has Bedrock env vars:

```bash
env | grep ANTHROPIC
env | grep AWS
```

Should show:
- `ANTHROPIC_BEDROCK_BASE_URL`
- `ANTHROPIC_AUTH_TOKEN`
- `AWS_BEARER_TOKEN_BEDROCK`
- `AWS_REGION`

### 4. Test manual commands

```bash
/work-vault capture "Test setup"
/work-vault sync
/work-vault status
/work-vault briefing
```

### 5. Configure Slack (optional, Phase 6)

See **Slack Integration Setup** section below.

**Cron jobs are already scheduled** (auto-expire after 7 days, re-run /work-vault setup to reschedule).

---

# Current Implementation Status

## ✅ Phase 2 Complete - Manual Subcommands

**Working subcommands:**
- `capture` - Write + classify + route (Claude Sonnet via Bedrock)
- `briefing` - Generate morning briefing (Claude Sonnet)
- `status` - Project pulse table
- `health` - Project health check
- `sync` - Alias for capture --process

**Files:**
- `scripts/work_vault_core.py` - Core utilities (BedrockClaudeClient, VaultFileSystem, SlackPoster)
- `scripts/capture.py` - Capture + classification
- `scripts/briefing.py` - Morning briefing generation
- `scripts/status.py` - Project status display
- `scripts/health.py` - Project health check
- `scripts/sync.py` - Wrapper for capture --process

**Prompts:**
- `prompts/morning-briefing.md` - Briefing generation
- `prompts/capture-classifier.md` - Capture classification

**Templates:**
- `templates/WORKBOT.md.template` - Operating manual template
- `templates/project-overview.md.template` - Project structure
- `templates/daily-note.md.template` - Daily note format

## ✅ Phase 3-5 Complete

**Phase 3: Additional Prompts** ✅
- `prompts/weekly-review.md`
- `prompts/project-health.md`
- `prompts/queue-processor-research.md`
- `prompts/queue-processor-draft.md`
- `prompts/queue-processor-plan.md`

**Phase 4: Cron Scripts** ✅
- `scripts/cron-morning-briefing.py`
- `scripts/cron-capture-processor.py`
- `scripts/cron-queue-processor.py`
- `scripts/cron-weekly-review.py`
- `scripts/cron-project-health.py`

**Phase 5: CronCreate Integration** ✅
- 5 durable recurring jobs scheduled
- Job IDs: 85e260e0, 80132178, 86ec207d, 0effc4c4, f3d99707
- Auto-expires after 7 days (re-schedule weekly)

**Phase 6: Slack Integration** ✅
- `scripts/slack-listener.py` - Socket Mode listener (Python)
- `scripts/setup-slack-listener.sh` - Auto-start setup
- Slash commands: /cap, /research, /status, /briefing, /health
- LaunchAgent for Mac auto-start on login

---

# Usage Notes

## Authentication

Uses Bedrock auth from settings.json environment variables:
- `ANTHROPIC_BEDROCK_BASE_URL`
- `ANTHROPIC_AUTH_TOKEN`
- `AWS_BEARER_TOKEN_BEDROCK`
- `AWS_REGION`

No separate ANTHROPIC_API_KEY needed for colleagues - they'll use their own Bedrock setup.

## Model Selection

Currently uses `claude-sonnet-4-20250514` for all operations:
- Classification (ideally Haiku for cost, but model name not available in Bedrock)
- Briefing generation
- Queue processing (Phase 3+)

Cost: ~$3/1M tokens input, ~$15/1M tokens output (Sonnet pricing)

## Slack Integration

**Status:** Optional, deferred to Phase 6

**Current workaround:** Use manual subcommands via terminal:
- `/work-vault capture "text"` instead of Slack `/cap text`
- `/work-vault briefing` instead of Slack `/briefing`

Automation still posts to Slack via `SlackPoster` if tokens configured at `~/.work-vault-config/slack-tokens.env`.

## Cron Jobs

**Status:** Not yet scheduled (Phase 5)

**Manual triggers available:**
- `/work-vault briefing` → morning briefing
- `/work-vault sync` → capture processor
- `/work-vault health` → project health check

## Troubleshooting

**Import errors:**
```bash
cd ~/.claude/skills/work-vault/scripts
python3 -c "from work_vault_core import *"
```

**Vault not found:**
```bash
ls ~/work-vault/
# Should show 8 folders: 00-CAPTURE through 07-ARCHIVE
```

**Bedrock auth errors:**
```bash
env | grep ANTHROPIC
env | grep AWS
# Should show 4 env vars from settings.json
```

**Log files:**
- `~/work-vault/03-SYSTEM/logs/work-vault.log` - All operations
- `~/work-vault/03-SYSTEM/logs/failed-captures.log` - Classification failures

---

# Development Notes

## Testing Workflow

```bash
# Test capture
cd ~/.claude/skills/work-vault/scripts
python3 capture.py "Test capture item"
ls ~/work-vault/00-CAPTURE/

# Test classification
python3 capture.py --process
ls ~/work-vault/02-RESOURCES/

# Test briefing
python3 briefing.py
cat ~/work-vault/04-GENERATED/briefings/$(date +%Y-%m-%d)-morning.md

# Test status
python3 status.py

# Test health
python3 health.py
```

## Adding New Prompts

1. Create `prompts/new-prompt.md` with `{PLACEHOLDER}` tokens
2. Use `load_prompt_template("new-prompt")` in script
3. Use `substitute_prompt_placeholders(template, PLACEHOLDER=value, ...)`
4. Call `BedrockClaudeClient().call(prompt, model, max_tokens, temperature)`

## Bedrock API Format

**Endpoint:** `{base_url}/model/{model_id}/invoke`

**Payload:**
```json
{
  "anthropic_version": "bedrock-2023-05-31",
  "max_tokens": 2048,
  "temperature": 0.7,
  "messages": [{"role": "user", "content": "prompt"}]
}
```

**Response:**
```json
{
  "content": [{"text": "response"}]
}
```

---

*Phase 2 complete. Ready for Phase 3 (prompts) and Phase 4-6 (cron + Slack).*

---

# Slack Integration Setup (Phase 6)

Adds Slack slash commands for two-way interaction with work-vault.

## Prerequisites

- Python 3.9+
- pip3 (Python package manager)
- Slack workspace with admin access

## Setup Steps

### 1. Create Slack App

1. Go to https://api.slack.com/apps?new_app=1
2. Click "From scratch"
3. App name: **Personal Assistant**
4. Pick your workspace
5. Click "Create App"

### 2. Configure OAuth Scopes

1. Go to **OAuth & Permissions** in left sidebar
2. Scroll to **Bot Token Scopes**
3. Add these scopes:
   - `chat:write` (Post messages)
   - `commands` (Add slash commands)
   - `im:write` (Send DMs)
   - `files:write` (Upload files, optional)

### 3. Enable Socket Mode

1. Go to **Settings → Socket Mode** in left sidebar
2. Toggle **Enable Socket Mode** to ON
3. Click **Generate an app-level token**
4. Token name: **work-vault-socket**
5. Scope: `connections:write`
6. Click **Generate**
7. **Copy the token** (starts with `xapp-`) — save as `SLACK_APP_TOKEN`

### 4. Create Slash Commands

1. Go to **Slash Commands** in left sidebar
2. Click **Create New Command** for each:

**Command 1: /cap**
- Command: `/cap`
- Short Description: `Quick capture work item`
- Usage Hint: `<text to capture>`

**Command 2: /research**
- Command: `/research`
- Short Description: `Queue research task`
- Usage Hint: `<topic to research>`

**Command 3: /status**
- Command: `/status`
- Short Description: `Show project status`
- Usage Hint: *(leave empty)*

**Command 4: /briefing**
- Command: `/briefing`
- Short Description: `Generate morning briefing`
- Usage Hint: *(leave empty)*

**Command 5: /health**
- Command: `/health`
- Short Description: `Check project health`
- Usage Hint: *(leave empty)*

3. Click **Save** for each command

### 5. Install App to Workspace

1. Go to **OAuth & Permissions**
2. Click **Install to Workspace**
3. Review permissions
4. Click **Allow**
5. **Copy the Bot User OAuth Token** (starts with `xoxb-`) — save as `SLACK_BOT_TOKEN`

### 6. Get Your User ID

1. Open Slack desktop/web app
2. Click your profile picture → **Profile**
3. Click **⋯ More** → **Copy member ID**
4. Save as `SLACK_USER_ID` (format: `U01234ABCDE`)

### 7. Save Tokens Locally

Create config file:

```bash
mkdir -p ~/.work-vault-config
cat > ~/.work-vault-config/slack-tokens.env <<'EOF'
SLACK_BOT_TOKEN=xoxb-your-bot-token-here
SLACK_APP_TOKEN=xapp-your-app-token-here
SLACK_USER_ID=U01234ABCDE
EOF

chmod 600 ~/.work-vault-config/slack-tokens.env
```

Replace the placeholder values with your actual tokens.

### 8. Install Python Dependencies

```bash
pip3 install --user slack-bolt
```

### 9. Set Up Auto-Start (LaunchAgent)

Run the setup script:

```bash
cd ~/.claude/skills/work-vault/scripts
./setup-slack-listener.sh
```

This will:
- Install `slack-bolt` if not already installed
- Create LaunchAgent plist file
- Load and start the listener
- Configure auto-start on Mac login

### 10. Verify Listener is Running

Check logs:

```bash
tail -f ~/.work-vault-config/slack-listener.log
```

Should show:
```
Starting Slack listener for work-vault...
Listening for commands: /cap, /research, /status, /briefing, /health
```

Check for errors:

```bash
tail -f ~/.work-vault-config/slack-listener-error.log
```

### 11. Test Slack Commands

In Slack, try:

```
/cap Test capture from Slack
/status
/briefing
```

You should get responses in Slack.

---

## Available Slash Commands

### `/cap <text>`

**Capture work item to vault**

Examples:
- `/cap Meeting with Alice about Q3 roadmap`
- `/cap Bug in auth flow - investigate timeout`
- `/cap Idea: automated weekly status reports`

Writes to `00-CAPTURE/` for processing at 6pm cron job (or manual `/work-vault sync`).

### `/research <topic>`

**Queue research task**

Examples:
- `/research Best practices for API rate limiting`
- `/research Compare feature flagging solutions`
- `/research How do high-performing teams handle incidents?`

Creates `RESEARCH-*.md` in `05-QUEUE/` for processing every 2 hours (8am-6pm weekdays).

### `/status`

**Show project pulse**

Displays table of active projects with status, next action, and last updated.

### `/briefing`

**Generate morning briefing now**

On-demand briefing generation (takes 10-15 seconds). Normally runs automatically at 7am weekdays.

### `/health`

**Check project health**

Identifies stalled projects (>7 days inactive or marked "blocked").

---

## Troubleshooting

### Listener not responding

1. Check if running:
   ```bash
   launchctl list | grep work-vault
   ```

2. Check logs:
   ```bash
   tail -20 ~/.work-vault-config/slack-listener-error.log
   ```

3. Restart listener:
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.work-vault.slack-listener.plist
   launchctl load ~/Library/LaunchAgents/com.work-vault.slack-listener.plist
   ```

### Commands not showing in Slack

1. Verify slash commands created in Slack app settings
2. Check that app is installed to workspace
3. Try typing `/` in Slack — commands should autocomplete

### Permission errors

1. Verify OAuth scopes:
   - `chat:write`
   - `commands`
   - `im:write`

2. Reinstall app if scopes changed:
   - Go to **OAuth & Permissions**
   - Click **Reinstall to Workspace**

### Token errors

1. Verify tokens in `~/.work-vault-config/slack-tokens.env`
2. Check token format:
   - Bot token starts with `xoxb-`
   - App token starts with `xapp-`
   - User ID starts with `U`

3. Regenerate tokens if expired:
   - Bot token: OAuth & Permissions → Reinstall
   - App token: Socket Mode → Regenerate

### Import errors (slack_bolt not found)

```bash
pip3 install --user slack-bolt
```

Then restart listener.

---

## Manual Control

### Start listener manually

```bash
cd ~/.claude/skills/work-vault/scripts
python3 slack-listener.py
```

Press Ctrl+C to stop.

### Stop LaunchAgent

```bash
launchctl unload ~/Library/LaunchAgents/com.work-vault.slack-listener.plist
```

### Start LaunchAgent

```bash
launchctl load ~/Library/LaunchAgents/com.work-vault.slack-listener.plist
```

### View logs

```bash
# Output (info)
tail -f ~/.work-vault-config/slack-listener.log

# Errors
tail -f ~/.work-vault-config/slack-listener-error.log
```

---

## Uninstalling Slack Integration

1. Stop listener:
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.work-vault.slack-listener.plist
   ```

2. Remove LaunchAgent:
   ```bash
   rm ~/Library/LaunchAgents/com.work-vault.slack-listener.plist
   ```

3. Remove config:
   ```bash
   rm ~/.work-vault-config/slack-tokens.env
   ```

4. Uninstall Slack app:
   - Go to https://api.slack.com/apps
   - Select **Personal Assistant**
   - Settings → Basic Information → Delete App

Terminal commands (`/work-vault capture`, etc.) still work without Slack integration.
